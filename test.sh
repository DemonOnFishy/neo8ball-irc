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

# if being sourced, act as config file. lol
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    NICK=testnick
    NICKSERV=testpass
    SERVER="irc.rizon.net"
    CHANNELS=("#chan1" "#chan2")
    PORT="6697"
    TLS=yes
    temp_dir=/tmp
    READ_NOTICE=
    LOG_LEVEL=1
    LOG_STDOUT=
    LIB_PATH="$(dirname "$0")/lib/"
    HIGHLIGHT="8ball.sh"
    PRIVMSG_DEFAULT_CMD='help'
    CMD_PREFIX=".,!"
    declare -gA COMMANDS
    COMMANDS=(
    ["8"]="8ball.sh" 
    ["8ball"]="8ball.sh" 
    ["define"]="define.sh"
    ["decide"]="8ball.sh" 
    ["duck"]="search.sh" 
    ["ddg"]="search.sh" 
    ["g"]="search.sh"
    ["help"]="help.sh"
    ["bots"]="bots.sh"
    ["source"]="bots.sh"
    ["v"]="vidme.sh"
    ["vid"]="vidme.sh"
    ["vidme"]="vidme.sh"
    #["w"]="weather.sh"
    ["owm"]="weather.sh"
    ["weather"]="weather.sh"
    ["wd"]="weatherdb.sh"
    ["location"]="weatherdb.sh"
    ["nws"]="nws.sh"
    ["nwsl"]="weatherdb.sh"
    ["nwsd"]="weatherdb.sh"
    ["npm"]="npm.sh"
    ["wiki"]="wikipedia.sh"
    ["reddit"]="subreddit.sh"
    ["sub"]="subreddit.sh"
    ["yt"]="youtube.sh"
    ["you"]="youtube.sh"
    ["youtube"]="youtube.sh"
    ["u"]="urbandict.sh"
    ["urban"]="urbandict.sh"
    ["bible"]="bible.sh"
    ["quran"]="bible.sh"
    ["fap"]="fap.sh"
    ["gay"]="fap.sh"
    ["straight"]="fap.sh"
    )
    REGEX=(
    'youtube.com|youtu.be' 'youtube.sh'
    '(https?)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]' 'pagetitle.sh'
    )
    IGNORE=(
    )
    ANTISPAM=yes
    ANTISPAM_TIMEOUT=30
    ANTISPAM_COUNT=3
    HALFCLOSE_CHECK=3
    export OWM_KEY="your owm key"
    export PERSIST_LOC="/tmp"
    export YOUTUBE_KEY="your youtube api key"
    export BIBLE_SOURCE="$(dirname "$0")/static/king-james.txt"
    export QURAN_SORUCE="$(dirname "$0")/static/quran-allah-ver.txt"
    URI_ENCODE() {
        curl -Gso /dev/null \
            -w '%{url_effective}' \
            --data-urlencode @- '' <<< "$1" |
        cut -c 3- |
        sed 's/%0A$//g'
    }
    export -f URI_ENCODE
    MOCK_CONN_TEST=yes
    return
fi

IFS+=$'\r' # remove carriage returns from reads
EXIT_CODE=0
RESTORE=$'\033[0m'
FAIL='['$'\033[00;31m'"FAIL${RESTORE}]"
PASS='['$'\033[00;32m'"PASS${RESTORE}]"

fail() {
    echo "$FAIL $*"
    EXIT_CODE=1
}

pass() {
    echo "$PASS $*"
}

cleanup() {
    echo 'ERROR :done testing' >&3
    rm ._TEST_IN ._TEST_OUT
    if kill "$TEST_PROC" 2>/dev/null; then
        fail 'ERROR COMMAND'
    else
        pass 'ERROR COMMAND'
    fi
    exit "$EXIT_CODE"
}
trap 'cleanup' SIGINT SIGTERM

# IPC
mkfifo ._TEST_IN
exec 3<> ._TEST_IN
mkfifo ._TEST_OUT
exec 4<> ._TEST_OUT

./ircbot.sh -c "$0" <&3 >&4 2>debug.log &
TEST_PROC=$!

# test nick cmd
read -u 4 -r cmd nick
if [ "$cmd" = 'NICK' ] && [ "$nick" = 'testnick' ]; then
    pass 'NICK COMMAND'
else
    fail 'NICK COMMAND'
fi

# test user cmd
read -u 4 -r cmd user mode unused realname
if  [ "$cmd" = 'USER' ] &&
    [ "$user" = 'testnick' ] &&
    [ "$mode" = '+i' ] &&
    [ "$realname" = ':testnick' ] 
then
    pass 'USER COMMAND'
else
    fail 'USER COMMAND'
fi

# send PING 
echo 'PING :hello' >&3
read -u 4 -r pong string
if [ "$pong" = 'PONG' ] && [ "$string" = ':hello' ]; then
    pass 'PING/PONG COMMAND'
else
    fail 'PING/PONG COMMAND'
fi

# send post ident
echo ':doesnt@matter@user.host 004 doesntmatter :reg' >&3
read -u 4 -r join chanstring
if  [ "$join" = 'JOIN' ] &&
    [ "$chanstring" = '#chan1,#chan2' ]
then
    pass 'post_ident function'
else
    fail 'post_ident function'
fi
# test that the bot attempted to identify for its nick
read -u 4 -r cmd ident pass
if [ "$cmd" = 'NICKSERV' ] &&
   [ "$ident" = 'IDENTIFY' ] &&
   [ "$pass" = 'testpass' ]; then
    pass 'nickserv identify'
else
    fail 'nickserv identify'
fi

# test nick change feature p.1
# initial nick test
echo ':testbot __DEBUG neo8ball :nickname' >&3
read -u 4 -r nick
if [ "$nick" = 'testnick' ]; then
    pass "nick variable 1"
else
    fail "nick variable 1"
fi

# notify the user the nick is in use
echo ':testbot 433 neo8ball :name in use' >&3
read -u 4 -r cmd nick
if [ "$cmd" = 'NICK' ] && [ "$nick" = 'testnick_' ]; then
    pass '433 COMMAND (nick conflict)'
else
    fail '433 COMMAND (nick conflict)'
fi

# verify nick variable is what it reported
echo ':testbot __DEBUG neo8ball :nickname' >&3
read -u 4 -r nick
if [ "$nick" = 'testnick_' ]; then
    pass "nick variable 1"
else
    fail "nick variable 1"
fi

# channel joining
echo ':testnick_!blah@blah JOIN :#chan1 ' >&3
echo ':testnick_!blah@blah JOIN :#chan2 ' >&3
echo ':testbot __DEBUG neo8ball :channels' >&3
read -u 4 -r channel
if [ "$channel" = '#chan1 #chan2' ]; then
    pass "JOIN test"
else
    fail 'JOIN test'
fi

# channel PART test
echo ':testnick_!blah@blah PART #chan2 :bye' >&3
echo ':testbot __DEBUG neo8ball :channels' >&3
read -u 4 -r channel
if [ "$channel" = '#chan1' ]; then
    pass "JOIN test"
else
    fail 'JOIN test'
fi

# channel KICK test
echo ':testserv KICK #chan1 testnick_ :test message' >&3
echo ':testbot __DEBUG neo8ball :channels' >&3
read -u 4 -r channel
if [ "$channel" = '' ]; then
    pass 'KICK test'
else
    fail 'KICK test'
fi

cleanup
