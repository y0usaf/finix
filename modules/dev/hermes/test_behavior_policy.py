"""Behavior policy regression: temporary HERMES_HOME only; requires PyYAML."""
import copy
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import yaml

ROOT = Path(__file__).resolve().parent


class BehaviorPolicyTests(unittest.TestCase):
    def test_cli_policy_is_idempotent_and_preserves_unmanaged_keys(self):
        desired = json.loads((ROOT / 'behavior-settings.json').read_text())
        self.assertEqual(desired['agent.reasoning_effort'], 'low')
        original = {'agent': {'reasoning_effort': 'medium', 'max_turns': 90},
                    'model': {'default': 'preserve-model'},
                    'memory': {'provider': 'old', 'custom': 'preserve'},
                    'auxiliary': {'compression': {'provider': 'preserve'}},
                    'custom': {'value': 'preserve'}}
        expected = copy.deepcopy(original)
        for key, value in desired.items():
            node = expected
            parts = key.split('.')
            for part in parts[:-1]:
                node = node.setdefault(part, {})
            node[parts[-1]] = value
        with tempfile.TemporaryDirectory() as tmp:
            config = Path(tmp) / 'config.yaml'
            config.write_text(yaml.safe_dump(original))
            env = {**os.environ, 'HERMES_HOME': tmp}
            for _ in range(2):
                for key, value in sorted(desired.items()):
                    subprocess.run(['hermes', 'config', 'set', '--force', key,
                                    value if isinstance(value, str) else json.dumps(value)],
                                   env=env, check=True, capture_output=True, timeout=30)
                self.assertEqual(yaml.safe_load(config.read_text()), expected)

    def test_soul_has_one_correct_messaging_contract(self):
        soul = (ROOT / 'SOUL.md').read_text()
        self.assertEqual(soul.count('hermes -p <agent-name>'), 1)
        self.assertNotIn('notify_on_complete', soul)
        self.assertIn('`notify=true`', soul)
        self.assertIn('Continue independent work', soul)


if __name__ == '__main__':
    unittest.main()
