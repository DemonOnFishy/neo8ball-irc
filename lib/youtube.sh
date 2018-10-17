#!/usr/bin/env bash
# Copyright 2017 Anthony DeDominic <adedomin@gmail.com>, underdoge <eduardo.chapa@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

declare -i COUNT
COUNT=1

MATCH="$4"
# parse args
for key in $4; do
    case "$key" in
        -c|--count)
            LAST='c'
        ;;
        --count=*)
            [[ "${key#*=}" =~ ^[1-3]$ ]] &&
                COUNT="${key#*=}"
        ;;
        -h|--help)
            echo ":m $1 usage: $5 [--count=#-to-ret] query"
            echo ":m $1 search for a youtube video."
            exit 0
        ;;
        *)
            [[ -z "$LAST" ]] && break
            LAST=
            [[ "$key" =~ ^[1-3]$ ]] &&
                COUNT="$key"
        ;;
    esac
    if [[ "$MATCH" == "${MATCH#* }" ]]; then
        MATCH=
        break
    else
        MATCH="${MATCH#* }"
    fi
done

if [[ -z "$MATCH" ]]; then
    echo ":mn $3 This command requires a search query"
    exit 0
fi

if [[ -z "$YOUTUBE_KEY" ]]; then
    echo ":mn $3 this command is disabled; no api key"
    exit 0
fi

if [ -n "$6" ]; then
    COUNT=1
    ids="$(grep -Po '(?<=watch\?v=)[^&?\s]*|(?<=youtu\.be/)[^?&\s]*' <<< "$MATCH")"
else
    youtube="https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&q=$(URI_ENCODE "$MATCH")&maxResults=${COUNT}&key=${YOUTUBE_KEY}"
    while read -r id; do
        if [ -z "$ids" ]; then
            ids=$id
        else
            ids=$ids,$id
        fi

    done < <(
        curl "${youtube}" -f 2>/dev/null |
        jq -r '.items[0],.items[1],.items[2] //empty |
               .id.videoId'
    )
fi

[[ -z "$ids" ]] && exit 0

stats="https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics,contentDetails&id=${ids}&key=${YOUTUBE_KEY}"

while read -r id2 likes dislikes views duration published title; do
    [[ -z "$title" ]] && exit 0
    duration="${duration:2}"
    echo -e ":m $1" \
        $'\002'"${title}\\002 (${duration,,}) "$'\003'"09::\\003 https://youtu.be/${id2} "$'\003'"09::\\003" \
        $'\003'"03\\u25B2 $(numfmt --grouping "$likes")\\003 "$'\003'"09::\\003" \
        $'\003'"04\\u25BC $(numfmt --grouping "$dislikes")\\003 "$'\003'"09::\\003" \
        "\\002Views\\002 $(numfmt --grouping "$views") ::" \
        "\\002Created\\002 ${published%%T*}"
done < <(
    curl "${stats}" 2>/dev/null |
    jq -r '.items[0],.items[1],.items[2] //empty |
        .id + " " +
        .statistics.likeCount + " " +
        .statistics.dislikeCount + " " +
        .statistics.viewCount + " " +
        .contentDetails.duration + " " +
        .snippet.publishedAt + " " +
        .snippet.title'
)
