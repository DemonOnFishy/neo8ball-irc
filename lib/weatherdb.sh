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

# format -> username:their weather location

if [ -z "$WEATHER_DB" ]; then
    echo ":mn $3 This feature is not enabled"
    exit 0
fi

if [ ! -f "$WEATHER_DB" ]; then
    touch "$WEATHER_DB"
fi

if [ -z "$4" ]; then
    sed -i '' '/^'"$3"':/d' "$WEATHER_DB"
    echo ":mn $3 Your defaults were deleted"
elif grep -q "^$3:" "$WEATHER_DB"; then
    sed -i '' 's/^'"$3"':.*$/'"$3"':'"$4"'/' "$WEATHER_DB"
    echo ":mn $3 Your default has changed"
else
    echo "$3:$4" >> "$WEATHER_DB"
    echo ":mn $3 You can now use the weather command without arguments"
fi
