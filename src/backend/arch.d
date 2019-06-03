module backend.arch;

import std.json;
import std.regex;
import std.stdio : writeln, writefln;
import std.format : format;
import std.net.curl : get;
import std.string : split;

string getArchVersion(string pkg)
{
    JSONValue j;

    /* try to find repo and arch if not specified */
    if(!matchFirst(pkg, r".*/.*/.*".regex))
    {
        try {
            j = parseJSON(get(
                format!"https://www.archlinux.org/packages/search/json/?name=%s"(("/" ~ pkg).split("/")[$ - 1])
            ));
        } catch(JSONException e) {
            return "";
        }

        if(!("valid" in j && j["valid"].boolean &&
             "version" in j && j["version"].integer == 2))
        {
            writeln("[WARN] Archlinux: (API error) invalid response");
            return "";
        }

        if(j["results"].array.length == 0)
        {
            writefln("[WARN] Archlinux: Package '%s' not found", pkg);
            return "";
        }

        /* TODO: Filter out -testing,
                 even though they appear to only show up after their non
                 -testing counterparts. */
        pkg = format!"%s/%s/%s"(
            j["results"][0]["repo"].str,
            j["results"][0]["arch"].str,
            j["results"][0]["pkgname"].str
        );
    }

    /* get package version */
    try {
        j = parseJSON(get(
            format!"https://www.archlinux.org/packages/%s/json"(pkg)
        ));
    } catch(JSONException e) {
        return "";
    }

    if(!("pkgver" in j))
    {
        writeln("[WARN] Archlinux API error: pkgver not found");
        return "";
    }

    return j["pkgver"].str;
}
