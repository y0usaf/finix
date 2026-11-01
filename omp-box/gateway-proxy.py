import asyncio
import base64
import json
import os
import ssl

GATEWAY = "ai-gateway.vercel.sh"
KEY_FILE = os.environ["GATEWAY_KEY_FILE"]
CREST_AUTH = os.environ["CREST_AUTH"]
HOST = os.environ.get("HOST", "127.0.0.1")
PORT = int(os.environ.get("PORT", "8899"))
CREST = {
    "anthropic": ("api.anthropic.com", ""),
    "openai-codex": ("chatgpt.com", "/backend-api"),
}
ACCOUNT = "chatgpt-account-id"
RESIDENCY = "x-openai-internal-codex-residency"
DROP = {
    "host",
    "authorization",
    "x-api-key",
    "cf-aig-authorization",
    "connection",
    "proxy-connection",
    "accept-encoding",
}


class CrestError(Exception):
    pass


def header_name(raw):
    return raw.partition(":")[0].strip().lower()


def read_key():
    with open(KEY_FILE) as handle:
        return handle.read().strip()


async def crest_auth(*args):
    process = await asyncio.create_subprocess_exec(
        CREST_AUTH,
        "json",
        *args,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    out, err = await process.communicate()
    if process.returncode != 0:
        detail = err.decode().strip() or f"exit {process.returncode}"
        raise CrestError(f"crest-auth json {' '.join(args)}: {detail}")
    return out


async def crest_token(provider):
    return json.loads(await crest_auth("token", provider))


async def successor(provider, tried):
    try:
        token = await crest_token(provider)
    except CrestError:
        return None
    return token if token.get("login") not in tried else None


def residency(access):
    try:
        segment = access.split(".")[1]
        claims = json.loads(
            base64.urlsafe_b64decode(segment + "=" * (-len(segment) % 4))
        )
    except (IndexError, ValueError):
        return None
    auth = claims.get("https://api.openai.com/auth", {})
    for claim in ("chatgpt_data_residency", "chatgpt_compute_residency"):
        value = auth.get(claim)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return None


def credentials(provider, token, names):
    if provider is None:
        return [f"Authorization: Bearer {read_key()}"]
    lines = [f"Authorization: Bearer {token['access']}"]
    if provider == "openai-codex":
        if ACCOUNT not in names and token.get("account_id"):
            lines.append(f"{ACCOUNT}: {token['account_id']}")
        place = residency(token["access"])
        if RESIDENCY not in names and place:
            lines.append(f"{RESIDENCY}: {place}")
    return lines


def route(path):
    for provider, (host, prefix) in CREST.items():
        mount = f"/{provider}"
        if path == mount or path.startswith((f"{mount}/", f"{mount}?")):
            return provider, host, prefix + path.removeprefix(mount)
    return None, GATEWAY, path


async def read_body(reader, headers):
    length = 0
    chunked = False
    for raw in headers:
        name = header_name(raw)
        value = raw.partition(":")[2].strip()
        if name == "content-length":
            length = int(value)
        elif name == "transfer-encoding" and "chunked" in value.lower():
            chunked = True
    if not chunked:
        return await reader.readexactly(length) if length else b""
    data = bytearray()
    while True:
        line = await reader.readline()
        data += line
        size = int(line.split(b";")[0].strip() or b"0", 16)
        if size == 0:
            data += await reader.readline()
            return bytes(data)
        data += await reader.readexactly(size + 2)


async def exchange(host, request):
    context = ssl.create_default_context()
    reader, writer = await asyncio.open_connection(
        host, 443, ssl=context, server_hostname=host
    )
    writer.write(request)
    await writer.drain()
    head = await reader.readuntil(b"\r\n\r\n")
    return reader, writer, head


async def pump(source, sink):
    while data := await source.read(65536):
        sink.write(data)
        await sink.drain()


async def relay(client_reader, client_writer, up_reader, up_writer, both):
    tasks = [asyncio.create_task(pump(up_reader, client_writer))]
    if both:
        tasks.append(asyncio.create_task(pump(client_reader, up_writer)))
    done, pending = await asyncio.wait(
        tasks, return_when=asyncio.FIRST_COMPLETED
    )
    for task in pending:
        task.cancel()
    for task in done:
        task.exception()


def failure(status, message):
    body = message.encode()
    return (
        f"HTTP/1.1 {status}\r\nContent-Type: text/plain\r\n"
        f"Content-Length: {len(body)}\r\nConnection: close\r\n\r\n"
    ).encode() + body


async def handle(reader, writer):
    try:
        head = await reader.readuntil(b"\r\n\r\n")
        method, path, _ = head.decode("latin1").split("\r\n")[0].split(" ", 2)
    except Exception:
        writer.close()
        return
    lines = [raw for raw in head.decode("latin1").split("\r\n")[1:] if raw]
    upgrade = any(header_name(raw) == "upgrade" for raw in lines)
    kept = [raw for raw in lines if header_name(raw) not in DROP]
    names = {header_name(raw) for raw in kept}
    provider, host, target = route(path)
    upstream = None
    answered = False
    try:
        body = await read_body(reader, kept)
        token = await crest_token(provider) if provider else None
        tried = set()
        while True:
            outgoing = [
                f"{method} {target} HTTP/1.1",
                f"Host: {host}",
                *credentials(provider, token, names),
                *kept,
                "Connection: Upgrade" if upgrade else "Connection: close",
                "",
                "",
            ]
            up_reader, upstream, response = await exchange(
                host, "\r\n".join(outgoing).encode("latin1") + body
            )
            login = token.get("login") if token else None
            if response.split(b" ", 2)[1] == b"429" and login and not upgrade:
                tried.add(login)
                await crest_auth("cool", login)
                following = await successor(provider, tried)
                if following:
                    upstream.close()
                    token = following
                    continue
            answered = True
            writer.write(response)
            await writer.drain()
            await relay(reader, writer, up_reader, upstream, upgrade)
            break
    except CrestError as error:
        if not answered:
            writer.write(failure("502 Bad Gateway", str(error)))
    except Exception as error:
        if not answered:
            writer.write(
                failure("502 Bad Gateway", f"upstream failed: {error}")
            )
    finally:
        if upstream:
            upstream.close()
        try:
            await writer.drain()
        except Exception:
            pass
        writer.close()


async def main():
    server = await asyncio.start_server(handle, HOST, PORT)
    async with server:
        await server.serve_forever()


asyncio.run(main())
