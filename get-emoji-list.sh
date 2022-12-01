#!/bin/sh

# provide a filename that already has the emoji list
test -z "$CACHED_LIST" && CACHED_LIST=0

HOW_TO_TOKEN="
http://app.slack.com 
console tab
localStorage
localConfig_v2
teams[id].token
"
TOKEN="${TOKEN:-$1}"

HOW_TO_COOKIE="
app.slack.com
network tab
open any request from app.slack.com to internal api
copy the cookie
"
COOKIE="${COOKIE:-$2}"

SLEEP_BETWEEN_REQ="${SLEEP_BETWEEN_REQ:-1}"

get_emoji_list() {
	if test "$CACHED_LIST" -eq 0 2>/dev/null; then
		[ -z "$TOKEN" ] && {
			>&2 printf "\nno token. to get: $HOW_TO_TOKEN\n\n"
			exit 1
		}
		[ -z "$COOKIE" ] && {
			>&2 printf "\nno cookie. to get: $HOW_TO_COOKIE\n\n"
			exit 1
		}

		curl "https://slack.com/api/emoji.list?token=$TOKEN" -H "Cookie: $COOKIE" > emoji.json
	else 
		test "$CACHED_LIST" != "emoji.json" && {
			cp "$CACHED_LIST" emoji.json
		}
	fi
}

get_emoji_list

# get_emoji_list | jq '.emoji'
# get_emoji_list | jq '.emoji | to_entries[] | [.key, .value] | @csv' emoji.json | cut -d, -f2
#get_emoji_list | node fetch-emoji.js

# jq '.emoji | to_entries[] | [.key, .value] | select(.[1]|test("^alias:"))' emoji.json > aliases.json
jq -r '.emoji | to_entries[] | [.key, .value] | select(.[1]|test("^alias:")) | [.[0], .[1]|ltrimstr("alias:")] | join(" ")' emoji.json > aliases.txt

#jq -r '.emoji | to_entries[] | [.key, .value, "" + .value] | select(.[1]|test("^alias:")|not) | [.[0], .[1], (.[2]+"X")|split(".")[-1]] | join(" ")' emoji.json > urls.txt
jq -r '.emoji | to_entries[] | [.key, .value] | select(.[1]|test("^alias:")|not) | join(" ")' emoji.json > urls.txt

get_extension() {
	printf "${1##*.}"
}

cat urls.txt | while read line; do 
	name="$(printf "$line" | cut -d' ' -f1)"
	url="$(printf "$line" | cut -d' ' -f2)"
	ext="$(get_extension "$line")"
	fullname="$name.$ext"

	echo "name $fullname url $url"
	2>errors curl -L -s -S "$url" > "$fullname"

	sleep "$SLEEP_BETWEEN_REQ"
done

