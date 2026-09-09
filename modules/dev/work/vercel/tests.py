import json
import os
import subprocess
from pathlib import Path

root = Path.cwd()
os.environ['HOME'] = str(root / 'home')
os.environ['XDG_DATA_HOME'] = str(root / 'data')
os.environ.pop('VERCEL_ACCOUNT', None)


def repo(name, owner):
    path = root / name
    subprocess.run(['git', 'init', '-q', str(path)], check=True)
    subprocess.run(['git', '-C', str(path), 'remote', 'add', 'origin',
                    f'git@github.com:{owner}/project.git'], check=True)
    return path


personal = repo('personal', 'y0usaf')
work = repo('work', 'work-org')
unknown = repo('unknown', 'stranger')


def invoke(command, cwd, args, account=None, success=True):
    env = os.environ.copy()
    if account is not None:
        env['VERCEL_ACCOUNT'] = account
    result = subprocess.run([command, *args], cwd=cwd, env=env,
                            capture_output=True, text=True)
    assert (result.returncode == 0) == success, result.stderr
    return json.loads(result.stdout) if success else result.stderr


def routed(command, cwd, args, account):
    actual = invoke(command, cwd, args)
    assert actual == ['--global-config', str(root / 'data/com.vercel.cli/profiles' / account), *args], actual


routed('vercel', personal, ['deploy', '--prod'], 'personal')
routed('vercel', work, ['whoami'], 'work')
routed('vercel-personal', work, ['whoami'], 'personal')
routed('vercel-work', personal, ['whoami'], 'work')
routed('vercel', personal, ['--cwd', str(work), 'whoami'], 'work')
routed('vercel', personal, [f'--cwd={work}', 'whoami'], 'work')
assert 'vercel-personal/vercel-work' in invoke('vercel', unknown, ['deploy'], success=False)
invoke('vercel', personal, ['whoami'], account='../bad', success=False)
for args in [['--global-config', '/explicit', 'whoami'], ['--token=explicit-test-token', 'whoami']]:
    assert invoke('vercel', unknown, args) == args
invoke('vercel', personal, ['--cwd'], success=False)
invoke('vercel', personal, ['--cwd=/missing-directory', 'whoami'], success=False)
assert (root / 'data/com.vercel.cli/profiles/personal').stat().st_mode & 0o777 == 0o700
