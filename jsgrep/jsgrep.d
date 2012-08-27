// Explicitly stating which parts of each library I'm using to make it easier
// to find where something comes from.
import std.array: appender;
import std.exception: enforce;
import std.file: dirEntries, SpanMode, exists, isDir, isFile, readText;
import std.format: formattedWrite;
import std.getopt: getopt;
import std.json;
import std.range: split, replace;
import std.stdio: writeln, writefln;
import std.string: chomp;
import std.typecons: Flag, No, Yes;

// Simple structure to hold all of the options instead of declaring many
// individual variables.
struct Options
{
    bool recursive = false;
    string fields;
    string path;
    string file;
    bool countMatches = false;
    string entrySeparator = "\n\t";
}

int main(string[] args)
{
    bool recursive, countMatches;
    getopt(args,
           std.getopt.config.bundling,
           std.getopt.config.passThrough,
           "recursive|r", &recursive,
           "count|c", &countMatches);

    Options opts = handleArgs(args);
    opts.recursive = recursive;
    opts.countMatches = countMatches;

    size_t numMatches;

    if (opts.fields is null)
    {
        return 1;
    }

    if (opts.path !is null)
    {
        // Using SpanMode.breadth instead of SpanMode.depth as it makes more
        // sense to process every file in the current directory before diving
        // in to a sub directory.
        foreach (string fname; dirEntries(opts.path,
                                          (opts.recursive ?  SpanMode.breadth :
                                                             SpanMode.shallow)))
        {
            try
            {
                string match = getValue(fname, opts);
                if (match != "")
                {
                    if (opts.countMatches)
                    {
                        numMatches++;
                    }
                    else
                    {
                        writeln(match);
                    }
                }
            }
            catch(JSONException e)
            {
                writeln("Invalid JSON file found: ", fname, "\n", e.msg);
            }
        }
    }
    else if (opts.file !is null)
    {
        try
        {
            string match = getValue(opts.file, opts);
            if (match != "")
            {
                if (opts.countMatches)
                {
                    numMatches++;
                }
                else
                {
                    writeln(match);
                }
            }
        }
        catch(JSONException e)
        {
            writeln("Invalid JSON file found: ", opts.file, "\n", e.msg);
        }
    }
    else
    {
        writeln("No file or directory provided.");
        return 1;
    }

    if (opts.countMatches)
    {
        writefln("Found %d matching files.", numMatches);
    }
    return 0;
}

@trusted
Options handleArgs(in string[] args)
{
    Options opts;

    if (args is null || args.length < 3)
    {
        writeln(q"EOS
jsgrep - Grep fields from a JSON document.

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

Options:
    -c, --count      -- Print out the number of matching files.
    --oneline        -- Show results on only one line.
    -r, --recursive  -- Recursively search the directory.

Examples:

    jsgrep field file.json
    jsgrep foo.value /path/to/files/
    jsgrep foo.value /path/to/files/ -c
    jsgrep foo.value /path/to/files/ -r
    jsgrep foo.value,bar.value test.json --oneline
EOS");
    }
    else
    {
        for (int i = 1; i < args.length; i++)
        {
            if (args[i] == "--oneline")
            {
                opts.entrySeparator = "-";
            }
            else if (args[i].exists && args[i].isDir)
            {
                opts.path = args[i];
            }
            else if (args[i].exists && args[i].isFile)
            {
                opts.file = args[i];
            }
            else
            {
                opts.fields = args[i];
            }
        }
    }

    if (opts.file !is null && opts.entrySeparator != "-")
    {
        opts.entrySeparator = "\n";
    }

    return opts;
}

@trusted
string getValue(in string fname, in Options opts)
{
    // If for some reason we can't read the file, throw an exception.  That's
    // the purpose of the "enforce" function.
    JSONValue doc = parseJSON(enforce(chomp(readText(fname))));
    string result = getValueFromJson(doc, opts, opts.fields, No.inArray);

    // If we're dealing with a set of files, we need to print the name of the
    // matching file, so we're adding it to the string using the proper
    // formatting here.  If it's just one file, we do nothing.
    auto writer = appender!(string);
    if (opts.path !is null && opts.entrySeparator != "-")
    {
        formattedWrite(writer, "%s: \n\t%s", fname, result);
        result = writer.data;
    }
    else if (opts.path !is null)
    {
        formattedWrite(writer, "%s: %s", fname, result);
        result = writer.data;
    }
    return result;
}

@trusted
string getValueFromJson(in JSONValue doc, in Options opts, in string field,
                        in Flag!"inArray" inArray)
{
    debug(testing) { writeln("Incoming field: ", field); }
    auto fieldValues = appender!string();
    bool hasMultiple = false;
    foreach (string currField; split(field, ","))
    {
        debug(testing) { writeln("currField: ", currField); }
        JSONValue temp = cast(JSONValue)doc;
        auto usedSubstr = appender!string();
        foreach (string f; split(currField, "."))
        {
            if (temp.type == JSON_TYPE.OBJECT && f in temp.object)
            {
                temp = temp.object[f];
            }
            else if (temp.type == JSON_TYPE.ARRAY)
            {
                debug(testing) { writeln("Got an array."); }
                string substr = replace(currField, usedSubstr.data, "");
                debug(testing) { writeln("Substring for array: ", substr); }
                JSONValue arrayVals;
                arrayVals.type = JSON_TYPE.ARRAY;
                auto arrVals = appender(arrayVals.array);
                foreach (JSONValue j; temp.array)
                {
                    arrVals.put(parseJSON(getValueFromJson(j, opts, substr,
                                                           Yes.inArray)));
                    debug(testin) { writeln("Curr ArrayVals: ", arrVals.data); }
                }
                arrayVals.array = arrVals.data;
                temp = arrayVals;
                break;
            }
            else
            {
                // We just create a null object if we didn't find a match.
                temp = parseJSON(q"[]");
                break;
            }
            usedSubstr.put(f);
            usedSubstr.put(".");
            debug(testing) { writeln("Curr used substring: ", usedSubstr.data); }
        }

        string json = toJSON(&temp);
        debug(testing) { writeln("Curr JSON: ", json); }
        if (json != "null")
        {
            if (hasMultiple)
            {
                fieldValues.put(opts.entrySeparator);
            }
            if (inArray)
            {
                fieldValues.put(json);
            }
            else
            {
                formattedWrite(fieldValues, "%s=%s", currField, json);
            }
            hasMultiple = true;
        }
    }
    debug(testing) { writeln("Returning."); }
    return fieldValues.data;
}
