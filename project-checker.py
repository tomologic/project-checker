#!/usr/bin/env python
"""Program for checking basic syntax issues in projects."""

import json
import sys
import subprocess
from os.path import isfile, join, basename
import unittest
import click
from git import Git
from pycotap import TAPTestRunner
from pathexclusion import exclude_file_paths


class ProjectAnomaly(Exception):
    """Raised when a project anomaly has been detected."""

    def __init__(self, title, info="", command=""):
        """
        Initialize a project anomaly.

        Args:
            title (str): The title of the anomaly.
            info (str): Additional info about anomaly.
            command (str): The command that found the anomaly.

        """
        self.title = title
        self.info = info
        self.command = command
        super().__init__(title)

    def __str__(self):
        return "%s\n\n%s\n\n%s" % (self.title,
                                   self.info,
                                   self.command)


class ProjectChecker(unittest.TestCase):
    """
    Run checks.

    This class is implemented by using the unit test framework. The
    approach is to hi-jack the unit test framework in order to perform the
    checks of this application. That is, the purpose is not to unit
    test.
    """

    # The client must set these variable before usage.
    # Passing information through class members is not nice but it
    # is unclear how the information can be passed to the initializer,
    # since instances of this class is not explicitly instantiated.
    files_to_check = []

    def check_readme(self):
        """Check that project contains README.md."""
        readme_path = join(ProjectChecker.project_dir, 'README.md')
        if not isfile(readme_path):
            raise ProjectAnomaly("Every project must include a README.md")

    def check_trailing_white_spaces(self):
        """Check that project contains no trailing whitespaces."""

        for file_path in ProjectChecker.files_to_check:
            full_file_path = join(ProjectChecker.project_dir,
                                  file_path)
            command = (r"grep --binary-files=without-match --with-filename "
                       r"--line-number '\(\s\)\+$' %s"
                       % full_file_path)

            process = subprocess.run(command,
                                     shell=True,
                                     stdout=subprocess.PIPE,
                                     encoding='utf-8')
            if process.stdout:
                raise ProjectAnomaly(
                    title="No file may have trailing whitespaces.",
                    info=process.stdout,
                    command=command)

    def check_tabs(self):
        """Check that project contains not tabs."""
        for file_path in ProjectChecker.files_to_check:
            if file_path == 'Makefile':
                continue

            full_file_path = join(ProjectChecker.project_dir, file_path)
            command = (r"grep --binary-files=without-match --with-filename "
                       r"--line-number $'\t' %s"
                       % full_file_path)
            process = subprocess.run(command,
                                     shell=True,
                                     stdout=subprocess.PIPE,
                                     encoding='utf-8')

            if process.stdout:
                raise ProjectAnomaly(title="No files may have tabs.",
                                     info=process.stdout,
                                     command=command)

    def check_eof(self):
        """Check that all files in project follows posix standard"""
        for file_path in ProjectChecker.files_to_check:
            full_file_path = join(ProjectChecker.project_dir, file_path)
            command = """    if [ -n "$(tail -c 1 %s)" ]; then \\
                               echo "%s does not contain line-break at EOF"; \\
                               exit 1 ; \\
                             fi; """ % (full_file_path, full_file_path)

            process = subprocess.run(command,
                                     shell=True,
                                     stdout=subprocess.PIPE,
                                     encoding='utf-8')

            if process.returncode != 0:
                raise ProjectAnomaly(title="All files must end with newline.",
                                     info=process.stdout,
                                     command=command)

    def check_bash_n(self):
        """Check that all bash files has correct syntax."""
        for file_path in ProjectChecker.files_to_check:
            if file_path.endswith('.sh'):
                full_file_path = join(ProjectChecker.project_dir, file_path)
                command = 'bash -n %s' % full_file_path

                process = subprocess.run(command,
                                         shell=True,
                                         stdout=subprocess.PIPE,
                                         encoding='utf-8')

                if process.returncode != 0:
                    raise ProjectAnomaly(title=("All bash files must"
                                                " have correct syntax."),
                                         info=process.stdout,
                                         command=command)

    def check_pip_package_safety(self):
        """Check for vulnerable packages in requirements.txt"""
        requirements_path = join(ProjectChecker.project_dir,
                                 'requirements.txt')
        if basename(requirements_path) in ProjectChecker.files_to_check:
            from safety.util import read_requirements
            from safety.safety import check

            with open(requirements_path) as requirements_file:
                packages = list(read_requirements(requirements_file,
                                                  resolve=True))
            vulns = check(packages=packages,
                          key=False,  # API key to pyup.io
                          db_mirror=False,
                          cached=False,
                          ignore_ids=[],  # Vulns to ignore
                          proxy=None)
            if vulns:
                raise ProjectAnomaly(
                    title="Vulnerable package(s) in requirements.txt",
                    info=json.dumps(vulns, indent=4, sort_keys=True)
                )


def get_files_to_check(project_dir, exclude_patterns):
    """
    Get files to check.

    Given the project directory and the exclude patterns, return all version
    controlled file paths, excluding those that match any of the exclude
    patterns

    Args:
        project_dir(str): The project directory.
        exclude_patterns(list): List of file path patterns to exclude.

    Returns:
        list: All file paths to files that project checker should examine.

    """
    git = Git(project_dir)
    included_files = git.ls_files().split('\n')
    selected_files = exclude_file_paths(included_files, exclude_patterns)

    return selected_files


@click.command()
@click.option('--exclude', 'exclude_patterns', multiple=True,
              help=('Exclude paths relative to project directory by following'
                    ' the patterns of the python method fnmatch: %s .'
                    ' E.g foo/*.jpg'
                    % 'https://docs.python.org/3.4/library/fnmatch.html'))
def run(exclude_patterns):
    """Program that checks basic syntax in a project."""

    project_dir = '/project'
    ProjectChecker.project_dir = project_dir

    ProjectChecker.files_to_check = get_files_to_check(
        project_dir=project_dir,
        exclude_patterns=list(exclude_patterns))

    loader = unittest.TestLoader()
    loader.testMethodPrefix = 'check'
    suite = loader.loadTestsFromTestCase(ProjectChecker)
    result = TAPTestRunner().run(suite)
    exit_status = 0 if result.wasSuccessful() else 1
    sys.exit(exit_status)


if __name__ == '__main__':
    # pylint: disable=no-value-for-parameter
    # https://github.com/landscapeio/landscape-issues/issues/144
    run()
