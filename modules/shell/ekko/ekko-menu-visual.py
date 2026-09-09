"""Real Kitty screenshots on a private headless Wayland compositor."""
import base64
import json
import os
import select
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import tty

if sys.argv[1] == '--fixture':
    tty.setraw(0)
    os.write(1, b'\x1b[?25l' + b''.join(f'LIVE TERMINAL CONTENT {i:02d}\r\n'.encode() for i in range(35)))
    os.write(1, b'\x1b[2;1H')
    pixels = bytes([180, 48, 70]) * (500*600)
    payload = base64.b64encode(pixels)
    for offset in range(0, len(payload), 4096):
        data = payload[offset:offset+4096]
        more = int(offset+4096 < len(payload))
        header = f'a=T,f=24,s=500,v=600,i=17,C=1,q=2,m={more}' if offset == 0 else f'm={more}'
        os.write(1, b'\x1b_G'+header.encode()+b';'+data+b'\x1b\\')
    updated = False
    while True:
        if select.select([0], [], [], .05)[0]:
            os.read(0, 4096)
        if not updated and Path(os.environ['EKKO_VISUAL_CONTROL']).exists():
            row = os.get_terminal_size().lines - 1
            os.write(1, b'\x1b_Ga=d,d=I,i=17;\x1b\\' +
                     f'\x1b[{row};1HUPDATED BEHIND MENU'.encode())
            updated = True

from PIL import Image, ImageChops
binary, config, destination = sys.argv[1:]
out = Path(destination).resolve()
out.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='finix-ekko-visual-') as directory:
    root = Path(directory)
    runtime = root/'runtime'
    runtime.mkdir(mode=0o700)
    env = dict(os.environ, XDG_RUNTIME_DIR=str(runtime), WAYLAND_DISPLAY='wayland-0',
               HOME=str(root), XDG_CONFIG_HOME=str(root/'config'), XDG_CACHE_HOME=str(root/'cache'),
               EKKO_CONFIG=str(Path(config).resolve()), EKKO_VISUAL_CONTROL=str(root/'change'), WLR_BACKENDS='headless', WLR_RENDERER='pixman',
               WLR_LIBINPUT_NO_DEVICES='1', WLR_HEADLESS_OUTPUTS='1', WLR_NO_HARDWARE_CURSORS='1',
               LIBGL_ALWAYS_SOFTWARE='1', MESA_LOADER_DRIVER_OVERRIDE='llvmpipe')
    env.pop('EKKO_SESSION_NAME', None)
    remote = 'unix:'+str(root/'kitty.sock')
    log = (out/'kitty.log').open('wb')
    process = subprocess.Popen(['cage', '-d', '--', 'kitty', '--config', 'NONE',
        '--listen-on', remote, '-o', 'allow_remote_control=yes', '-o', 'linux_display_server=wayland',
        '-o', 'font_family=DejaVu Sans Mono', '-o', 'font_size=16', '-o', 'cursor_blink_interval=0',
        binary, 'run', '--session', 'visual', sys.executable, __file__, '--fixture'], env=env,
        stdout=log, stderr=log)
    def run(*args, **kwargs):
        return subprocess.check_output(args, env=env, timeout=10, **kwargs)
    def inspect():
        return json.loads(run(binary, 'inspect', 'visual'))
    def wait(predicate):
        deadline = time.monotonic()+15
        while time.monotonic() < deadline:
            try:
                if predicate():
                    return
            except (subprocess.CalledProcessError, FileNotFoundError):
                pass
            time.sleep(.1)
        raise AssertionError('preview did not settle')
    def key(data, mode):
        run('kitty', '@', '--to', remote, 'send-text', '--stdin', input=data)
        wait(lambda: inspect()['mode'] == mode)
        time.sleep(.5)
    def capture(name):
        run('grim', str(out/(name+'.png')))
    try:
        wait(lambda: (root/'kitty.sock').exists() and (runtime/'ekko-v2/visual.sock').exists())
        wait(lambda: inspect()['mode'] == 'normal')
        time.sleep(2)
        capture('normal')
        key(b'\x02', 'menu')
        capture('commands')
        key(b'p', 'panes')
        capture('panes')
        key(b'\x1b', 'menu')
        key(b'\x1b', 'normal')
        capture('restored')
        before = Image.open(out/'normal.png').convert('RGB')
        restored = Image.open(out/'restored.png').convert('RGB')
        assert ImageChops.difference(before, restored).getbbox() is None, 'dismiss did not restore exact pixels'
        menu = Image.open(out/'commands.png').convert('RGB')
        assert ImageChops.difference(before, menu).getbbox(), 'menu did not render'
        red = lambda im: sum(1 for r,g,b in im.get_flattened_data() if r > 140 and g < 80 and b < 110)
        assert red(before) > 100000, 'Kitty image fixture missing'
        assert red(menu) < red(before)-10000, 'opaque menu failed to occlude image'
        key(b'\x07', 'locked')
        capture('locked')
        key(b'\x07', 'normal')
        key(b'\x02', 'menu')
        (root/'change').touch()
        wait(lambda: json.loads(run(binary, 'status', 'visual'))['panes'][0]['images'] == 0)
        time.sleep(.5)
        capture('live-menu')
        assert b'UPDATED BEHIND MENU' not in run('kitty', '@', '--to', remote, 'get-text')
        key(b'\x1b', 'normal')
        capture('live-restored')
        assert b'UPDATED BEHIND MENU' in run('kitty', '@', '--to', remote, 'get-text')
        run(binary, 'split', '--session', 'visual', 'columns')
        time.sleep(.5)
        capture('split')
        key(b'\x10', 'panes')
        capture('split-menu')
        (out/'report.json').write_text(json.dumps({'status':'pass', 'host':'Kitty/private Cage',
            'checks':['native Kitty graphics', 'opaque menu', 'exact pixel restoration', 'lock indicator', 'live output behind menu', 'split chrome'],
            'size':before.size, 'image_pixels_before':red(before), 'image_pixels_menu':red(menu)}, indent=2)+'\n')
        print(out/'report.json')
    finally:
        subprocess.run([binary, 'stop', 'visual'], env=env, capture_output=True, timeout=5)
        process.terminate()
        process.wait(timeout=5)
        log.close()
