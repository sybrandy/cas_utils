import std.stdio;
import std.array;
import std.conv;
import std.format;
import std.string;

string toRedisProto(string command)
{
    string[] args = split(command);
    auto proto = appender!(string)();

    if (args[2].indexOf("\"") == 0)
    {
        formattedWrite(proto, "*%d\r\n", 3);
        formattedWrite(proto, "$%d\r\n%s\r\n", args[0].length, args[0]);
        formattedWrite(proto, "$%d\r\n%s\r\n", args[1].length, args[1]);
        string value = command[command.indexOf("\"")..$];
        formattedWrite(proto, "$%d\r\n%s\r\n", value.length, value);
    }
    else
    {
        formattedWrite(proto, "*%d\r\n", args.length);

        foreach (string arg; args)
        {
            formattedWrite(proto, "$%d\r\n%s\r\n", arg.length, arg);
        }
    }

    return proto.data;
}

unittest
{
    assert(toRedisProto(q"[SET key value]") == "*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$5\r\nvalue\r\n");
    assert(toRedisProto(q"[SET key "some value"]") == "*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$12\r\n\"some value\"\r\n");
}

void main()
{
    version(unittest)
    {
        writeln("Executing unit tests.");
    }
    else
    {
        // TODO: Read from STDIN and send output to STDOUT.
    }
}
