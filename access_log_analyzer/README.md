# access_log_analyzer

A tool for analyzing Apache access logs.

This is meant to be a simple command-line app to perform some basic analysis
on Apache access logs.  The types of analysis performed are:

* Top N IP addresses with counts
* Status code counts
* Bytes retrieved per day
* Requests per day
* Cohort Analysis

By default, the first three will be calculated.  Cohort analysis must be
explicitly specified on the command line and the results will be formatted in
a delimited format.  All output will be done via STDOUT.

## DEPENDENCIES

A D compiler.  Currently using v. 2.060.

## FILE LIST

alanalyzer.d

## USAGE

Show basic statistics:

    alanalyzer /path/to/access_log

Set the number of IP addresses (default 10):

    alanalyzer /path/to/access_log -n 20

Perform cohort analysis:

    alanalyzer /path/to/access_log --cohort

Perform cohort analysis with a specified config file:

    alanalyzer /path/to/access_log --cohort -c /path/to/file.cfg

## CONFIGURATION

The config file is strictly for the cohort analysis.  Each line is a specific
part of a path that we want to match against.  The thought here is that we
don not necessarily care that users have visited the error page.  We care if
they have visited the "Reports" section or the "Books" section of the site.
Good restful sites will have paths that reflect this, like "/Reports/view" or
"/Books/browse".  Therefore, we can leverage that to see which portions of a
site are being used the most by users and which are not used as much.  These
strings will match the start of a URL, therefore if we have "/Books" in our
config, we will match every URL that starts with "/Books".  Any URL with a "/"
at the end will match the entire URL.  This is good for matching the home page
of the site.  Anything not specified in the list of strings is ignored.

Example:

    /Books/Fantasy
    /Books/History
    /Music/Rock

## BUILD INSTRUCTIONS

For DMD: dmd -O -release alanalyzer.d

## KNOWN LIMITATIONS/DEFECTS

## TODO
