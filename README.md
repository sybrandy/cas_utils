# CAS_Utils

This is a collection of various utilities that I created.  A short description
of each is as follows:

## access_log_analyzer

A utility for performing some quick analysis of an Apache access log.  It
performs some basic analysis, but also does Cohort Analysis which can be used
to see how popular parts of the site are at different times.  This can be
useful for seeing if users are progressing from login and sign-up pages to
other areas of the site.

## jsgrep

jsgrep is a small utility written using the D Programming Language to grep
JSON files.  This was created to be able to view parts of a JSON document
quickly and easily.  It is designed to be similar to grep from a command-line
perspective.  It only filters of fields and not values as my current use case
was to see what values are in one or more documents.

## redis_proto

redis_proto is a simple utility to take an input stream of Redis commands and
convert them to the Redis protocol.  This would be used when one has to bulk
load data into Redis via the --pipe option.
