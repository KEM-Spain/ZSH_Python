#!/opt/youtube-search-python/.venv/bin/python
import sys
import os

# Add the root directory of the isolated package to Python's search path
OPT_DIR = "/opt/youtube-search-python"
if OPT_DIR not in sys.path:
    sys.path.insert(0, OPT_DIR)

import argparse
import re
from youtubesearchpython import VideosSearch

def main():
    parser = argparse.ArgumentParser(description="Search YouTube")
    parser.add_argument("searchterm", help="youtube search term")
    parser.add_argument("-s", "--strict", action="store_true", help="author must match searchterm")
    parser.add_argument("-a", "--age", default="all", help="all recent min hour day week mon year")

    args = parser.parse_args()

    searchterm = args.searchterm
    age = args.age
    strict = args.strict

    # Perform search and slice the first 50 results
    search = VideosSearch(searchterm, limit=50)
    results = search.result().get("result", [])

    # Regex for "recent" matching both short (5m, 2h) and long (5 minutes ago, 2 hours ago) formats
    recent_pattern = re.compile(r"(?:Streamed\s+)?(?:[0-9]+\s*(?:m|h|minute|hour|day)s?\s*ago|[0-9]+[hdm]\b)", re.IGNORECASE)

    # Pre-check if any video matches the age filter across the results
    age_matched = False
    if age == "all":
        age_matched = True
    elif age == "recent":
        for v in results:
            v_ago = v.get("publishedTime") or v.get("ago", "")
            if recent_pattern.search(v_ago):
                age_matched = True
                break
    else:
        for v in results:
            v_ago = v.get("publishedTime") or v.get("ago", "")
            if age in v_ago:
                age_matched = True
                break

    # Print info messages once at the top of the listing
    if strict:
        print("strict filter active")

    if age == "all":
        print("match on age:all")
    elif age == "recent":
        if age_matched:
            print("matched on age:recent")
        else:
            print("no match on age:recent")
    else:
        if age_matched:
            print(f"matched on age:{age}")
        else:
            print(f"no match on age:{age}")

    for v in results:
        has_match = False

        # Extract fields safely from the dictionary returned by youtube-search-python
        v_ago = v.get("publishedTime") or v.get("ago", "")
        v_title = v.get("title", "")

        channel_info = v.get("channel", {})
        if isinstance(channel_info, dict):
            v_author_name = channel_info.get("name", "")
        else:
            v_author_name = str(channel_info)

        v_url = v.get("link", "")
        v_timestamp = v.get("duration", "")

        # Age filtering logic
        if age == "all":
            has_match = True
        elif age == "recent":
            if recent_pattern.search(v_ago):
                has_match = True
        else:
            if age in v_ago:
                has_match = True

        # Clean up pipe delimiters in title and author name
        v_title = v_title.replace("|", ":")
        v_author_name = v_author_name.replace("|", "")

        if has_match:
            if strict:
                t_arg = searchterm.lower().replace(" ", "")
                v_arg = v_author_name.lower().replace(" ", "")
                if t_arg not in v_arg:
                    continue

            print(f"{v_ago}|{v_author_name}|{v_title}|{v_url}|{v_timestamp}")

if __name__ == "__main__":
    main()
