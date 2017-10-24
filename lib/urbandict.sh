#!/usr/bin/env bash
# Copyright 2017 prussian <genunrest@gmail.com>
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
# DEPENDS: recode

declare -i COUNT
COUNT=3

# parse args
q="$4"
for key in $4; do
    case "$key" in
        -c|--count)
            LAST='c'
        ;;
        --count=*)
            [[ "${key#*=}" =~ ^[1-3]$ ]] &&
                COUNT="${key#*=}"
        ;;
        -d|--definition)
            LAST='d'
        ;;
        --definition=*)
            [[ "${key#*=}" =~ ^(1[0-9]|[1-9])$ ]] &&
                DEFINITION="${key#*=}"
        ;;
        -h|--help)
            echo ":m $1 usage: $5 [--count=#-to-ret|--definition=#] query"
            echo ":m $1 find a defintion for a word using the urban dictionary."
            exit 0
        ;;
        *)
            [ -z "$LAST" ] && break
            if [ "$LAST" = 'd' ]; then
                declare -i DEFINITION
                [[ "$key" =~ ^(1[0-9]|[1-9])$ ]] &&
                    DEFINITION="$key"
            else
                [[ "$key" =~ ^[1-3]$ ]] &&
                    COUNT="$key"
            fi
            LAST=
        ;;
    esac
    if [[ "$q" == "${q#* }" ]]; then
        q=
        break
    else
        q="${q#* }"
    fi
done

if [ -z "$4" ]; then
    echo ":mn $3 This command requires a search query"
    exit 0
fi

# kept for advert
URBAN="http://www.urbandictionary.com/define.php?term=$(URI_ENCODE "$q")"
NEW_URBAN="http://api.urbandictionary.com/v0/define?term=$(URI_ENCODE "$q")"

declare -i DEF_NUM
DEF_NUM=0

if [ -n "$DEFINITION" ]; then
    while read -r definition; do
        DEF_NUM+=1
        (( ${#definition} > 400 )) && 
            definition="${definition:0:400}..."
        echo -e ":m $1 "$'\002'"${q}\002 :: $definition"
    done < <(
        curl "$NEW_URBAN" -L -f 2>/dev/null \
        | jq -r '.list['"$(( DEFINITION - 1 ))"'] //empty
            | .definition
            | sub("\r|\n"; " "; "g")
            | sub("  +"; " "; "g") 
        '
    )
else
    while read -r definition; do
        DEF_NUM+=1
        (( ${#definition} > 400 )) && 
            definition="${definition:0:400}..."
        echo -e ":m $1 "$'\002'"${q}\002 :: $definition"
        (( DEF_NUM >= COUNT )) && break
    done < <(
      curl "$NEW_URBAN" -L -f 2>/dev/null \
      | jq -r '.list[0],.list[1],.list[2] //empty 
            | .definition
            | sub("\r|\n"; " "; "g")
            | sub("  +"; " "; "g")
        '
    )
fi

if (( DEF_NUM > 0 )); then
    echo ":mn $3 See More: $URBAN"
else
    echo ":m $1 No definitions found"
fi
