"""Run with a Python containing PyYAML and `hermes` on PATH; no live writes."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import yaml

ROOT = Path(__file__).resolve().parent


class SkillPolicyTests(unittest.TestCase):
    def test_cli_preserves_unmanaged_settings_and_is_idempotent(self):
        desired = json.loads((ROOT / 'skills/disabled.json').read_text())
        self.assertEqual(len(desired), len(set(desired)))
        self.assertIn('claude-design', desired)
        for name in ['test-driven-development', 'systematic-debugging', 'requesting-code-review']:
            self.assertIn(name, desired)
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            config = home / 'config.yaml'
            original = {'model': {'provider': 'example', 'default': 'keep-me'},
                        'skills': {'disabled': ['old'], 'custom': 'preserve'},
                        'memory': {'memory_enabled': False}}
            config.write_text(yaml.safe_dump(original))
            expected = {**original, 'skills': {**original['skills'], 'disabled': desired}}
            env = {**os.environ, 'HERMES_HOME': tmp}
            for _ in range(2):
                subprocess.run(['hermes', 'config', 'set', '--force', 'skills.disabled',
                                json.dumps(desired)], env=env, check=True, capture_output=True)
                self.assertEqual(yaml.safe_load(config.read_text()), expected)

    def test_compact_entries_and_preserved_guides(self):
        for rel in ['autonomous-ai-agents/hermes-agent',
                    'autonomous-ai-agents/computer-use', 'research/grounded-citations']:
            skill = ROOT / 'skills' / rel
            entry = (skill / 'SKILL.md').read_text()
            guide = (skill / 'references/detailed-guide.md').read_text()
            self.assertEqual(yaml.safe_load(entry.split('---', 2)[1])['name'], skill.name)
            self.assertLess(len(entry), 4000)
            self.assertGreater(len(guide), len(entry))
            self.assertIn('references/detailed-guide.md', entry)


if __name__ == '__main__':
    unittest.main()
