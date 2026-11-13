"""Carries the box's DevTools connections to baobot's Chromium as needed.

The box reaches this host's loopback as 10.0.2.2 through QEMU's user
networking, so a bot connects to 10.0.2.2:9233. Chromium keeps its DevTools
on 127.0.0.1:9234, and this holds 9233: for each connection it starts the
browser if it is not up, then carries the connection through. A CDP session is
one connection, and Chromium answers both the JSON endpoints and the DevTools
WebSocket upgrades on it, so the box sees one DevTools endpoint that is never
closed.
"""

import asyncio
import os
import socket
import sys

LISTEN_PORT = int(os.environ["BAOBOT_CHROMIUM_PORT"])
DEVTOOLS_PORT = int(os.environ["BAOBOT_CHROMIUM_DEVTOOLS_PORT"])
ENSURE = os.environ["BAOBOT_CHROMIUM_ENSURE"]
DEVTOOLS = ("127.0.0.1", DEVTOOLS_PORT)
CHUNK = 1 << 16

# Held while a browser starts, so connections that arrive together wait for
# that one browser instead of each starting a browser of their own.
starting = asyncio.Lock()


def note(message):
    print(f"baobot-chromium-broker: {message}", file=sys.stderr, flush=True)


def tune(sock):
    if sock is not None:
        sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)


async def copy(reader, writer):
    """One direction of a connection, until either end closes."""
    try:
        while chunk := await reader.read(CHUNK):
            writer.write(chunk)
            await writer.drain()
    except (ConnectionError, OSError):
        # Either end went away mid-stream; closing both is all that is left.
        pass
    finally:
        writer.close()


async def devtools():
    """A connection to DevTools, starting the browser first if it is down."""
    try:
        return await asyncio.open_connection(*DEVTOOLS)
    except OSError:
        pass
    async with starting:
        # A connection that waited for the lock may have started it already.
        try:
            return await asyncio.open_connection(*DEVTOOLS)
        except OSError:
            pass
        code = await (await asyncio.create_subprocess_exec(ENSURE)).wait()
        if code != 0:
            raise OSError(f"baobot-chromium-ensure exited {code}")
        return await asyncio.open_connection(*DEVTOOLS)


async def serve(reader, writer):
    """A connection from the box: to the browser until either end closes."""
    tune(writer.get_extra_info("socket"))
    try:
        upstream_reader, upstream_writer = await devtools()
    except OSError as error:
        note(error)
        writer.close()
        return
    tune(upstream_writer.get_extra_info("socket"))
    await asyncio.gather(
        copy(reader, upstream_writer), copy(upstream_reader, writer)
    )
    upstream_writer.close()


async def main():
    while True:
        try:
            server = await asyncio.start_server(
                serve, "127.0.0.1", LISTEN_PORT, reuse_address=True
            )
            break
        except OSError as error:
            # A browser started before this broker held the port still owns it,
            # and answers the box itself until it goes; wait for that.
            note(f"{error}; trying again in 5s")
            await asyncio.sleep(5)
    note(f"{LISTEN_PORT} carries to DevTools on {DEVTOOLS_PORT}")
    async with server:
        await server.serve_forever()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
