#!/bin/bash

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set -x

mkdir -p "$folder"/webpages

mlr --j2t cat "$folder"/config.json | tail -n +2 >"$folder"/config.tsv

while IFS=$'\t' read -r cf categoria urlToClean tidy scrape xpath; do
  if [ "$tidy" = 1 ] && [ "$scrape" = 1 ]; then
    curl --max-time 60 -k -sL "$urlToClean" -D "$folder"/webpages/"$cf"_code -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36" -H "Sec-Fetch-User: ?1" --compressed |
      tidy -q --show-warnings no --drop-proprietary-attributes y --show-errors 0 --force-output y |
      scrape -be ''"$xpath"'' >"$folder"/webpages/"$cf".html
  else
    curl --max-time 60 -k -sL "$urlToClean" -o "$folder"/webpages/"$cf".html -D "$folder"/webpages/"$cf"_code -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36" -H "Sec-Fetch-User: ?1" --compressed
  fi
done <"$folder"/config.tsv


. ~/.keychain/$HOSTNAME-sh

cd "$folder"/..
git -C "$folder"/.. add .
git -C "$folder"/.. commit -am "update"
git -C "$folder"/.. push origin master
