module resolver;

import std.regex;
import std.stdio : writefln;
import core.stdc.string : strcmp;

string normalizeVersion(string v)
{
    return replaceAll(v, r"[^0-9]".regex, "");
}

bool compareVersions(string high, string low)
{
    return strcmp(
        cast(const(char*)) normalizeVersion(high),
        cast(const(char*)) normalizeVersion(low)
    ) <= 0;
}

void printVersions(string[string] versions, string target, string pkg, string[string] prettyname)
{
    string upstream = "";
    string ver = "";
    /* get higher upstream version */
    foreach(key, value; versions)
    {
        /* upstreams */
        if(key == "github" ||
            key == "github-releases" ||
            key == "github-tags" ||
            key == "git")
        {
            if(ver == "")
                ver = value;

            if(compareVersions(ver, value))
            {
                upstream = key;
                ver = value;
            }
        }
    }

    foreach(key, value; versions)
    {
        /* resolve versions for last package */
        if(target != "")
        {
            /* downstreams */
            if(key == "arch" &&
               ver != "" &&
               value != "" &&
               ver != value &&
               compareVersions(value, ver))
                writefln("Package '%s' is outaded. (%s vs %s on %s)", pkg, value, ver, prettyname[upstream]);

        } else {
            if(value != "")
                writefln("Package '%s' is on version '%s' on %s", pkg, value, prettyname[key]);
        }
    }

}
