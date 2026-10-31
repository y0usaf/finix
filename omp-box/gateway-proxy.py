"""Forward model calls to the AI gateway, adding its key."""

import asyncio
import os
import ssl

UPSTREAM = "ai-gateway.vercel.sh"
KEY_FILE = os.environ["GATEWAY_KEY_FILE"]
HOST = os.environ.get("HOST", "127.0.0.1")
PORT = int(os.environ.get("PORT", "8899"))
DROP = {
    "host",
    "authorization",
    "x-api-key",
    "cf-aig-authorization",
    "connection",
    "proxy-connection",
    "accept-encoding",
}


def header_name(raw):
    return raw.partition(":")[0].strip().lower()


def read_key():
    with open(KEY_FILE) as handle:
        return handle.read().strip()


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
        return (await reader.readexactly(length) if length else b"")
    data = bytearray()
    while True:
        line = await reader.readline()
        data += line
        size = int(line.split(b";")[0].strip() or b"0", 16)
        if size == 0:
            data += await reader.readline()
            return bytes(data)
        data += await reader.readexactly(size + 2)


async def handle(reader, writer):
    try:
        head = await reader.readuntil(b"\r\n\r\n")
        method, path, _ = head.decode("latin1").split("\r\n")[0].split(" ", 2)
    except Exception:
        writer.close()
        return
    kept = [
        raw
        for raw in head.decode("latin1").split("\r\n")[1:]
        if raw and header_name(raw) not in DROP
    ]
    body = await read_body(reader, kept)
    outgoing = [
        f"{method} {path} HTTP/1.1",
        f"Host: {UPSTREAM}",
        f"Authorization: Bearer {read_key()}",
    ]
    outgoing += kept
    outgoing += ["Connection: close", "", ""]
    try:
        context = ssl.create_default_context()
        up_reader, up_writer = await asyncio.open_connection(
            UPSTREAM, 443, ssl=context, server_hostname=UPSTREAM
        )
        up_writer.write("\r\n".join(outgoing).encode("latin1") + body)
        await up_writer.drain()
        while True:
            data = await up_reader.read(65536)
            if not data:
                break
            writer.write(data)
            await writer.drain()
        up_writer.close()
    except Exception as exc:
        message = f"upstream failed: {exc}".encode()
        writer.write(
            b"HTTP/1.1 502 Bad Gateway\r\nContent-Length: "
            + str(len(message)).encode()
            + b"\r\nConnection: close\r\n\r\n"
            + message
        )
    finally:
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
