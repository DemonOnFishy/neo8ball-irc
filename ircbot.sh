#! /usr/bin/env bash
# Copyright 2016 prussian <generalunrest@airmail.cc>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
VERSION="bash-ircbot: v1.3.0-RC2"

usage() {
    echo "usage: $0 [-c config]"
    echo "       -c --config - a config file"
    echo ""
    echo "by default, if empty, the script assumes all the information can be found in the same directory as the script"
    exit 1
}

die() {
    echo "$1" >&2
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        -c|--config)
            CONFIG_PATH="$2"
            shift
        ;;
        -h|--help)
            usage
        ;;
    esac
    shift
done

if [ -z "$CONFIG_PATH" ]; then
    CONFIG_PATH="$(dirname "$0")/config.sh"
fi

if [ -f "$CONFIG_PATH" ]; then
    . "$CONFIG_PATH"
else
    echo "NO CONFIG FILE FOUND"
    usage
fi

[ -d "$temp_dir/bash-ircbot" ] && rm -r "$temp_dir/bash-ircbot"
infile="$temp_dir/bash-ircbot/in"
outfile="$temp_dir/bash-ircbot/out"
mkdir "$temp_dir/bash-ircbot" || \
    die "failed to make temp directory, check your config"
mkfifo "$infile" || \
    die "couldn't make named pipe"
mkfifo "$outfile" || \
    die "couldn't make named pipe"

quit_prg() {
    pkill -P $$
    exec 3>&-
    exec 4>&-
    rm -rf "$temp_dir/bash-ircbot"
    exit 0
}
trap 'quit_prg' SIGINT SIGTERM

# helper for channel config reload
# determine if chan is in channel list
contains_chan() {
  for chan in "${@:2}"; do 
      [ "$chan" = "$1" ] && return 0
  done
  return 1
}

reload_config() {
    local _NICK="$NICK"
    local _NICKSERV="$NICKSERV"
    local _CHANNELS=("${CHANNELS[@]}")
    . "$CONFIG_PATH"
    # NICK changed
    if [ "$NICK" != "$_NICK" ]; then
        send_msg "NICK $NICK"
    fi
    # pass change for nickserv
    if [ "$NICKSERV" != "$_NICKSERV" ]; then
        printf "%s\r\n" "PRIVMSG NickServ :IDENTIFY $NICKSERV" >&3
    fi
    
    # join or part channels based on new channel list
    uniq_chan_list="$(printf '%s\n' "${_CHANNELS[@]}" "${CHANNELS[@]}" | sort | uniq -u)"
    for uniq_chan in $uniq_chan_list; do
        if contains_chan "$uniq_chan" "${_CHANNELS[@]}"; then
            send_cmd <<< ":l $uniq_chan"
        else
            send_cmd <<< ":j $uniq_chan"
        fi
    done
}
trap 'reload_config' SIGHUP SIGWINCH

if [ -z "$(which ncat 2>/dev/null)" ]; then
    echo "WARN: ncat not found, TLS will not be enabled" >&2
    BASH_TCP=a
fi

if [ -z "$NICK" ]; then
    echo "Nick was not specified" >&2
    usage
fi

# Connect to server
[ -n "$TLS" ] && TLS="--ssl"
if [ -z "$BASH_TCP" ]; then
    exec 3<> "$infile" || \
        die "unknown failure mapping named pipe to fd"
    exec 4<> "$outfile" || \
        die "unknown failure mapping named pipe to fd"
    ( ncat $SERVER $PORT $TLS <&3 >&4
      kill -TERM $$ ) &
else
    infile="/dev/tcp/${SERVER}/${PORT}"
    exec 3<> "$infile" || \
        die "Cannot connect to $SERVER on port $PORT"
    exec 4<&3 || \
        die "unknown failure mapping named pipe to fd"
fi

# any literal argument/s will be sent
send_msg() {
    printf "%s\r\n" "$*" >&3
    [ -n "$LOG_INFO" ] && \
        echo "*** SENT *** $*"
}

send_cmd() {
    while read -r cmd arg other; do

        case $cmd in
            :j|:join)
                send_msg "JOIN $arg"
                ;;
            :l|:leave)
                send_msg "PART $arg :$other"
                ;;
            :m|:message)
                send_msg "PRIVMSG $arg :$other"
                ;;
            :mn|:notice)
                send_msg "NOTICE $arg :$other"
                ;;
            :n|:nick)
                send_msg "NICK $arg"
                ;;
            :q|:quit)
                send_msg "QUIT :$arg $other"
                kill -TERM $$
                ;;
            :r|:raw)
                send_msg "$arg $other"
                ;;
            :li|:log)
                [ -n "$LOG_INFO" ] && \
                    echo "*** INFO *** $arg $other"
                ;;
            *)
                ;;
        esac
    done
}

# $1: channel
# $2: datetime
# $3: user
# $4: msg
handle_privmsg() {
    # private message to us
    if [ "$NICK" = "$1" ]; then
        # most servers require this "in spirit"
        # tell them what we are
        if [ "$message" = $'\001VERSION\001' ]; then
            echo -e ":mn $3 \001VERSION $VERSION\001"
            return
        fi

        [ -x "$LIB_PATH/$PRIVATE" ] || return
        $LIB_PATH/$PRIVATE \
            "$3" "$2" "$3" "$4" "$LIB_PATH"
        echo ":li PRIV_MSG EVENT -> $3 <$3> $4"
        return
    fi

    # highlight event in message
    local highlight="$NICK.? (.*)"
    if [[ "$4" =~ $highlight ]]; then
        [ -x "$LIB_PATH/$HIGHLIGHT" ] || return
        $LIB_PATH/$HIGHLIGHT \
            "$1" "$2" "$3" "${BASH_REMATCH[1]}" "$LIB_PATH"
        echo ":li HIGHLIGHT EVENT -> $1 <$3> $4"
        return
    fi

    read -r cmd args <<< "$4"
    local reg="^[${CMD_PREFIX}]${cmd:1}"
    if [[ "$cmd" =~ $reg ]]; then
        cmd="${cmd:1}"
        [ -n "${COMMANDS[$cmd]}" ] || return
        [ -x "$LIB_PATH/${COMMANDS[$cmd]}" ] || return
        $LIB_PATH/${COMMANDS[$cmd]} \
            "$1" "$2" "$3" "$args" "$cmd"
        echo ":li COMMAND EVENT -> $cmd: $1 <$3> $args"
    fi

    # fallback regex check on message
    for reg in "${!REGEX[@]}"; do
        if [[ "$4" =~ $reg ]]; then
            [ -x "$LIB_PATH/${REGEX[$reg]}" ] || return
            $LIB_PATH/${REGEX[$reg]} \
                "$1" "$2" "$3" "$4" "${BASH_REMATCH[0]}"
            echo ":li REGEX EVENT -> $reg: $1 <$3> $4"
            return
        fi
    done
}

post_ident() {
    # join chans
    local CHANNELS_=$(printf ",%s" "${CHANNELS[@]}")
    CHANNELS=()
    send_cmd <<< ":j ${CHANNELS_:1}"
    # ident with nickserv
    if [ -n "$NICKSERV" ]; then
        # bypass logged send_cmd/send_msg
        printf "%s\r\n" "PRIVMSG NickServ :IDENTIFY $NICKSERV" >&3
    fi
}

# start communication
if [ -n "$PASS" ]; then
    send_msg "PASS $PASS"
fi
send_msg "NICK $NICK"
send_msg "USER $NICK +i * :$NICK"
# message handler loop
while read -r user command channel message; do
    user=$(sed 's/^:\([^!]*\).*/\1/' <<< "$user")
    datetime=$(date +"%Y-%m-%d %H:%M:%S")
    message=${message:1}
    message=${message%$'\r'}
    # if ping request
    if [ "$user" = "PING" ]; then
        # unless you like seing *** SENT *** PONG :blah in the log
        printf "%s\r\n" "PONG $command" >&3
        continue
    fi

    [ -n "$LOG_STDOUT" ] && \
        echo "$channel $datetime $command <$user> $message"

    case $command in
        PRIVMSG)
            handle_privmsg "$channel" "$datetime" "$user" "$message" | send_cmd
        ;;
        NOTICE)
            [ -z "$READ_NOTICE" ] || \
            handle_privmsg "$channel" "$datetime" "$user" "$message" | send_cmd
        ;;
        JOIN)
            if [ "$user" = "$NICK" ]; then
                channel="${channel:1}"
                channel="${channel%$'\r'}"
                CHANNELS+=("$channel")
                [ -n "$LOG_INFO" ] && \
                    echo "*** JOIN *** $channel"
            fi

        ;;
        PART)
            if [ "$user" = "$NICK" ]; then
                for i in "${!CHANNELS[@]}"; do
                    if [ "${CHANNELS[$i]}" = "$channel" ]; then
                        unset CHANNELS["$i"]
                    fi
                done
                [ -n "$LOG_INFO" ] && \
                    echo "*** PART *** $channel"
            fi
        ;;
        004)
            # this should only happen once?
            post_ident
        ;;
        464)
            die '*** NOTICE *** INVALID PASSWORD'
        ;;
        465)
            die '*** NOTICE *** YOU ARE BANNED'
        ;;
        433)
            NICK="${NICK}_"
            send_msg "NICK $NICK"
            [ -n "$LOG_INFO" ] && \
                echo "*** INFO *** NICK CHANGED TO $NICK"
        ;;
    esac
done <&4
