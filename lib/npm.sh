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

URI_ENCODE() {
    curl -Gso /dev/null \
        -w '%{url_effective}' \
        --data-urlencode @- '' <<< "$1" | \
    cut -c 3-
}

ARG="$(URI_ENCODE "$4")"
ARG="${ARG%\%0A}"
NPM="https://www.npmjs.com/-/search?text=${ARG}&from=0&size=3"
 
while read -r name link desc; do
    if [ -n "$desc" ]; then
        desc=" $desc ::"
    fi 
    echo -e ":m $1 \002${name}\002 ::$desc $link"
done < <(
    curl "$NPM" -f 2>/dev/null |
    jq -r '.objects[0].package,.objects[1].package,.objects[2].package // empty | .name + " " + .links.npm + " " + .description'
)
