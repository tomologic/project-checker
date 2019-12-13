from unittest import TestCase
from pathexclusion import exclude_file_paths


class ExcludeFilePathsTest(TestCase):
    def test__excluding_files_among_no_files_results_in_no_files(self):
        self.assertEqual(exclude_file_paths([], []), [])

    def test__excluding_only_file_without_wildcard_results_in_no_files(self):
        self.assertEqual(exclude_file_paths(['foo.txt'], ['foo.txt']), [])

    def test__excluding_no_file_results_in_same_files(self):
        self.assertEqual(exclude_file_paths(['foo.txt'], []), ['foo.txt'])

    def test__excluding_all_files_in_sub_dir_results_in_no_files_from_that_directory(self):
        self.assertEqual(exclude_file_paths(['foo/bar.txt'],
                                            ['foo/*']), [])
