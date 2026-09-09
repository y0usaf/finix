"""Reproduce inherited gateway cwd and verify the CLI boundary repair.
Run using the packaged Hermes Python, not a system Python without its deps.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

probe = '''
import os,json
from types import SimpleNamespace
from hermes_cli.main import _apply_in_dir
_apply_in_dir(SimpleNamespace(in_dir=os.environ['PROBE_DIR']))
import cli
cli.load_cli_config()
print('CWD_PROBE='+json.dumps({'process':os.getcwd(),'tools':os.environ.get('TERMINAL_CWD')}))
'''
with tempfile.TemporaryDirectory(prefix='hermes-cwd-test-') as tmp:
    root=Path(tmp); target=root/'project'; target.mkdir()
    home=root/'hermes';home.mkdir()
    (home/'config.yaml').write_text('terminal:\n  env_type: local\n  cwd: /old-parent\n')
    base=dict(os.environ,HERMES_HOME=str(home),PROBE_DIR=str(target),TERMINAL_ENV='local',TERMINAL_CWD='/old-parent')
    observed={}
    for mode in ['inherited','clean-cli']:
        env=dict(base)
        if mode=='inherited':env['_HERMES_GATEWAY']='1'
        else:env.pop('_HERMES_GATEWAY',None)
        result=subprocess.run([sys.executable,'-c',probe],env=env,text=True,capture_output=True,check=True)
        line=next(l for l in result.stdout.splitlines() if l.startswith('CWD_PROBE='))
        observed[mode]=json.loads(line.split('=',1)[1])
    assert observed['inherited']=={'process':str(target),'tools':'/old-parent'},observed
    assert observed['clean-cli']=={'process':str(target),'tools':str(target)},observed
    if len(sys.argv)>1:
        launcher=Path(sys.argv[1]).read_text()
        assert '\nunset _HERMES_GATEWAY\n' in launcher
    print('PASS: actual --in + CLI config reproduces inherited gateway cwd; clearing process marker aligns process and tools. Built launcher checked.' if len(sys.argv)>1 else 'PASS: cwd regression')
