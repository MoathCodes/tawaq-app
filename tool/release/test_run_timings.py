import unittest

from run_timings import markdown, seconds, timing_rows


class RunTimingsTests(unittest.TestCase):
    def test_durations_come_from_started_and_completed_times(self):
        self.assertEqual(seconds('2026-10-25T19:20:40Z', '2026-10-25T19:22:38Z'), 118)
        self.assertIsNone(seconds(None, '2026-10-25T19:22:38Z'))

    def test_every_job_and_step_gets_a_row(self):
        jobs = [{'name': 'Windows', 'started_at': '2026-10-25T19:20:39Z',
                 'completed_at': '2026-10-25T19:29:40Z',
                 'steps': [{'name': 'Codegen', 'started_at': '2026-10-25T19:22:38Z',
                            'completed_at': '2026-10-25T19:24:55Z'},
                           {'name': 'Skipped', 'started_at': None, 'completed_at': None}]}]
        self.assertEqual(timing_rows(jobs), [('Windows', '(job)', 541), ('Windows', 'Codegen', 137),
                                             ('Windows', 'Skipped', None)])
        self.assertIn('| Windows | Codegen | 137 |', markdown(timing_rows(jobs)))
        self.assertIn('| Windows | Skipped | - |', markdown(timing_rows(jobs)))


if __name__ == '__main__':
    unittest.main()
