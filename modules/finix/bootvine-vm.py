import argparse
import json
import os
import re
import socket
import struct
import subprocess
import sys
import time
import zlib


class Serial:
    def __init__(self, path):
        self.path = path
        self.sock = None
        self.buffer = b""
        self.log = None

    def connect(self, timeout=60):
        end = time.time() + timeout
        while time.time() < end:
            try:
                sock = socket.socket(socket.AF_UNIX)
                sock.connect(self.path)
                self.sock = sock
                return
            except OSError:
                time.sleep(0.1)
        raise RuntimeError("serial socket never appeared")

    def send(self, text):
        if self.sock is None:
            raise RuntimeError("serial console is gone")
        try:
            self.sock.sendall(text.encode())
        except OSError as error:
            raise RuntimeError(f"serial console is gone: {error}")

    def read(self, timeout=0.5):
        if self.sock is None:
            return b""
        self.sock.settimeout(timeout)
        try:
            data = self.sock.recv(65536)
        except socket.timeout:
            return b""
        except OSError:
            return b""
        if data:
            if self.log is not None:
                self.log.write(data)
                self.log.flush()
            self.buffer += data
        return data

    def take(self):
        data = self.buffer
        self.buffer = b""
        return data

    def wait_for(self, pattern, timeout=60):
        regex = re.compile(pattern.encode())
        end = time.time() + timeout
        while time.time() < end:
            if regex.search(self.buffer):
                return True
            self.read(0.4)
        return bool(regex.search(self.buffer))


class QMP:
    def __init__(self, path):
        self.path = path
        self.sock = None
        self.file = None

    def connect(self, timeout=60):
        end = time.time() + timeout
        while time.time() < end:
            try:
                sock = socket.socket(socket.AF_UNIX)
                sock.connect(self.path)
                self.sock = sock
                self.file = sock.makefile("rwb")
                self.read_message()
                self.execute("qmp_capabilities")
                return
            except OSError:
                time.sleep(0.1)
        raise RuntimeError("qmp socket never appeared")

    def read_message(self):
        line = self.file.readline()
        if not line:
            raise RuntimeError("qmp closed")
        return json.loads(line)

    def execute(self, name, **arguments):
        payload = {"execute": name}
        if arguments:
            payload["arguments"] = arguments
        self.file.write((json.dumps(payload) + "\n").encode())
        self.file.flush()
        while True:
            message = self.read_message()
            if "event" in message:
                continue
            return message

    def screendump(self, path):
        reply = self.execute("screendump", filename=path)
        if "error" in reply:
            raise RuntimeError(reply["error"].get("desc", "screendump failed"))


def ppm_to_png(source, target):
    with open(source, "rb") as handle:
        data = handle.read()
    fields = []
    index = 0
    while len(fields) < 4:
        while index < len(data) and data[index : index + 1].isspace():
            index += 1
        if data[index : index + 1] == b"#":
            while index < len(data) and data[index] != 0x0A:
                index += 1
            continue
        start = index
        while index < len(data) and not data[index : index + 1].isspace():
            index += 1
        fields.append(data[start:index])
    index += 1
    if fields[0] != b"P6":
        raise RuntimeError("not a binary ppm")
    width = int(fields[1])
    height = int(fields[2])
    pixels = data[index : index + width * height * 3]
    raw = bytearray()
    stride = width * 3
    for row in range(height):
        raw.append(0)
        raw += pixels[row * stride : (row + 1) * stride]

    def chunk(kind, body):
        return (
            struct.pack(">I", len(body))
            + kind
            + body
            + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)
        )

    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    with open(target, "wb") as handle:
        handle.write(b"\x89PNG\r\n\x1a\n")
        handle.write(chunk(b"IHDR", header))
        handle.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        handle.write(chunk(b"IEND", b""))


class Driver:
    def __init__(self, args):
        self.args = args
        self.out = args.out
        self.work = args.work
        self.qemu = None
        self.serial = Serial(os.path.join(self.work, "serial.sock"))
        self.serial.log = open(os.path.join(self.out, "serial.log"), "wb")
        self.qmp = QMP(os.path.join(self.work, "qmp.sock"))
        self.checks = []
        self.columns = 80
        self.nonce = 1000 + int(time.time()) % 9000

    def log(self, text):
        print(text, flush=True)

    def check(self, name, ok, detail=""):
        self.checks.append((name, bool(ok), detail))
        state = "PASS" if ok else "FAIL"
        self.log(f"[{state}] {name}{(': ' + detail) if detail else ''}")

    def start_qemu(self):
        with open(self.args.argv) as handle:
            argv = json.load(handle)
        argv = argv + [
            "-serial", f"unix:{os.path.join(self.work, 'serial.sock')},server=on,wait=off",
            "-qmp", f"unix:{os.path.join(self.work, 'qmp.sock')},server=on,wait=off",
        ]
        self.logfile = open(os.path.join(self.out, "qemu.log"), "wb")
        self.qemu = subprocess.Popen(argv, cwd=self.work, stdout=self.logfile, stderr=subprocess.STDOUT)

    def shell(self, command, timeout=30):
        marker = f"MARK{self.nonce}X"
        self.serial.take()
        self.serial.send(command + "\n")
        self.serial.send("printf '\\n%s-\\n' " + marker + "\n")
        end = time.time() + timeout
        collected = b""
        while time.time() < end:
            collected += self.serial.read(0.3)
            match = re.search(marker.encode() + rb"-", collected)
            if match:
                break
        text = collected.decode(errors="replace")
        text = re.sub(re.escape(marker) + r"-\s*", "", text)
        return text

    def wait_shell(self, timeout=180):
        end = time.time() + timeout
        while time.time() < end:
            self.serial.take()
            self.serial.send("printf 'SHELL%s-\\n'\n" % self.nonce)
            if self.serial.wait_for(f"SHELL{self.nonce}-", 3):
                self.serial.take()
                self.serial.send("stty -echo -onlcr 2>/dev/null\n")
                self.serial.send("printf 'OK%s-\\n'\n" % self.nonce)
                self.serial.wait_for(f"OK{self.nonce}-", 3)
                self.serial.take()
                return True
        return False

    def guest(self, command, timeout=30):
        return self.shell(command, timeout)

    def vt_text(self, number):
        text = self.guest(f"cat /dev/vcs{number} 2>/dev/null")
        text = text.strip("\r\n")
        text = re.sub(r"#\s*$", "", text)
        start = text.find("finix")
        if start > 0 and "\x1b" in text[:start]:
            text = text[start:]
        return text

    def active_vt(self):
        text = self.guest("echo ACTIVE=$(cat /sys/class/tty/tty0/active 2>/dev/null)")
        match = re.search(r"ACTIVE=(tty\d+)", text)
        if match:
            return match.group(1)
        return ""

    def vt_columns(self):
        size = self.guest("echo SIZE=$(stty size < /dev/tty12 2>/dev/null)")
        match = re.search(r"SIZE=\d+ (\d+)", size)
        if match:
            return int(match.group(1))
        return 80

    def save_screen(self, name, text):
        width = self.columns
        lines = []
        for line in text.split("\n"):
            if not line:
                continue
            for i in range(0, len(line), width):
                lines.append(line[i : i + width].rstrip())
        with open(os.path.join(self.out, name), "w") as handle:
            handle.write("\n".join(lines) + "\n")

    def screenshot(self, name):
        image = os.path.join(self.out, name + ".png")
        raw = os.path.join(self.work, name + ".ppm")
        self.qmp.screendump(raw)
        ppm_to_png(raw, image)
        return image

    def run(self):
        os.makedirs(self.out, exist_ok=True)
        os.makedirs(self.work, exist_ok=True)
        self.start_qemu()
        self.log("qemu started")
        self.serial.connect()
        self.log("serial connected")
        self.qmp.connect()
        self.log("qmp connected")
        began = time.time()
        if not self.wait_shell():
            self.check("serial console shell", False, "no shell prompt")
            return self.finish()
        self.columns = self.vt_columns()
        self.log(f"serial shell ready after {time.time() - began:.1f}s, {self.columns} columns wide")

        boot_samples = []
        login_seen = False
        delayed_state = ""
        deadline = time.time() + self.args.boot_timeout
        while time.time() < deadline:
            text = self.vt_text(12)
            if text.strip():
                boot_samples.append(text)
            if self.active_vt() == "tty1":
                login = self.vt_text(1)
                if "login:" in login:
                    login_seen = True
                    self.log(f"login prompt seen after {time.time() - began:.1f}s")
                    self.save_screen("screen-login.txt", login)
                    self.screenshot("login")
                    delayed_state = self.guest(
                        "echo STARTED=$(test -e /run/delayed-start && echo yes || echo no)"
                        " DONE=$(test -e /run/delayed-done && echo yes || echo no)"
                    )
                    break
            time.sleep(0.4)

        final = self.vt_text(12)
        self.save_screen("screen-boot.txt", final)
        all_boot = "\n\n".join(boot_samples)
        self.save_screen("screen-boot-samples.txt", all_boot)

        self.check("boot screen shows the slow task", "slowpoke" in final)
        self.check("boot screen shows how long the slow task ran",
                   re.search(r"slowpoke\D{0,80}?[789]\.\d+s", final) is not None,
                   self.first_line(final, "slowpoke"))
        self.check("boot screen shows the failing task", "broken" in final)
        self.check("boot screen gives the failure reason", "status 3" in final, self.first_line(final, "broken"))
        self.check("boot screen kept its last frame for the handover",
                   "runlevel 2" in final and "slowpoke" in final and "broken" in final)
        self.check("boot screen hides finit status", "Starting " not in final and "Calling '" not in final)
        self.check("login prompt reached on tty1", login_seen)
        if not login_seen:
            self.check("active terminal after boot", False, self.active_vt())
            login = self.vt_text(1)
            self.save_screen("screen-login.txt", login)
        started = re.search(r"STARTED=(yes|no)", delayed_state)
        done = re.search(r"DONE=(yes|no)", delayed_state)
        self.check("the slow runlevel 2 task had started",
                   started is not None and started.group(1) == "yes",
                   self.first_line(delayed_state, "STARTED"))
        self.check("login prompt did not wait for the slow runlevel 2 task",
                   done is not None and done.group(1) == "no",
                   self.first_line(delayed_state, "DONE"))

        self.serial.take()
        self.serial.send("initctl poweroff\n")
        time.sleep(0.5)
        shutdown_seen = False
        deadline = time.time() + 40
        shutdown_text = ""
        while time.time() < deadline:
            if self.qemu.poll() is not None:
                break
            try:
                text = self.vt_text(12)
            except RuntimeError:
                break
            if "shutting down" in text or "poweroff" in text:
                shutdown_text = text
                if not shutdown_seen:
                    shutdown_seen = True
                    self.save_screen("screen-shutdown.txt", text)
                    self.screenshot("shutdown")
                if "slowstop" in text:
                    break
            time.sleep(0.1)
        self.check("shutdown screen rendered", shutdown_seen)
        self.check("shutdown screen shows a service stopping", "slowstop" in shutdown_text)
        return self.finish()

    def first_line(self, text, needle):
        for line in text.splitlines():
            if needle in line:
                return line.strip()
        return ""

    def finish(self):
        if self.qemu is not None and self.qemu.poll() is None:
            self.qemu.terminate()
            try:
                self.qemu.wait(10)
            except subprocess.TimeoutExpired:
                self.qemu.kill()
        failures = [c for c in self.checks if not c[1]]
        with open(os.path.join(self.out, "assertions.log"), "w") as handle:
            for name, ok, detail in self.checks:
                handle.write(f"{'PASS' if ok else 'FAIL'} {name} {detail}\n")
        self.log(f"{len(self.checks) - len(failures)} checks passed, {len(failures)} failed")
        if failures and not self.args.allow_fail:
            return 1
        return 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--argv", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--work", required=True)
    parser.add_argument("--boot-timeout", type=int, default=240)
    parser.add_argument("--allow-fail", action="store_true")
    args = parser.parse_args()
    return Driver(args).run()


if __name__ == "__main__":
    sys.exit(main())
