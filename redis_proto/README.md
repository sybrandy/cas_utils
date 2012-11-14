# redis_proto

A tool for converting a series of Redis commands into a single protocol
string.

This is useful for taking a file that contains individual Redis command and
having it automatically converted to the Redis protocol format for efficiency.
E.g.

    SET key value

Becomes

    *3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$5\r\nvalue\r\n

## DEPENDENCIES

A D compiler.  Currently using v. 2.060. - [http://dlang.org/](http://dlang.org/)

## FILE LIST

redis_proto.d

## USAGE

Convert from a list of commands to the protocol format:

    redis_proto < commands.txt > protocol.txt

Convert a list of commands and pipe through redis-cli:

    redis_proto < commands.txt | redis-cli --pipe

## CONFIGURATION

## BUILD INSTRUCTIONS

For DMD: dmd -O -release redis_proto.d

If DMD is installed, you can also use the associated Makefile to generate the
different builds.  There are three make targets:

* release -- Creates a release build.
* debug -- Creates a version with debugging statements enabled.
* profile -- Creates a version with profiling turned on.

## KNOWN LIMITATIONS/DEFECTS

## TODO
