import std.algorithm: sort, stripRight, replace, startsWith, endsWith, map, reduce, max;
import std.array: array, split, appender, join;
import std.conv: to;
import std.format: formattedWrite;
import std.getopt: getopt, config;
import std.range: take;
import std.stdio: writefln, writef, writeln, File;
import std.string: cmp;

int main(string[] args)
{
    int numIPs = 10;
    bool doCohort = false;
    string configFile;
    string logFile;

    getopt(args,
           config.passThrough,
           "num|n", &numIPs,
           "cohort", &doCohort,
           "config|c", &configFile);

    debug(config)
    {
        writeln("Num IPs: ", numIPs);
        writeln("Do Cohort Analysis: ", doCohort);
        writeln("Config File: ", configFile);
    }

    if (args is null || args.length < 2)
    {
        writeln(q"EOS
Make sure we have something here!
EOS");
    }
    else
    {
        logFile = args[1];
    }

    debug(config) { writeln("Log file: ", logFile); }

    if (!doCohort)
    {
        getStats(logFile, numIPs);
    }
    else
    {
        getCohort(logFile, configFile);
    }

    return 0;
}

struct Rec
{
    string ipAddress;
    string identity;
    string user;
    string date;
    string requestType;
    string resource;
    string protocol;
    string statusCode;
    long bytes;
}

void getStats(in string logFile, in int numIPs)
{
    long[string] ips;
    long[string] codes;
    long[string] requests;
    long[string] bytesData;

    File f = File(logFile);
    char[] line;
    while(f.readln(line))
    {
        debug(testing) { writeln("Current line: ", line); }
        Rec reqData = parseLine(line);
        debug(testing) { writeln("Current record: ", reqData); }

        ips[reqData.ipAddress] = (reqData.ipAddress in ips)
                               ? ips[reqData.ipAddress] + 1
                               : 1;
        codes[reqData.statusCode] = (reqData.statusCode in codes)
                                  ? codes[reqData.statusCode] + 1
                                  : 1;
        requests[reqData.date] = (reqData.date in requests)
                               ? requests[reqData.date] + 1
                               : 1;
        bytesData[reqData.date] = (reqData.date in bytesData)
                                ? requests[reqData.date] + reqData.bytes
                                : reqData.bytes;
    }

    debug(testing)
    {
        writeln("\n\n");
        writeln("IP data: ", ips);
        writeln("Status Code data: ", codes);
        writeln("Request data: ", requests);
        writeln("Data Size data: ", bytesData);
    }

    printTopIps(ips, numIPs);
    printSep();
    printStatusCodes(codes);
    printSep();
    printRequests(requests);
    printSep();
    printDataSize(bytesData);
}

Rec parseLine(in char[] line)
{
    Rec rec;

    string[] fields = split(stripRight(line.idup), " ");
    rec.ipAddress = fields[0];
    rec.identity = fields[1];
    rec.user = fields[2];
    rec.date = toIsoDate(fields[3].replace("[", ""));
    rec.requestType = fields[5].replace("\"", "");
    debug(testing) { writeln("Request Type: ",  rec.requestType); }
    rec.resource = fields[6];
    if (startsWith(fields[7], "HTTP"))
    {
        rec.protocol = fields[7].replace("\"", "");
        rec.statusCode = fields[8];
        rec.bytes = (fields[9] != "-") ? to!(long)(fields[9]) : 0;
    }
    else if (rec.requestType == "-")
    {
        rec.statusCode = fields[6];
        rec.bytes = (fields[7] != "-") ? to!(long)(fields[7]) : 0;
    }
    else
    {
        rec.statusCode = fields[7];
        rec.bytes = (fields[8] != "-") ? to!(long)(fields[8]) : 0;
    }

    return rec;
}

string toIsoDate(in string date)
{
    string[string] monthMap = ["Jan": "01", "Feb": "02", "Mar": "03",
                               "Apr": "04", "May": "05", "Jun": "06",
                               "Jul": "07", "Aug": "08", "Sep": "09",
                               "Oct": "10", "Nov": "11", "Dec": "12"];
    string[] parts = split(date, ":")[0].split("/");

    return parts[2] ~ "-" ~ monthMap[parts[1]] ~ "-" ~ parts[0];
}

auto printSep = () => writeln("\n====================\n");

// TODO: Find a better way to do this as an O(n^2) algorithm isn't very good.
void printTopIps(long[string] ips, in int num)
{
    long[] sortedSizes = ips.values.sort!("a > b")().take(num).array;
    debug(testing) { writeln("Sorted size: ", sortedSizes); }

    writefln("Top %d IP Addresses:\n", num);
    foreach(long size; sortedSizes)
    {
        foreach(string key, long value; ips)
        {
            if (value == size)
            {
                writefln("%-15s -- %d", key, value);
                break;
            }
        }
    }
}

void printStatusCodes(in long[string] codes)
{
    writeln("Status codes:\n");
    foreach (string key; codes.keys.sort)
    {
        writefln("%-3s -- %d", key, codes[key]);
    }
}

void printRequests(in long[string] requests)
{
    writeln("Requests per day:\n");
    foreach (string key; requests.keys.sort)
    {
        writefln("%-10s -- %d", key, requests[key]);
    }
}

void printDataSize(in long[string] bytesData)
{
    writeln("Bytes of data per day:\n");
    foreach (string key; bytesData.keys.sort)
    {
        writefln("%-10s -- %d", key, bytesData[key]);
    }
}

struct CohortKey
{
    string date;
    string cohort;

    this(string d, string c)
    {
        date = d;
        cohort = c;
    }

    const hash_t toHash()
    {
        hash_t hash;
        foreach (char c; date ~ cohort)
              hash = (hash * 9) + c;
        return hash;
    }

    const bool opEquals(ref const CohortKey ck)
    {
        return cmp(date ~ cohort, ck.date ~ ck.cohort) == 0;
    }

    const int opCmp(ref const CohortKey ck)
    {
        return cmp(date ~ cohort, ck.date ~ ck.cohort);
    }
}

void getCohort(in string logFile, in string configFile)
{
    string[] cohorts = getCohorts(configFile);
    long[CohortKey] cohortList;

    File f = File(logFile);
    char[] line;
    while(f.readln(line))
    {
        debug(testing) { writeln("Current line: ", line); }
        Rec reqData = parseLine(line);
        debug(testing) { writeln("Current record: ", reqData); }

        foreach (string c; cohorts)
        {
            bool fullMatch = c.endsWith("/");
            if (!fullMatch && reqData.resource.startsWith(c))
            {
                CohortKey ck = CohortKey(reqData.date, c);
                cohortList[ck] = (ck in cohortList) ? cohortList[ck] + 1 : 1;
                break;
            }
            else if (fullMatch && reqData.resource == c)
            {
                CohortKey ck = CohortKey(reqData.date, c);
                cohortList[ck] = (ck in cohortList) ? cohortList[ck] + 1 : 1;
                break;
            }
        }
    }

    debug(testing) { writeln("Cohort list: ", cohortList); }

    long[string] dayCounts;
    foreach (CohortKey k, long value; cohortList)
    {
        dayCounts[k.date] = (k.date in dayCounts)
                          ? dayCounts[k.date] + value
                          : value;
    }

    printCohorts(cohorts, cohortList, dayCounts);
}

string[] getCohorts(in string configFile)
{
    auto cohorts = appender!(string[]);
    File f = File(configFile);
    char[] line;
    while (f.readln(line))
    {
        cohorts.put(line.idup.stripRight);
    }

    debug(testing) { writeln("Cohorts: ", cohorts.data); }
    return cohorts.data.sort;
}

void printCohorts(in string[] cohorts, in long[CohortKey] cohortList, in long[string] dayCounts)
{
    int strLen = cohorts.map!("a.length")().reduce!(max)();
    debug(testing) { writeln("Max cohort string length: ", strLen); }

    string strFormat = "\t%" ~ to!(string)(strLen) ~ "s";
    string numFormat = "%#" ~ to!(string)(strLen) ~ ".1f";

    writef("%-10s", "Date");
    foreach(string c; cohorts)
    {
        writef(strFormat, c);
    }
    writef("\n", "");
    foreach(string day; sort(dayCounts.keys))
    {
        auto currData = appender!(string[]);
        long currCount = dayCounts[day];

        foreach (string c; cohorts)
        {
            CohortKey ck = CohortKey(day, c);
            auto formattedString = appender!(string);
            float percent = (ck in cohortList)
                          ? (cast(double)(cohortList[ck]) /
                                  cast(double)currCount) * 100
                          : 0.0;
            formattedWrite(formattedString, numFormat, percent);
            currData.put(formattedString.data);
        }

        writefln("%s\t%s\t(%d)", day, currData.data.join("\t"), currCount);
    }
}
