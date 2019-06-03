import std.stdio;
import std.getopt;
import std.json;
import std.format;
import std.net.curl;
import std.exception;
import std.regex;
import std.algorithm;
import std.string;

import backend.arch;
import backend.github_releases;
import backend.github_tags;
import resolver;

enum string VERSION = "0.0.1";

int main(string[] args)
{
    string[] visited_sections = [];

    string config;
    string[] packages;
    string target;
    bool prerelease;
    bool verbosity;
    bool show_version;

    string[string] prettyname = [
        "arch":             "Archlinux",
        "github":           "Github Releases",
        "github-releases":  "Github Releases",
        "github-tags":      "Github Tags",
        "git":              "Git Tag"
    ];

    bool help = args.length == 1;

    auto helpInformation = getopt(
        args, std.getopt.config.bundling,
        "config|c",     "Config file",                                  &config,
        "target|t",     "Target version resolver to compare against",   &target,
        "package|p",    "Check specific package (stackable)",           &packages,
        "prerelease|r", "Accept prereleases (default = false)",         &prerelease,
        "verbose|d",    "Verbose (default = info)",                     &verbosity,
        "version|v",    "Version",                                      &show_version
    );

    if(helpInformation.helpWanted || help)
    {
        defaultGetoptPrinter(format!"Usage: %s (options)\n\nOptions:"(args[0]), helpInformation.options);
        return 0;
    }

    if(show_version)
    {
        writefln("VersionCheck %s", VERSION);
        return 0;
    }

    string[string] versions;

    auto lines = File(config).byLine.map!strip;
    foreach(ln; lines)
    {
        /* writeln(ln); */

        /* sections (package names) */
        auto section = matchFirst(ln, r"\[.*\]".regex);

        if(!section.empty && !visited_sections.canFind(section.hit))
        {
            if(!visited_sections.empty)
                printVersions(versions, target, visited_sections[$ - 1], prettyname);

            foreach(key, value; versions)
                versions[key] = "";

            /* visited_sections[$ - 1] gives active section */
            visited_sections ~= cast(string) replaceAll(section.hit, r"[\[\]]".regex, "");
        }

        /* keys (config) */
        if(matchFirst(ln, r".*=.*".regex))
        {
            auto vals = ln.split("=");

            if(vals.length < 2)
                continue;

            JSONValue j;
            switch(vals[0])
            {
                case "arch":
                    versions["arch"] = getArchVersion(cast(string) vals[1]);
                    break;

                case "github":
                case "github-releases":
                    versions["github-releases"] = getGithubReleasesVersion(cast(string) vals[1]);
                    break;

                case "github-tags":
                    versions["github-tags"] = getGithubTagsVersion(cast(string) vals[1]);
                    break;

                case "git":
                    break;

                default:
                    continue;
            }
        }

    }

    /* we usually trigger when we start reading a new section, we need to
       manually trigger printVersion for the last package */
    printVersions(versions, target, visited_sections[$ - 1], prettyname);

    return 0;
}
