import os
import subprocess
import sys
from pathlib import Path

args = sys.argv[1:]
cli = '@vercel@/bin/vercel'


def fail(message):
    sys.exit(f'vercel: {message}')


def run_cli(extra=()):
    os.execv(cli, [cli, *extra, *args])


# Explicit upstream authentication/configuration remains available.
if any(arg in ('--token', '-t', '--global-config', '-Q') or
       arg.startswith(('--token=', '--global-config=')) for arg in args):
    run_cli()

if '--help' in args or '-h' in args or not args:
    print('Account routing: VERCEL_ACCOUNT=personal|work, then '
          'recognized GitHub origin owner.\n'
          'Use vercel-personal login or vercel-work login to authenticate.\n'
          'Inspect the selected login with vercel whoami.', flush=True)
    if args:
        run_cli()

# Route using the directory the CLI will operate in, including --cwd.
cwd = os.getcwd()
for index, arg in enumerate(args):
    if arg == '--cwd':
        if index + 1 == len(args):
            fail('--cwd requires a directory')
        cwd = args[index + 1]
    elif arg.startswith('--cwd='):
        cwd = arg.split('=', 1)[1]
if not Path(cwd).is_dir():
    fail(f'directory does not exist: {cwd}')


def git(*arguments):
    result = subprocess.run(['@git@/bin/git', '-C', cwd, *arguments],
                            capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else ''


account = os.environ.get('VERCEL_ACCOUNT')
if not account:
    origin = git('remote', 'get-url', 'origin')
    for prefix in ('git@github.com:', 'https://github.com/', 'ssh://git@github.com/'):
        if origin.startswith(prefix):
            owner = origin.removeprefix(prefix).split('/')[0].lower()
            account = @owners@.get(owner, '')
            break
if account not in ('personal', 'work'):
    fail('use vercel-personal/vercel-work or set VERCEL_ACCOUNT=personal|work')

profile = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share'))) \
    / 'com.vercel.cli' / 'profiles' / account
profile.mkdir(parents=True, exist_ok=True, mode=0o700)
run_cli(['--global-config', str(profile)])
