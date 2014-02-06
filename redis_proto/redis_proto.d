import std.stdio;
import std.array;
import std.conv;
import std.format;
import std.string;
import std.parallelism;

/**
 * Converts a redis command to the Redis protocol format.
 * Params:
 *   command = The command to be translated.
 * Returns: The command rewritten in the Redis protocol format.
 */
string toRedisProto(string command)
{
    auto proto = appender!(string)();

    // Check to see if we can use a "fast" method to parse the command.
    if (command.indexOf("\"") > 0)
    {
        // If there are quotes, we run the command through a parser before
        // reformatting it.
        string[] parts = parseString(command);
        formattedWrite(proto, "*%d\r\n", parts.length);
        for (int i = 0; i < parts.length; i++)
        {
            formattedWrite(proto, "$%d\r\n%s\r\n", parts[i].length, parts[i]);
        }
    }
    else
    {
        // No quotes, so split the command using spaces before formatting.
        string[] args = split(command);
        formattedWrite(proto, "*%d\r\n", args.length);

        foreach (string arg; args)
        {
            formattedWrite(proto, "$%d\r\n%s\r\n", arg.length, arg);
        }
    }

    debug(testing) { writeln("Data: ", proto.data); }
    return proto.data;
}

/**
 * Parse the various portions of the Redis command into separate array
 * elements.
 *
 * Params:
 *    command = The command to be parsed.
 * Returns: An array containing the parts of the command.
 */
// TODO: Consider ensuring this works with embedded quotes, if necessary.
pure
string[] parseString(string command)
{
    string[] parts;
    char[] collector;
    bool inQuotes = false;
    foreach (char ch; command)
    {
        if (ch == '\"' && !inQuotes)
        {
            inQuotes = true;
        }
        else if (ch == '\"' && inQuotes)
        {
            inQuotes = false;
        }
        else if (!inQuotes && ch == ' ')
        {
            parts ~= collector.idup;
            collector = [];
        }
        else
        {
            collector ~= ch;
        }
    }
    parts ~= collector.idup;
    debug(testing) { writeln("current parts: ", parts); }
    return parts;
}

unittest
{
    assert(toRedisProto(q"[SET key value]") ==
           "*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$5\r\nvalue\r\n");
    assert(toRedisProto(q"[SET key "some value"]") ==
           "*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$10\r\nsome value\r\n");
    assert(toRedisProto(q"[HMSET hashkey first "value" second "value"]") ==
           "*6\r\n$5\r\nHMSET\r\n$7\r\nhashkey\r\n$5\r\nfirst\r\n$5\r\nvalue\r\n$6\r\nsecond\r\n$5\r\nvalue\r\n");
}

void main()
{
    version(unittest)
    {
        writeln("Executing unit tests.");
    }
    else
    {
        auto reader = taskPool.asyncBuf(stdin.byLine);
        foreach (char[] line; reader)
        {
            write(toRedisProto(line.idup));
        }
    }
}
