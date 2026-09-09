"""Run with python3; only temporary config files are modified."""
import importlib.util
from pathlib import Path
import tempfile
import tomllib
import unittest

spec = importlib.util.spec_from_file_location('policy', Path(__file__).with_name('apply-reasoning-policy.py'))
assert spec is not None and spec.loader is not None
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)


class ReasoningPolicyTests(unittest.TestCase):
    def test_preservation_and_idempotence(self):
        for text in ['', 'model = "gpt-6-astra"\nmodel_reasoning_effort = "medium"\n',
                     '# comment\n[profiles.other]\nmodel_reasoning_effort = "max"\n',
                     '"model_reasoning_effort" = "medium"\n[tools]\nenabled = true\n']:
            with self.subTest(text=text), tempfile.TemporaryDirectory() as tmp:
                path = Path(tmp) / 'config.toml'
                path.write_text(text)
                expected = {**tomllib.loads(text), 'model_reasoning_effort': 'low'}
                policy.apply(path)
                first = path.read_text()
                self.assertEqual(tomllib.loads(first), expected)
                policy.apply(path)
                self.assertEqual(path.read_text(), first)


if __name__ == '__main__':
    unittest.main()
