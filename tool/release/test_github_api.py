import unittest
from unittest.mock import patch

from github_api import gh_json


class GhJsonTests(unittest.TestCase):
    def call(self, output, **kwargs):
        with patch('github_api.subprocess.run') as process:
            process.return_value.stdout = output
            return gh_json('repos/o/r/releases', **kwargs), process.call_args.args[0]

    def test_single_document(self):
        result, command = self.call('{"workflow_runs": []}')
        self.assertEqual(result, {'workflow_runs': []})
        self.assertEqual(command, ['gh', 'api', 'repos/o/r/releases'])

    def test_paginated_pages_are_returned_separately(self):
        result, command = self.call('[{"tag_name":"a"}]\n[{"tag_name":"b"}]\n', paginate=True)
        self.assertEqual(result, [[{'tag_name': 'a'}], [{'tag_name': 'b'}]])
        self.assertIn('--paginate', command)

    def test_adjacent_pages_without_whitespace(self):
        result, _ = self.call('[{"tag_name":"a"}][{"tag_name":"b"}]', paginate=True)
        self.assertEqual(len(result), 2)


if __name__ == '__main__':
    unittest.main()
