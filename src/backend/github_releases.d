module backend.github_releases;

import std.json;
import std.regex;
import std.format : format;
import std.net.curl : get, HTTPStatusException;

string getGithubReleasesVersion(string pkg)
{
    JSONValue j;

    /* get package version */
    try {
        j = parseJSON(get(
            format!"https://api.github.com/repos/%s/releases"(pkg)
        ));
    } catch(JSONException e) {
        return "";
    } catch(HTTPStatusException e) {
        return "";
    }

    /* releases array seems to be sorted by lastest first */
    /* name or tag_name ? */
    if(j.array.length > 0 &&
       "name" in j.array[0])
       return replaceAll(j.array[0]["name"].str, r"refs\/tags\/[v]*".regex, "");

    return "";
}
