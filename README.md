# Project Checker

## Purpose

The purpose of this app is to check if a project fulfills basic
requirements.

## Prerequisites

* Make, Docker and Docker Compose - building and using the application
* Bats, Git - for running tests locally
  (https://github.com/sstephenson/bats)


## Build

    make build

## Test

    make verify

## Run

The following examples all assume that the project to be checked is
the current directory and that the project is version controlled by
Git.

    docker run -v "${PWD}:/project" --rm IMAGE

    docker run -v "${PWD}:/project" --rm IMAGE

    docker run -v "${PWD}:/project" --rm IMAGE \
        --exclude legacy/code/*.png


The file path patterns that can be excluded by the `exclude` flag are
documented here: https://docs.python.org/3.4/library/fnmatch.html

## Contribute

### Commit messages

This project adheres to the seven rules of a great Git commit message:

1. Separate subject from body with a blank line.
2. Limit the subject line to 50 characters.
3. Capitalize the subject line.
4. Do not end the subject line with a period.
5. Use the imperative mood in the subject line.
6. Wrap the body at 72 characters.
7. Use the body to explain what and why vs. how.

## Checks and their rationales

### Readme check

Every project's root directory should contain a README.md file (in
UTF-8 English) in the project root that answers these questions:

* Purpose: Why does the project exist?

* Prerequisites: What is required to build, test, and run the project?

* Build: How to build the project?

* Test: How to run test suites or manually test the project?

* Run: How to run the project?

* Contribute: How to contribute to the project?

The readme should be brief and not overwhelming to the
reader. Detailed documentation etc should be accessible through
references rather than being part of the actual README.md itself.

### Trailing white space check

Trailing white spaces have several drawbacks (See
https://softwareengineering.stackexchange.com/questions/121555/why-is-trailing-whitespace-a-big-deal)
for an interesting discussion. The following is a summary

* They look ugly in diff views such as Git and Gerrit.

* Many editors removes trailing white spaces as default. This means
  that if trailing white spaces exist then the developer has to remove
  these changes manually during a commit in order to not confuse the
  reader.

* Git warns about trailing white spaces

* Going to the end of a line in an editor will have unexpected
  behavior with trailing white spaces.

* Trailing white spaces are hard to see; it makes sense to not have
  invisible characters.

Remark: In markdown languages, two white spaces at the end of a line
has special meaning. However, most flavors, for example Pandoc and
CommonMark has other ways of expressing the same thing
("\"+newline). Although not confirmed, it is likely that Gerrit,
GitLab and GitHub allows the backslash+newline syntax.

### Newline at end-of-file check

A file that does not end with a newline is not a valid POSIX text
file, since a line must end with a newline. Except this fact, many
editors automatically adds a newline at the end for convenience, and
the consequence is that modifying a file in one place may cause a
change in the end of the file. Also, Git warns about non POSIX text
files.

Another problem with the absence of newlines is that command line
tools such as `tail` gives unexpected behavior.

For more info, see
https://stackoverflow.com/questions/729692/why-should-text-files-end-with-a-newline

### Syntax check on shell scripts

The `bash -n` syntax check is very basic, so each meaningful shell
script should be able to pass it.

## Implementation

The presentation of the checks has been implemented with Python and
Python's `unittest` module in combination with Pycotap, which ensures
that the output of `unittest` is TAP compatible:
http://testanything.org/

The reason why not Bats (https://github.com/sstephenson/bats) was used
is that it was found inconvenient for handling user options. Project
checker has flags which allow the user to exclude directories from the
checks, and passing such options is convenient with a higher level
language such as Python.

Some checks are implemented in Python exclusively, and some checks are
implemented using Linux commands such as `find` and `grep`.

## License

This software is released under the MIT license. See the file LICENSE
for details.
