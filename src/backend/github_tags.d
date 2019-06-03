module backend.github_tags;

import std.json;
import std.regex;
import std.format : format;
import std.net.curl : get, HTTPStatusException;

import resolver;

string getGithubTagsVersion(string pkg)
{
    JSONValue j;

    /* get package version */
    try {
        j = parseJSON(get(
            format!"https://api.github.com/repos/%s/git/refs/tags"(pkg)
        ));
    } catch(JSONException e) {
        return "";
    } catch(HTTPStatusException e) {
        return "";
    }

    if(j.array.length &&
       "ref" in j.array[$ - 1])
        return replaceAll(j.array[$ - 1]["ref"].str, r"refs\/tags\/[v]*".regex, "");

    return "";
}
