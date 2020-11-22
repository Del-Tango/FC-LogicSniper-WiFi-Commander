#!/bin/bash
#
# Regards, the Alveare Solutions society.
#

function done_msg () {
    local MSG="$@"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ ${BLUE}DONE${RESET} ]: $MSG"
    return 0
}

function ok_msg () {
    MSG="$@"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ ${GREEN}OK${RESET} ]: $MSG"
    return 0
}

function nok_msg () {
    MSG="$@"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ ${RED}NOK${RESET} ]: $MSG"
    return 0
}

function qa_msg () {
    MSG="$@"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ ${YELLOW}Q/A${RESET} ]: $MSG"
    return 0
}

function info_msg () {
    MSG="$@"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ ${YELLOW}INFO${RESET} ]: $MSG"
    return 0
}

function error_msg () {
    MSG="$@"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ ${RED}ERROR${RESET} ]: $MSG"
    return 0
}

function warning_msg () {
    MSG="$@"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ ${RED}WARNING${RESET} ]: $MSG"
    return 0
}

function symbol_msg () {
    SYMBOL="$1"
    MSG="${@:2}"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ $SYMBOL ]: $MSG"
    return 0
}

