# jsgrep

A tool for extracting one or more elements from a JSON document.

This program will print out one or more fields from one or more JSON files.
If a file name is passed in, then only the fields from that file are printed
out.  If a directory is passed in, then the field in all of the files will be
printed out.  Nested fields are separated via a period and multiple fields are
separated by a comma.

If "-c" is used, then it will only print out the number of files that matched
at least one of the conditions.  This is most useful if one is looking to see
if a specific element exists in a data set.

Normally, the output is human-readable with the matching filename on oneline
and one or more indented lines below it containing the matches.  However, this
is not ideal for scripts or piping, so the --oneline option is provided to
allow easier processing of the data via scripts.

## DEPENDENCIES

A D compiler.  Currently using v. 2.060. - [http://dlang.org/](http://dlang.org/)

## FILE LIST

jsgrep.d

## USAGE

Grep for a field in a single file:

    jsgrep field file.json

Grep files in a directory for a field:

    jsgrep field /path/to/files/

Grep files for a nested field:

    jsgrep foo.bar.baz /path/to/files/

Grep a directory recursively:

    jsgrep -r field /path/to/files/

Grep for multiple fields:

    jsgrep foo.value,bar.value,baz.value /path/to/files

Display the results on a single line:

    jsgrep field /path/to/files --oneline

Display the number of files that match at least one of the fields:

    jsgrep foo.value,bar.value,baz.value /path/to/files -c

## CONFIGURATION

Describe any configuration that needs/should occur here...Filled out as
needed.

## BUILD INSTRUCTIONS

For DMD: dmd -O -releaes jsgrep.d

## KNOWN LIMITATIONS/DEFECTS

Currently, we do not grep for values.  This can be done by piping the reults
through grep.  If this becomes an issue, it can be revisited.

## TODO
