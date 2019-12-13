"""Provide functionality for path exclusion."""
import fnmatch


def _matching_patterns(file_path, patterns):
    """Select all patterns that match the file path."""
    return [pattern
            for pattern
            in patterns
            if fnmatch.fnmatch(file_path, pattern)]


def exclude_file_paths(file_paths, exclude_patterns):
    """
    Exclude relative files paths based on a list of exclude patterns.

    Args:
        file_paths(list): list of relative paths
        exclude_patterns(list): list of exclude patterns following the syntax
                                of python method fnmatch.fnmatch:
                               https://docs.python.org/3.4/library/fnmatch.html

    Returns:
        list: The list of the file_paths that does not match any exclude
              pattern.

    """
    return [file_path
            for file_path
            in file_paths
            if not _matching_patterns(file_path, exclude_patterns)]
