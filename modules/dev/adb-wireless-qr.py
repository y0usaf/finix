#!/usr/bin/env python3
"""Android wireless debugging QR pairing + auto-connect.

Flow: renders a QR code the phone scans, then listens on mDNS for the
phone to advertise its pairing service, runs `adb pair`, discovers the
debug port, and runs `adb connect`.
"""
from __future__ import annotations

import argparse
import ipaddress
import shutil
import subprocess
import sys
import threading
from secrets import choice
from string import digits
from textwrap import dedent

import qrcode
from zeroconf import IPVersion, ServiceBrowser, ServiceListener, Zeroconf

PAIRING_SERVICE = "_adb-tls-pairing._tcp.local."
CONNECT_SERVICE = "_adb-tls-connect._tcp.local."


def random_digits(length: int) -> str:
    return "".join(choice(digits) for _ in range(length))


def run_adb(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["adb", *args],
        capture_output=True,
        text=True,
        check=False,
    )


def ensure_adb() -> None:
    if shutil.which("adb") is None:
        raise SystemExit("adb not found in PATH")
    started = run_adb("start-server")
    if started.returncode != 0:
        raise SystemExit((started.stderr or started.stdout or "failed to start adb").strip())


def restart_adb() -> None:
    run_adb("kill-server")
    started = run_adb("start-server")
    if started.returncode != 0:
        raise RuntimeError((started.stderr or started.stdout or "failed to restart adb").strip())


def pick_private_ipv4(info) -> str | None:
    for address in info.ip_addresses_by_version(IPVersion.V4Only):
        if isinstance(address, ipaddress.IPv4Address) and address.is_private:
            return address.exploded
    return None


class MatchListener(ServiceListener):
    def __init__(self, zeroconf, service_type, matcher):
        self.zeroconf = zeroconf
        self.service_type = service_type
        self.matcher = matcher
        self.event = threading.Event()
        self.info = None
        self.error = None

    def add_service(self, zeroconf, service_type, name):
        self._handle(name)

    def update_service(self, zeroconf, service_type, name):
        self._handle(name)

    def remove_service(self, zeroconf, service_type, name):
        return

    def _handle(self, name):
        if self.event.is_set():
            return
        try:
            info = self.zeroconf.get_service_info(self.service_type, name, timeout=3000)
            if info and self.matcher(name, info):
                self.info = info
                self.event.set()
        except Exception as exc:
            self.error = exc
            self.event.set()

    def wait(self, timeout):
        if not self.event.wait(timeout):
            return None
        if self.error is not None:
            raise self.error
        return self.info


def print_intro() -> None:
    print("Android wireless debugging over QR")
    print()
    print("Phone setup:")
    print("1. Enable Developer options: Settings -> About phone -> tap Build number 7 times.")
    print("2. Open Settings -> Developer options -> Wireless debugging.")
    print("3. Keep phone and computer on the same Wi-Fi network.")
    print("4. Tap Pair device with QR code, then scan the QR below.")
    print()


def print_qr(payload: str) -> None:
    qr = qrcode.QRCode(border=1)
    qr.add_data(payload)
    qr.make(fit=True)
    qr.print_ascii(out=sys.stdout, invert=True)
    print()
    print("If scanning is flaky, increase terminal zoom/font size and try again.")
    print()


def wait_for_pairing_service(zeroconf, service_name, timeout):
    expected_full_name = f"{service_name}.{PAIRING_SERVICE}"
    listener = MatchListener(zeroconf, PAIRING_SERVICE, lambda name, info: name == expected_full_name)
    browser = ServiceBrowser(zeroconf, PAIRING_SERVICE, listener=listener)
    try:
        info = listener.wait(timeout)
    finally:
        browser.cancel()
    if info is None:
        raise TimeoutError("timed out waiting for the phone to advertise its pairing service")
    address = pick_private_ipv4(info)
    if address is None:
        raise RuntimeError("pairing service did not advertise a private IPv4 address")
    return address, info.port


def wait_for_connect_service(zeroconf, address, timeout):
    listener = MatchListener(
        zeroconf,
        CONNECT_SERVICE,
        lambda name, info: pick_private_ipv4(info) == address,
    )
    browser = ServiceBrowser(zeroconf, CONNECT_SERVICE, listener=listener)
    try:
        info = listener.wait(timeout)
    finally:
        browser.cancel()
    return None if info is None else info.port


def adb_pair(address, port, password):
    result = run_adb("pair", f"{address}:{port}", password)
    if result.returncode != 0:
        message = (result.stderr or result.stdout or "adb pair failed").strip()
        raise RuntimeError(message)


def should_retry_pair(message):
    lowered = message.lower()
    return "protocol fault" in lowered or "couldn't read status message" in lowered


def pair_with_recovery(address, port, password):
    try:
        adb_pair(address, port, password)
        return
    except RuntimeError as exc:
        message = str(exc)
        if not should_retry_pair(message):
            raise
        print()
        print("ADB hit a stale server/protocol fault during pairing.")
        print("Restarting the ADB server and retrying once...")
        sys.stdout.flush()
        restart_adb()
        try:
            adb_pair(address, port, password)
        except RuntimeError as exc2:
            raise RuntimeError(
                dedent(
                    f"""
                    pairing failed after restarting ADB: {exc2}
                    Try this:
                    1. Keep the phone on the Wireless debugging screen.
                    2. Turn Wireless debugging off, then on again.
                    3. Tap Pair device with QR code again.
                    4. Re-run adb-wireless-qr.
                    If it keeps happening:
                    - run: adb kill-server && adb start-server
                    - make sure no other adb client/tool is fighting for the server
                    """
                ).strip()
            ) from exc2


def adb_connect(address, port):
    result = run_adb("connect", f"{address}:{port}")
    if result.returncode != 0:
        message = (result.stderr or result.stdout or "adb connect failed").strip()
        raise RuntimeError(message)


def adb_devices():
    result = run_adb("devices")
    if result.returncode != 0:
        return []
    return [line for line in result.stdout.splitlines()[1:] if line.strip()]


def build_parser():
    parser = argparse.ArgumentParser(
        prog="adb-wireless-qr",
        description="Show an Android wireless-debugging QR code, then pair and connect automatically.",
        epilog=dedent(
            """
            Phone flow:
            Settings -> Developer options -> Wireless debugging -> Pair device with QR code
            """
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--pair-timeout", type=float, default=180, help="seconds to wait for QR pairing (default: 180)")
    parser.add_argument("--connect-timeout", type=float, default=30, help="seconds to wait for auto-connect discovery (default: 30)")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    ensure_adb()
    service_name = f"adb-wireless-{random_digits(6)}"
    password = random_digits(8)
    payload = f"WIFI:T:ADB;S:{service_name};P:{password};;"
    print_intro()
    print_qr(payload)
    print("Waiting for your phone to scan the QR and start pairing...")
    sys.stdout.flush()
    zeroconf = Zeroconf()
    try:
        address, pairing_port = wait_for_pairing_service(zeroconf, service_name, args.pair_timeout)
        print(f"Found pairing service at {address}:{pairing_port}")
        pair_with_recovery(address, pairing_port, password)
        print("Pairing succeeded")
        connect_port = wait_for_connect_service(zeroconf, address, args.connect_timeout)
        if connect_port is None:
            print("Pairing succeeded, but the debugging port was not discovered in time.")
            print("Open Wireless debugging on the phone and run adb connect with the shown port if needed.")
            return 1
        adb_connect(address, connect_port)
        print(f"Connected to {address}:{connect_port}")
        devices = adb_devices()
        if devices:
            print()
            print("adb devices:")
            for line in devices:
                print(line)
        return 0
    finally:
        zeroconf.close()


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit("cancelled")
    except Exception as exc:
        sys.stdout.flush()
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)