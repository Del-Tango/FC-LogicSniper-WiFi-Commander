#!/bin/bash
#
# Regards, the Alveare Solutions society.
#

declare -A DEFAULT
declare -A AUTOMATION

CONF_FILE_PATH="$1"

if [ ! -z "$CONF_FILE_PATH" ]; then
    source $CONF_FILE_PATH
fi

if [ -f "${AUTOMATION['cli-messages']}" ]; then
    source "${AUTOMATION['cli-messages']}"
fi

# FETCHERS

function fetch_request_body_from_user () {
    local PROMPT_STRING="${1:-RequestBody}"
    while :
    do
        REQUEST_BODY=`fetch_data_from_user "$PROMPT_STRING"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        echo "$REQUEST_BODY"
        break
    done
    return 0
}

function fetch_single_port_number_from_user () {
    local PROMPT_STRING="${1:-TargetPort}"
    while :
    do
        PORT_NUMBER=`fetch_data_from_user "$PROMPT_STRING"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        CHECK_VALID=`check_value_is_number "$PORT_NUMBER"`
        if [ $? -ne 0 ]; then
            echo; warning_msg "Invalid machine port number"\
                "${RED}$PORT_NUMBER${RESET}."
            continue
        fi
        echo "$PORT_NUMBER"
        break
    done
    return 0
}

function fetch_ipv4_address_from_user () {
    local PROMPT_STRING="${1:-IPv4Address}"
    while :
    do
        IPV4_ADDRESS=`fetch_data_from_user "$PROMPT_STRING"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        CHECK_VALID=`check_is_ipv4_address "$IPV4_ADDRESS"`
        if [ $? -ne 0 ]; then
            echo; warning_msg "Invalid IPv4 address"\
                "${RED}$IPV4_ADDRESS${RESET}."
            continue
        fi
        echo "$IPV4_ADDRESS"
        break
    done
    return 0
}

function fetch_router_bssid_from_user () {
    local PROMPT_STRING="${1:-BSSID}"
    while :
    do
        BSSID=`fetch_data_from_user "$PROMPT_STRING"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        echo "$BSSID"
        break
    done
    return 0
}

function fetch_wireless_gateway_channel_from_user () {
    local PROMPT_STRING="${1:-Channel}"
    while :
    do
        CHANNEL_NUMBER=`fetch_data_from_user "$PROMPT_STRING"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        echo "$CHANNEL_NUMBER"
        break
    done
    return 0
}

function fetch_mac_address_from_user () {
    local PROMPT_STRING="${1:-MACAddress}"
    while :
    do
        MAC_ADDRESS=`fetch_data_from_user "$PROMPT_STRING"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        CHECK_VALID=`check_is_mac_address "$MAC_ADDRESS"`
        if [ $? -ne 0 ]; then
            fetch_ultimatum_from_user "Do you wish to continue? ${YELLOW}Y/N${RESET}"
            if [ $? -ne 0 ]; then
                echo; info_msg "Aborting action."
                echo; return 1
            fi
        fi
        echo "$MAC_ADDRESS"; break
    done
    return 0
}

function fetch_default_essid () {
    DETECTED_ESSID=`fetch_previously_detected_wireless_gateway_essid`
    if [ $? -ne 0 ]; then
        DETECTED_ESSID=`fetch_currently_connected_gateway_essid`
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi
    echo $DETECTED_ESSID
    return 0
}

function fetch_default_wireless_interface () {
    DETECTED_INTERFACE=`fetch_previouly_detected_wireless_interface`
    if [ $? -ne 0 ]; then
        DETECTED_INTERFACE=`fetch_wireless_interface`
        if [ $? -ne 0 ]; then
            return 1
        fi
        return 1
    fi
    echo $DETECTED_INTERFACE
    return 0
}

function fetch_default_router_bssid () {
    DETECTED_BSSID=`fetch_previously_detected_wireless_gateway_bssid`
    if [ $? -ne 0 ]; then
        DETECTED_BSSID=`fetch_wireless_gateway_bssid`
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi
    echo $DETECTED_BSSID
    return 0
}

function fetch_default_wireless_gateway_channel () {
    GATEWAY_CHANNEL=`fetch_previously_detected_wireless_gateway_channel`
    if [ $? -ne 0 ]; then
        WIRELESS_INTERFACE=`fetch_default_wireless_interface`
        if [ $? -ne 0 ]; then
            return 2
        fi
        GATEWAY_CHANNEL=`fetch_wireless_gateway_channel_by_interface \
            "$WIRELESS_INTERFACE"`
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi
    echo $GATEWAY_CHANNEL
    return 0
}

function fetch_wireless_gateway_channel_by_interface () {
    WIRELESS_INTERFACE="$1"
    RADIO_CHANNEL=`iwlist $WIRELESS_INTERFACE scan | \
        grep Channel: | \
        cut -d':' -f 2 | \
        head -n 1`
    if [ -z "$RADIO_CHANNEL" ]; then
        return 1
    fi
    echo $RADIO_CHANNEL
    return 0
}

function fetch_wireless_gateway_bssid () {
    WIRELESS_INTERFACE=`fetch_wireless_interface`
    if [ $? -ne 0 ]; then
        return 2
    fi
    ROUTER_BSSID=`iwlist "$WIRELESS_INTERFACE" scan | \
        grep 'Address' | \
        awk '{print $NF}' | \
        head -n 1`
    if [ -z "$ROUTER_BSSID" ]; then
        return 1
    fi
    echo $ROUTER_BSSID
    return 0
}

function fetch_wireless_interface () {
    WIRELESS_INTERFACE=`iwgetid | awk '{print $1}' | head -n 1`
    if [ -z "$WIRELESS_INTERFACE" ]; then
        return 1
    fi
    echo $WIRELESS_INTERFACE
    return 0
}

function fetch_wireless_interface_from_user () {
    local PROMPT_STRING="${1:-WiFiInterface}"
    while :
    do
        WIRELESS_INTERFACE=`fetch_data_from_user "$PROMPT_STRING"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        CHECK_VALID=`check_valid_wireless_interface "$WIRELESS_INTERFACE"`
        if [ $? -ne 0 ]; then
            echo; warning_msg "Invalid wireless interface"\
                "${RED}$WIRELESS_INTERFACE${RESET}."
            continue
        fi
        break
    done
    echo "$WIRELESS_INTERFACE"
    return 0
}

function fetch_previously_detected_wireless_gateway_channel () {
    if [ -z "$CONNECTION_CHANNEL" ]; then
        return 1
    fi
    echo "$CONNECTION_CHANNEL"
    return 0
}

function fetch_previously_detected_wireless_gateway_bssid () {
    if [ -z "$CONNECTION_BSSID" ]; then
        return 1
    fi
    echo "$CONNECTION_BSSID"
    return 0
}

function fetch_previously_detected_wireless_gateway_essid () {
    if [ -z "$CONNECTION_ESSID" ]; then
        return 1
    fi
    echo $CONNECTION_ESSID
    return 0
}

function fetch_previouly_detected_wireless_interface () {
    if [ -z "$WIRELESS_INTERFACE" ]; then
        return 1
    fi
    echo $WIRELESS_INTERFACE
    return 0
}

function fetch_all_wireless_interfaces () {
    WIFI_INTERFACES=( `iw dev | grep Interface | awk '{print $NF}'` )
    if [ ${#WIFI_INTERFACES[@]} -eq 0 ]; then
        return 1
    fi
    echo ${WIFI_INTERFACES[@]}
    return 0
}

function fetch_currently_connected_gateway_essid () {
    CURRENT_ESSID=`iwgetid | sed 's/\"//g' | cut -d ':' -f 2`
    if [ -z "$CURRENT_ESSID" ]; then
        return 1
    fi
    echo "$CURRENT_ESSID"
    return 0
}

function fetch_wireless_password_from_user () {
    local PROMPT_STRING="${1:-Password}"
    echo; info_msg "Type wifi ${YELLOW}Password${RESET}"\
        "or ${MAGENTA}.back${RESET}."
    while :
    do
        ESSID_PASSWORD=`fetch_data_from_user "$PROMPT_STRING" "password"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        echo "$ESSID_PASSWORD"
        break
    done
    return 0
}

function fetch_available_wireless_access_point_essid_set () {
    ESSID_SET=(
        `display_available_wireless_access_points | \
            egrep -e '[0-9]{2}/[0-9]{2}' | awk '{print $3}' | \
            sed 's/\"//g'`
    )
    if [ ${#ESSID_SET[@]} -eq 0 ]; then
        echo; warning_msg "No available wireless access points found."
        return 1
    fi
    echo ${ESSID_SET[@]}
    return 0
}

function fetch_wireless_essid_from_user () {
    AVAILABLE_ESSID=( `fetch_available_wireless_access_point_essid_set` )
    echo; TARGET_ESSID=`fetch_selection_from_user \
        "${MAGENTA}ESSID${RESET}" ${AVAILABLE_ESSID[@]}`
    if [ $? -ne 0 ]; then
        return 1
    fi
    echo "$TARGET_ESSID"
    return 0
}

function fetch_file_length () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "File ${RED}$FILE_PATH${RESET} not found."
        return 1
    fi
    cat $FILE_PATH | wc -l
    return $?
}

function fetch_data_from_user () {
    local PROMPT="$1"
    local OPTIONAL="${@:2}"
    while :
    do
        if [[ $OPTIONAL == 'password' ]]; then
            read -sp "$PROMPT: " DATA
        else
            read -p "$PROMPT> " DATA
        fi
        if [ -z "$DATA" ]; then
            continue
        elif [[ "$DATA" == ".back" ]]; then
            return 1
        fi
        echo "$DATA"; break
    done
    return 0
}

function fetch_ultimatum_from_user () {
    PROMPT="$1"
    while :
    do
        local ANSWER=`fetch_data_from_user "$PROMPT"`
        case "$ANSWER" in
            'y' | 'Y' | 'yes' | 'Yes' | 'YES')
                return 0
                ;;
            'n' | 'N' | 'no' | 'No' | 'NO')
                return 1
                ;;
            *)
        esac
    done
    return 2
}

function fetch_selection_from_user () {
    local PROMPT="$1"
    local OPTIONS=( "${@:2}" "Back" )
    local OLD_PS3=$PS3
    PS3="$PROMPT> "
    select opt in "${OPTIONS[@]}"; do
        case "$opt" in
            'Back')
                PS3="$OLD_PS3"
                return 1
                ;;
            *)
                local CHECK=`check_item_in_set "$opt" "${OPTIONS[@]}"`
                if [ $? -ne 0 ]; then
                    warning_msg "Invalid option."
                    continue
                fi
                PS3="$OLD_PS3"
                echo "$opt"
                return 0
                ;;
        esac
    done
    PS3="$OLD_PS3"
    return 1
}


function fetch_alive_lan_machines_ipv4_addresses () {
    LAN_SCAN=`lan_scan`
    IPV4_ADDRESSES=( `echo "$LAN_SCAN" | awk '{print $1}'` )
    echo ${IPV4_ADDRESSES[@]}
    return 0
}

function fetch_alive_lan_machines_mac_addresses () {
    LAN_SCAN=`lan_scan`
    MAC_ADDRESSES=( `echo "$LAN_SCAN" | awk '{print $2}'` )
    echo ${MAC_ADDRESSES[@]}
    return 0
}

# SETTERS

function set_wireless_interface () {
    local WIRELESS_INTERFACE="$1"
    check_valid_wireless_interface "$WIRELESS_INTERFACE"
    if [ $? -ne 0 ]; then
        echo; error_msg "Invalid wireless interface"\
           "${RED}$WIRELESS_INTERFACE${RESET}"
        return 1
    fi
    WIRELESS_INTERFACE=$WIRELESS_INTERFACE
    return 0
}

function set_connected_bssid () {
    local BSSID="$1"
    CONNECTED_BSSID="$BSSID"
    return 0
}

function set_connection_channel () {
    local CHANNEL_NUMBER=$1
    check_value_is_number $CHANNEL_NUMBER
    if [ $? -ne 0 ]; then
        echo; error_msg "Invalid channel number ${RED}$CHANNEL_NUMBER${RESET}."
        return 1
    fi
    CONNECTION_CHANNEL=$CHANNEL_NUMBER
    return 0
}

function set_connected_essid () {
    local ESSID="$1"
    CONNECTED_ESSID="$ESSID"
    return 0
}

function set_user_black_book_journal_file () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "File ${RED}$FILE_PATH${RESET} not found."
        return 1
    fi
    DEFAULT['black-book']="$FILE_PATH"
    return 0
}

function set_user_action_journal_file () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "File ${RED}$FILE_PATH${RESET} not found."
        return 1
    fi
    DEFAULT['action-journal']="$FILE_PATH"
    return 0
}

function set_wpa_supplicant_configuration_file () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "File ${RED}$FILE_PATH${RESET} not found."
        return 1
    fi
    WPA_SUPPLICANT_CONF_FILE="$FILE_PATH"
    return 0
}

function set_wpa_supplicant_log_file () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "File ${RED}$FILE_PATH${RESET} not found."
        return 1
    fi
    LOG_FILE_WPA_SUPPLICANT="$FILE_PATH"
    return 0
}

function set_dhcpcd_log_file () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "File ${RED}$FILE_PATH${RESET} not found."
        return 1
    fi
    LOG_FILE_DHCPCD="$FILE_PATH"
    return 0
}

function set_temporary_file () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "File ${RED}$FILE_PATH${RESET} not found."
        return 1
    fi
    DEFAULT['tmp-file']="$FILE_PATH"
    return 0
}

function set_file_editor () {
    local FILE_EDITOR="$1"
    check_util_installed "$FILE_EDITOR"
    if [ $? -ne 0 ]; then
        echo; warning_msg "Editor ${RED}$FILE_EDITOR${RESET} not installed."
        return 1
    fi
    DEFAULT['file-editor']=$FILE_EDITOR
    return 0
}

function set_remote_resource_server () {
    local REMOTE_SERVER=$1
    is_alive_ping $REMOTE_SERVER
    if [ $? -ne 0 ]; then
        echo; error_msg "Remote server ${RED}$REMOTE_SERVER${RESET} is down."
        return 1
    fi
    REMOTE_RESOURCE=$REMOTE_SERVER
    return 0
}

function set_subnet_address_prefix () {
    local SUBNET_PREFIX=$1
    check_is_subnet_address "$SUBNET_PREFIX"
    if [ $? -ne 0 ]; then
        echo; error_msg "Invalid subnet address prefix"\
            "${RED}$SUBNET_PREFIX${RESET}, expected"\
            "'<${WHITE}octet${RESET}.${WHITE}octet${RESET}.${WHITE}octet${RESET}>'."
        return 1
    fi
    SUBNET_ADDRESS=$SUBNET_PREFIX
    return 0
}

function set_address_range_end_octet () {
    local END_OCTET=$1
    check_value_is_number $END_OCTET
    if [ $? -ne 0 ]; then
        echo; error_msg "Final octet must be a number,"\
            "not ${RED}$END_OCTET${RESET}."
        return 1
    fi
    echo "$END_OCTET" | egrep -e '[0-9]{1,3}' &> /dev/null && \
        test $END_OCTET -lt 255
    if [ $? -ne 0 ]; then
        echo; error_msg "Invalid final octet number ${RED}$END_OCTET${RESET}."
        return 2
    fi
    END_ADDRESS_RANGE=$END_OCTET
    return 0
}

function set_address_range_start_octet () {
    local START_OCTET=$1
    check_value_is_number $START_OCTET
    if [ $? -ne 0 ]; then
        echo; error_msg "Beginning octet must be a number,"\
            "not ${RED}$START_OCTET${RESET}."
        return 1
    fi
    echo "$START_OCTET" | egrep -e '[0-9]{1,3}' &> /dev/null && \
        test $START_OCTET -lt 255
    if [ $? -ne 0 ]; then
        echo; error_msg "Invalid beginning octet number ${RED}$START_OCTET${RESET}."
        return 2
    fi
    START_ADDRESS_RANGE=$START_OCTET
    return 0
}

function set_logic_sniper_safety () {
    local SAFETY="$1"
    if [[ "$SAFETY" != 'on' ]] && [[ "$SAFETY" != 'off' ]]; then
        echo; error_msg "Invalid safety value ${RED}$SAFETY${RESET}."\
            "Defaulting to ${GREEN}ON${RESET}."
        LOGIC_SNIPER_SAFETY='on'
        return 1
    fi
    LOGIC_SNIPER_SAFETY=$SAFETY
    return 0
}

# CHECKERS

function check_valid_wireless_interface () {
    local WIRELESS_INTERFACE="$1"
    WIFI_INTERFACES=( `fetch_all_wireless_interfaces` )
    check_item_in_set "$WIRELESS_INTERFACE" ${WIFI_INTERFACES[@]}
    if [ $? -ne 0 ]; then
        return 1
    fi
    return 0
}

function check_essid_password_protected () {
    local TARGET_ESSID="$1"
    for count in `seq 3`; do
        ENCODED=`display_available_wireless_access_points | \
            grep "$TARGET_ESSID" | \
            awk '{print $2}'`
        case $ENCODED in
            'on')
                echo; info_msg "Wireless access point"\
                    "${YELLOW}$TARGET_ESSID${RESET}"\
                    "${GREEN}is password protected${RESET}."
                return 0
                ;;
            'off')
                echo; info_msg "Wireless access point"\
                    "${YELLOW}$TARGET_ESSID${RESET}"\
                    "${RED}is not password protected${RESET}."
                return 1
                ;;
            *)
                echo; warning_msg "Could not determine if"\
                    "${YELLOW}ESSID${RESET} ${RED}$TARGET_ESSID${RESET}"\
                    "is password protected on try number"\
                    "${WHITE}$count${RESET}."
                ;;
        esac
    done
    error_msg "Something went wrong."\
        "Could not detemine if ${YELLOW}ESSID${RESET}"\
        "${RED}$TARGET_ESSID${RESET} is password protected."
    return 2
}

function check_util_installed () {
    local UTIL_NAME="$1"
    type "$UTIL_NAME" &> /dev/null && return 0 || return 1
}

function check_safety_on () {
    if [[ "$LOGIC_SNIPER_SAFETY" == 'on' ]]; then
        return 0
    fi
    return 1
}

function check_safety_off () {
    if [[ "$LOGIC_SNIPER_SAFETY" == 'off' ]]; then
        return 0
    fi
    return 1
}

function check_file_has_number_of_lines () {
    local FILE_PATH="$1"
    local LINE_COUNT=$2
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "File ${RED}$FILE_PATH${RESET} not found."
        echo; return 2
    fi
    check_value_is_number $LINE_COUNT
    if [ $? -ne 0 ]; then
        echo; warning_msg "Line count must be a number, not ${RED}$LINE_COUNT${RESET}."
        echo; return 3
    fi
    if [ `cat $FILE_PATH | wc -l` -eq $LINE_COUNT ]; then
        return 0
    fi
    return 1
}

function check_value_is_number () {
    local VALUE=$1
    test $VALUE -eq $VALUE &> /dev/null
    if [ $? -ne 0 ]; then
        return 1
    fi
    return 0
}

function check_item_in_set () {
    local ITEM="$1"
    ITEM_SET=( "${@:2}" )
    for SET_ITEM in "${ITEM_SET[@]}"; do
        if [[ "$ITEM" == "$SET_ITEM" ]]; then
            return 0
        fi
    done
    return 1
}

function check_file_empty () {
    local FILE_PATH="$1"
    if [ ! -s "$FILE_PATH" ]; then
        return 0
    fi
    return 1
}

function check_number_is_divisible_by_two () {
    local NUMBER=$1
    if (( $NUMBER % 2 == 0 )); then
        return 0
    fi
    return 1
}

function check_is_subnet_address () {
    local IPV4_SUBNET="$1"
    local SUBNET_REGEX_PATTERN='^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$'
    echo "$IPV4_SUBNET" | egrep -e $SUBNET_REGEX_PATTERN &> /dev/null
    if [ $? -ne 0 ]; then
        return 1
    fi
    IFS='.'
    for octet in $IPV4_SUBNET; do
        check_value_is_number $octet
        if [ $? -ne 0 ]; then
            IFS=' '
            return 1
        elif [ $octet -gt 254 ]; then
            IFS=' '
            return 1
        fi
    done
    IFS=' '
    return 0
}

function check_is_ipv4_address () {
    local IPV4_ADDRESS="$1"
    local IPV4_REGEX_PATTERN='^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$'
    echo "$IPV4_ADDRESS" | egrep -e $IPV4_REGEX_PATTERN &> /dev/null
    if [ $? -ne 0 ]; then
        return 1
    fi
    IFS='.'
    for octet in $IPV4_ADDRESS; do
        check_value_is_number $octet
        if [ $? -ne 0 ]; then
            IFS=' '
            return 1
        elif [ $octet -gt 254 ]; then
            IFS=' '
            return 1
        fi
    done
    IFS=' '
    return 0
}

function check_is_mac_address () {
    local MAC_ADDRESS="$1"
    local MAC_REGEX_PATTERN='^([0-9A-Fa-f]{1,2}[:-]){5}([0-9A-Fa-f]{1,2})$'
    echo "$MAC_ADDRESS" | egrep -e $MAC_REGEX_PATTERN &> /dev/null
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 1 ]; then
        return 0
    fi
    return 1
}

function check_file_exists () {
    local FILE_PATH="$1"
    if [ -f "$FILE_PATH" ]; then
        return 0
    fi
    return 1
}

function check_directory_exists () {
    local DIR_PATH="$1"
    if [ -d "$DIR_PATH" ]; then
        return 0
    fi
    return 1
}

# CREATORS

function create_file () {
    local FILE_PATH="$1"
    if [ ! -d "$FILE_PATH" ]; then
        touch "$FILE_PATH" &> /dev/null
        return $?
    fi
    return 1
}

function create_directory () {
    local DIR_PATH="$1"
    if [ ! -d "$DIR_PATH" ]; then
        mkdir -p "$DIR_PATH" &> /dev/null
        return $?
    fi
    return 1
}

# INSTALLERS

function apt_install_dependency() {
    local UTIL="$1"
    symbol_msg "${GREEN}+${RESET}" \
        "Installing package ${YELLOW}$UTIL${RESET}..."
    apt-get install $UTIL
    return $?
}

function apt_install_full_clip_logic_sniper_dependencies () {
    if [ ${#APT_DEPENDENCIES[@]} -eq 0 ]; then
        info_msg 'No dependencies to fetch using the apt package manager.'
        return 1
    fi

    is_alive_ping $REMOTE_RESOURCE
    if [ $? -ne 0 ]; then
        warning_msg "Remote resource ${RED}$REMOTE_RESOURCE${RESET}"\
            "did not respond to ping. You may have a connection problem."
    fi

    local FAILURE_COUNT=0
    info_msg "Installing dependencies using apt package manager:"
    for package in "${APT_DEPENDENCIES[@]}"; do
        echo; apt_install_dependency $package
        if [ $? -ne 0 ]; then
            nok_msg "Failed to install ${YELLOW}$SCRIPT_NAME${RESET}"\
                "dependency ${RED}$package${RESET}!"
            FAILURE_COUNT=$((FAILURE_COUNT + 1))
        else
            ok_msg "Successfully installed ${YELLOW}$SCRIPT_NAME${RESET}"\
                "dependency ${GREEN}$package${RESET}."
            INSTALL_COUNT=$((INSTALL_COUNT + 1))
        fi
    done
    if [ $FAILURE_COUNT -ne 0 ]; then
        echo; warning_msg "${RED}$FAILURE_COUNT${RESET} dependency"\
            "installation failures!"\
            "Try installing the packages manually ${GREEN}:)${RESET}"
    fi
    return 0
}

# GENERAL

function banner_grabber () {
    local TARGET_MACHINE_ADDRESS="$1"
    local TARGET_PORT_NUMBER="$2"
    local REQUEST_BODY="${@:3}"
    echo "$REQUEST_BODY" | \
        nc -w 10 -vv "$TARGET_MACHINE_ADDRESS" $TARGET_PORT_NUMBER
    return $?
}

function logic_sniper_setup_subroutine () {
    echo; info_msg "Searching for active wireless interface..."
    DETECTED_INTERFACE=`fetch_wireless_interface`
    if [ $? -eq 0 ]; then
        ok_msg "Detected interface ${GREEN}$DETECTED_INTERFACE${RESET}."
        set_wireless_interface "$DETECTED_INTERFACE"
    fi

    info_msg "Attempting to fetch wireless gateway ESSID..."
    DETECTED_ESSID=`fetch_currently_connected_gateway_essid`
    if [ $? -eq 0 ]; then
        ok_msg "Detected ESSID ${GREEN}$DETECTED_ESSID${RESET}."
        set_connected_essid "$DETECTED_ESSID"
    fi

    info_msg "Attempting to fetch wireless gateway BSSID..."
    DETECTED_BSSID=`fetch_wireless_gateway_bssid`
    if [ $? -eq 0 ]; then
        ok_msg "Detected BSSID ${GREEN}$DETECTED_BSSID${RESET}."
        set_connected_bssid "$DETECTED_BSSID"
    fi

    info_msg "Attempting to fetch wireless network radio channel..."
    DETECTED_CHANNEL_NUMBER=`fetch_wireless_gateway_channel_by_interface \
        "$DETECTED_INTERFACE"`
    if [ $? -eq 0 ]; then
        ok_msg "Detected channel ${GREEN}$DETECTED_CHANNEL_NUMBER${RESET}."
        set_connection_channel $DETECTED_CHANNEL_NUMBER
    fi

    info_msg "Ensuring user Black Book journal exists."
    ensure_user_black_book_journal
    if [ $? -eq 0 ]; then
        ok_msg "${GREEN}Black Book${RESET} journal exists."
    fi

    info_msg "Ensuring user Action Journal exists."
    ensure_user_action_journal
    if [ $? -eq 0 ]; then
        ok_msg "${GREEN}Action Journal${RESET} exists."
    fi

    info_msg "Setting ${BLUE}$SCRIPT_NAME${RESET} safety to ON."
    set_logic_sniper_safety 'on'
    if [ $? -eq 0 ]; then
        ok_msg "${BLUE}$SCRIPT_NAME${RESET} safety is ${GREEN}ON${RESET}."
    fi
    return 0
}

function three_second_count_down () {
    for item in `seq 3`; do
        echo -n '.'; sleep 1
    done; echo; return 0
}

function perform_endless_wireless_deauthentication_attack () {
    local DEVICE_MAC_ADDRESS="$1"
    local ROUTER_MAC_ADDRESS="$2"
    local WIRELESS_MONITOR_INTERFACE="$3"
    check_is_mac_address $DEVICE_MAC_ADDRESS
    if [ $? -ne 0 ]; then
        echo; error_msg "Illegal data set, required machine"\
            "${GREEN}MAC address${RESET}, not"\
            "${RED}$DEVICE_MAC_ADDRESS${RESET}."
        return 1
    fi
    check_is_mac_address $ROUTER_MAC_ADDRESS
    if [ $? -ne 0 ]; then
        echo; error_msg "Illegal data set, required router MAC address, not"\
            "${RED}$ROUTER_MAC_ADDRESS${RESET}."
        return 1
    fi
    check_valid_wireless_interface $WIRELESS_MONITOR_INTERFACE
    if [ $? -ne 0 ]; then
        echo; error_msg "Invalid data set, wireless interface"\
            "${RED}$WIRELESS_MONITOR_INTERFACE${RESET} not found."
        return 1
    fi

    trap "return $?" SIGINT

    aireplay-ng --deauth 0 \
        -c $DEVICE_MAC_ADDRESS \
        -a $ROUTER_MAC_ADDRESS \
        $WIRELESS_MONITOR_INTERFACE
    return $?
}

function stop_wireless_monitor_interface () {
    PREVIOUS_WIRELESS_INTERFACE=`fetch_previouly_detected_wireless_interface`
    check_valid_wireless_interface \
        `echo "$PREVIOUS_WIRELESS_INTERFACE""mon"`
    if [ $? -ne 0 ]; then
        echo; error_msg "Invalid data set, wireless interface"\
            "${RED}$PREVIOUS_WIRELESS_INTERFACE${RESET} not found."
        return 1
    fi
    airmon-ng stop "$PREVIOUS_WIRELESS_INTERFACE""mon"
    return $?
}

function start_wireless_monitor_interface () {
    local WIRELESS_INTERFACE="$1"
    local CHANNEL_NUMBER=$2
    check_valid_wireless_interface "$WIRELESS_INTERFACE"
    if [ $? -ne 0 ]; then
        echo; error_msg "Invalid wireless interface"\
            "${RED}$WIRELESS_INTERFACE${RESET}."
    fi
    check_value_is_number $CHANNEL_NUMBER
    if [ $? -ne 0 ] && [ ! -z "$CHANNEL_NUMBER" ]; then
        echo; error_msg "Invalid channel number"\
            "${RED}$CHANNEL_NUMBER${RESET}."
    fi
    airmon-ng start "$WIRELESS_INTERFACE" $CHANNEL_NUMBER
    return $?
}

function connect_to_wireless_access_point () {
    local CONNECTION_MODE="$1"
    local TARGET_ESSID="$2"
    local WIFI_PASSWORD="$3"
    check_safety_off
    if [ $? -ne 0 ]; then
        warning_msg "${GREEN}$SCRIPT_NAME${RESET}"\
            "safety is ${GREEN}ON${RESET}."\
            "Machine will not be connecting network."
        return 0
    fi
    case "$CONNECTION_MODE" in
        'password-on')
            ${AUTOMATION['wifi-commander']} \
                "$CONF_FILE_PATH" \
                --connect-pass "$TARGET_ESSID" "$WIFI_PASSWORD"
            ;;
        'password-off')
            ${AUTOMATION['wifi-commander']} \
                "$CONF_FILE_PATH" \
                --connect-without-pass "$TARGET_ESSID"
            ;;
        *)
            echo; info_msg "No connection mode specified,"\
                "defaulting to password protected."
            ${AUTOMATION['wifi-commander']} \
                "$CONF_FILE_PATH" \
                --connect-pass "$TARGET_ESSID" "$WIFI_PASSWORD"
            ;;
    esac
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        set_connected_essid "$TARGET_ESSID"
    fi
    return $EXIT_CODE
}

function disconnect_from_wireless_access_point () {
    check_safety_off
    if [ $? -ne 0 ]; then
        echo; warning_msg "${GREEN}$SCRIPT_NAME${RESET}"\
            "safety is ${GREEN}ON${RESET}."\
            "Machine will not be disconnecting from network."
        return 0
    fi
    wpa_cli terminate &> /dev/null
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        set_connected_essid "Unconnected"
    fi
    return $EXIT_CODE
}

function is_alive_ping () {
    local TARGET=$1
    ping -c 1 $TARGET &> /dev/null
    [ $? -eq 0 ] && return 0 || return 1
}

function journal_entry () {
    local TIMESTAMP=`date`
    local FILE_PATH="$1"
    local MESSAGE="${@:2}"
    local JOURNAL_ENTRY="[ $TIMESTAMP ]: $MESSAGE"
    echo "$JOURNAL_ENTRY" >> "$FILE_PATH"
    return $?
}

function action_journal_entry () {
    local MESSAGE="$@"
    journal_entry "${DEFAULT['action-journal']}" "$MESSAGE"
    return $?
}

function black_book_journal_entry () {
    local MESSAGE="$@"
    journal_entry "${DEFAULT['black-book']}" "$MESSAGE"
    return $?
}

function ensure_user_action_journal () {
    ensure_journal_directory
    ensure_action_journal_file
    return $?
}

function ensure_journal_directory () {
    check_directory_exists "$JOURNAL_DIR"
    if [ $? -ne 0 ]; then
        create_directory "$JOURNAL_DIR"
    fi
    return 0
}

function ensure_action_journal_file () {
    check_file_exists "${DEFAULT['action-journal']}"
    if [ $? -ne 0 ]; then
        create_file "${DEFAULT['action-journal']}"
    fi
    return 0
}

function ensure_black_book_journal_file () {
    check_file_exists "${DEFAULT['black-book']}"
    if [ $? -ne 0 ]; then
        create_file "${DEFAULT['black-book']}"
    fi
    return 0
}

function ensure_user_black_book_journal () {
    ensure_journal_directory
    ensure_black_book_journal_file
    return $?
}

function write_to_file () {
    local FILE_PATH="$1"
    local CONTENT="${@:2}"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "File ${RED}$FILE_PATH${RESET} does not exist."
        echo; return 1
    elif [ -z $CONTENT ]; then
        echo; warning_msg "No content specified."
        echo; return 2
    fi
    echo "$CONTENT" >> "$FILE_PATH"
    return $?
}

function clear_file () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; warning_msg "File ${RED}$FILE_PATH${RESET} does not exist."
        echo; return 1
    fi
    echo -n > $FILE_PATH
    return $?
}

function edit_file () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; warning_msg "File ${RED}$FILE_PATH${RESET} does not exist."
        echo; return 1
    fi
    if [ -z "${DEFAULT['file-editor']}" ] && [ -z $EDITOR ]; then
        vim "$FILE_PATH"
        return $?
    elif [ -z "${DEFAULT['file-editor']}" ] && [ ! -z $EDITOR ]; then
        $EDITOR "$FILE_PATH"
        return $?
    elif [ ! -z "${DEFAULT['file-editor']}" ]; then
        ${DEFAULT['file-editor']} "$FILE_PATH"
        return $?
    fi
    return 2
}

function lan_scan () {
    for i in `seq $START_ADDRESS_RANGE $END_ADDRESS_RANGE`; do
        ping "$SUBNET_ADDRESS.$i" -c 1 -w 5 > /dev/null && (
            arp -a "$SUBNET_ADDRESS.$i" | \
            egrep -e '([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.' | \
            sort -u | \
            awk '{print $2$4}' | \
            sed -e 's/)/ /g' -e 's/(//g'
        ) &
    done; sleep 1
    return 0
}

# FORMATTERS

function format_lan_scan () {
    lan_scan | column -t > ${DEFAULT['tmp-file']}
    local COUNT=1
    local ACTIVE_MACHINES=`fetch_file_length ${DEFAULT['tmp-file']}`
    CURRENT_ESSID=`fetch_currently_connected_gateway_essid`
    DISPLAY_ESSID=${CURRENT_ESSID:-'Unconnected'}
    echo "${CYAN}Active Machines On WiFi Network"\
        "${GREEN}$DISPLAY_ESSID${CYAN}(${WHITE}$ACTIVE_MACHINES${CYAN})${RESET}"
    echo "${CYAN}   IPV4 Address      MAC Address${RESET}"
    while read line; do
        echo "${WHITE}$COUNT${RESET}) ${GREEN}$line${RESET}"
        local COUNT=$((COUNT + 1))
    done < ${DEFAULT['tmp-file']}
#   cleanup_default_temporary_file
    return 0
}

# CLEANERS

function cleanup_default_temporary_file () {
    if [ ! -f ${DEFAULT['tmp-file']} ]; then
        warning_msg "No temporary file found at"\
            "${RED}${DEFAULT['tmp-file']}${RESET}."
        return 1
    fi
    rm ${DEFAULT['tmp-file']} &> /dev/null
    return $?
}

# SCANNERS

function scan_machine_port () {
    local IPV4_ADDRESS="$1"
    local PORT_NUMBER=$2
    nmap -p $PORT_NUMBER "$IPV4_ADDRESS"
    return $?
}

function scan_machine_port_range () {
    local IPV4_ADDRESS="$1"
    local INITIAL_PORT_NUMBER=$2
    local FINAL_PORT_NUMBER=$3
    nmap -p $INITIAL_PORT_NUMBER-$FINAL_PORT_NUMBER "$IPV4_ADDRESS"
    return $?
}

function scan_machine_all_ports () {
    local IPV4_ADDRESS="$1"
    nmap -p- "$IPV4_ADDRESS"
    return $?
}

# ACTIONS

# [ NOTE ]: Safety switch verifications are performed here.

function action_banner_grab () {
    echo; info_msg "Type target machine ${YELLOW}IPv4 address${RESET}"\
        "or ${MAGENTA}.back${RESET}."
    IPV4_ADDRESS=`fetch_ipv4_address_from_user`
    if [ $? -ne 0 ]; then
        return 1
    fi

    echo; info_msg "Type target machine ${YELLOW}port number${RESET}"\
        "or ${MAGENTA}.back${RESET}."
    PORT_NUMBER=`fetch_single_port_number_from_user`
    if [ $? -ne 0 ]; then
        return 1
    fi

    echo; symbol_msg "${BLUE}ProTip${RESET}" \
        "Try something like ${YELLOW}GET /${RESET} for HTTP port 80"\
        "or ${YELLOW}-${RESET} for SSH port 22 ${BLUE};)${RESET}"
    echo; info_msg "Type ${YELLOW}request body${RESET}"\
        "or ${MAGENTA}.back${RESET}."
    REQUEST_BODY=`fetch_request_body_from_user`
    if [ $? -ne 0 ]; then
        return 1
    elif [[ "$REQUEST_BODY" == '-' ]]; then
        REQUEST_BODY=''
    fi

    echo; fetch_ultimatum_from_user "Are you sure about this? ${YELLOW}Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi

    check_safety_on
    if [ $? -eq 0 ]; then
        echo; warning_msg "Safety is ${GREEN}ON${RESET}."\
            "Banner grabbing will not be performed."
        return 1
    fi

    echo; info_msg "Performing ${BLUE}NetCat${RESET} banner grabbing for"\
        "${YELLOW}$IPV4_ADDRESS${RESET} port ${WHITE}$PORT_NUMBER${RESET}..."
    echo "================================================================================"
    banner_grabber "$IPV4_ADDRESS" $PORT_NUMBER "$REQUEST_BODY"
    EXIT_CODE=$?
    echo "================================================================================"

    if [ $EXIT_CODE -eq 0 ]; then
        done_msg "Banner grabbing of ${GREEN}$IPV4_ADDRESS${RESET}"\
            "port ${WHITE}$PORT_NUMBER${RESET} completed successfully."
    else
        nok_msg "Something went wrong."\
            "Could not banner grab ${RED}$IPV4_ADDRESS${RESET} port"\
            "${WHITE}$PORT_NUMBER${RESET}."
    fi

    action_journal_entry "Performed banner grabbing of $IPV4_ADDRESS"\
        "on port $PORT_NUMBER using request ($REQUEST_BODY)."
    return $EXIT_CODE
}

function action_scan_machine_port_range () {
    echo; info_msg "Type target machine ${YELLOW}IPv4 address${RESET}"\
        "or ${MAGENTA}.back${RESET}."
    IPV4_ADDRESS=`fetch_ipv4_address_from_user`
    if [ $? -ne 0 ]; then
        return 1
    fi

    while :
    do
        echo; info_msg "Type port range ${YELLOW}initial port number${RESET}"\
            "or ${MAGENTA}.back${RESET}."
        INITIAL_PORT=`fetch_single_port_number_from_user "InitialPort"`
        if [ $? -ne 0 ]; then
            return 1
        fi
        while :
        do
            echo; info_msg "Type port range ${YELLOW}final port number${RESET}"\
                "or ${MAGENTA}.back${RESET}."
            FINAL_PORT=`fetch_single_port_number_from_user "FinalPort"`
            if [ $? -ne 0 ]; then
                return 1
            fi
            if [ $FINAL_PORT -lt $INITIAL_PORT ]; then
                echo; warning_msg "Final port number ${RED}$FINAL_PORT${RESET}"\
                    "cannot be lesser than"\
                    "initial port number ${YELLOW}$INITIAL_PORT${RESET}."
                qa_msg "Would you like to reset"\
                    "${YELLOW}initial port number${RESET}?"
                fetch_ultimatum_from_user "${YELLOW}Y/N${RESET}"
                if [ $? -eq 0 ]; then
                    echo; info_msg "Initial port number reset."
                    break
                fi
            fi; break
        done
        if [ ! -z "$FINAL_PORT" ]; then
            break
        fi
    done

    echo; fetch_ultimatum_from_user "Are you sure about this? ${YELLOW}Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi

    check_safety_on
    if [ $? -eq 0 ]; then
        echo; warning_msg "Safety is ${GREEN}ON${RESET}."\
            "Machine port scanning will not be performed."
        return 1
    fi

    echo; info_msg "Generating ${BLUE}NMAP${RESET} report for"\
        "${YELLOW}$IPV4_ADDRESS${RESET} scanning of port range"\
        "[${WHITE}$INITIAL_PORT-$FINAL_PORT${RESET}]..."
    echo "================================================================================"
    scan_machine_port_range "$IPV4_ADDRESS" $INITIAL_PORT $FINAL_PORT
    EXIT_CODE=$?
    echo "================================================================================"

    if [ $EXIT_CODE -eq 0 ]; then
        done_msg "Port scan of ${GREEN}$IPV4_ADDRESS${RESET}"\
            "completed successfully."
    else
        nok_msg "Something went wrong."\
            "Could not port scan ${RED}$IPV4_ADDRESS${RESET}."
    fi

    action_journal_entry "Scanned machine $IPV4_ADDRESS"\
        "port range $INITIAL_PORT-$FINAL_PORT."
    return $EXIT_CODE
}

function action_scan_machine_all_ports () {
    echo; info_msg "Type target machine ${YELLOW}IPv4 address${RESET}"\
        "or ${MAGENTA}.back${RESET}."
    IPV4_ADDRESS=`fetch_ipv4_address_from_user`
    if [ $? -ne 0 ]; then
        return 1
    fi

    echo; fetch_ultimatum_from_user "Are you sure about this? ${YELLOW}Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi

    check_safety_on
    if [ $? -eq 0 ]; then
        echo; warning_msg "Safety is ${GREEN}ON${RESET}."\
            "Machine port scanning will not be performed."
        return 1
    fi

    echo; info_msg "Generating ${BLUE}NMAP${RESET} report for"\
        "${YELLOW}$IPV4_ADDRESS${RESET} scanning of all ports..."
    echo "================================================================================"
    scan_machine_all_ports "$IPV4_ADDRESS"
    EXIT_CODE=$?
    echo "================================================================================"

    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi

    if [ $EXIT_CODE -eq 0 ]; then
        done_msg "Port scan of ${GREEN}$IPV4_ADDRESS${RESET}"\
            "completed successfully."
    else
        nok_msg "Something went wrong."\
            "Could not port scan ${RED}$IPV4_ADDRESS${RESET}."
    fi

    action_journal_entry "Scanned all machine $IPV4_ADDRESS ports."
    return $EXIT_CODE
}

function action_scan_machine_single_port () {
    echo; info_msg "Type target machine ${YELLOW}IPv4 address${RESET}"\
        "or ${MAGENTA}.back${RESET}."
    IPV4_ADDRESS=`fetch_ipv4_address_from_user`
    if [ $? -ne 0 ]; then
        return 1
    fi

    echo; info_msg "Type target machine ${YELLOW}port number${RESET}"\
        "or ${MAGENTA}.back${RESET}."
    PORT_NUMBER=`fetch_single_port_number_from_user`
    if [ $? -ne 0 ]; then
        return 1
    fi

    echo; fetch_ultimatum_from_user "Are you sure about this? ${YELLOW}Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi

    check_safety_on
    if [ $? -eq 0 ]; then
        echo; warning_msg "Safety is ${GREEN}ON${RESET}."\
            "Machine port scanning will not be performed."
        return 1
    fi

    echo; info_msg "Generating ${BLUE}NMAP${RESET} report for"\
        "${YELLOW}$IPV4_ADDRESS${RESET} scanning of"\
        "port ${WHITE}$PORT_NUMBER${RESET}..."
    echo "================================================================================"
    scan_machine_port "$IPV4_ADDRESS" $PORT_NUMBER
    EXIT_CODE=$?
    echo "================================================================================"

    if [ $EXIT_CODE -eq 0 ]; then
        done_msg "Port scan of ${GREEN}$IPV4_ADDRESS${RESET}"\
            "completed successfully."
    else
        nok_msg "Something went wrong."\
            "Could not port scan ${RED}$IPV4_ADDRESS${RESET}."
    fi

    action_journal_entry "Scanned machine $IPV4_ADDRESS port $PORT_NUMBER."
    return $EXIT_CODE
}

function action_kick_machine_off_network () {
    local WIRELESS_INTERFACE="$1"
    local CHANNEL_NUMBER=$2
    local ROUTER_BSSID="$3"
    local DEVICE_MAC_ADDRESS="$4"

    check_safety_on
    if [ $? -eq 0 ]; then
        echo; warning_msg "Safety is ${GREEN}ON${RESET}."\
            "Connection with wireless access point will not be performed."
        return 1
    fi

    echo; info_msg "Starting wireless monitor interface on"\
        "${YELLOW}$WIRELESS_INTERFACE${RESET}"\
        "channel ${WHITE}$CHANNEL_NUMBER${RESET}..."
    start_wireless_monitor_interface "$WIRELESS_INTERFACE" "$CHANNEL_NUMBER" &> /dev/null
    if [ $? -ne 0 ]; then
        echo; warning_msg "Something went wrong."\
            "Could not start wireless monitor interface on"\
            "${RED}$WIRELESS_INTERFACE${RESET}"\
            "channel ${RED}$CHANNEL_NUMBER${RESET}."
        return 1
    fi

    PREVIOUS_WIRELESS_INTERFACE=`fetch_previouly_detected_wireless_interface`
    local MONITOR_INTERFACE="$PREVIOUS_WIRELESS_INTERFACE""mon"
    ok_msg "Successfully started wireless monitor interface"\
        "${GREEN}$MONITOR_INTERFACE${RESET}."

    info_msg "Initiating endless wireless"\
        "${YELLOW}deauthentication attack${RESET},"\
        "press <${GREEN}Ctrl-c${RESET}> to stop."; three_second_count_down
    perform_endless_wireless_deauthentication_attack "$DEVICE_MAC_ADDRESS" "$ROUTER_BSSID" "$MONITOR_INTERFACE"
    echo; ok_msg "Wireless ${GREEN}deauthentication attack${RESET} performed successfully."
    info_msg "Tearing down wireless monitor interface"\
        "${YELLOW}$MONITOR_INTERFACE${RESET}."

    stop_wireless_monitor_interface &> /dev/null
    if [ $? -ne 0 ]; then
        warning_msg "Something went wrong."\
            "Could not stop wireless monitor interface"\
            "${RED}$MONITOR_INTERFACE${RESET}."
        return 2
    fi

    trap - SIGINT

    black_book_journal_entry "$DEVICE_MAC_ADDRESS"
    action_journal_entry "Kicked machine $DEVICE_MAC_ADDRESS"\
        "off wireless network. Interface $WIRELESS,"\
        "BSSID $ROUTER_BSSID,"\
        "radio channel $CHANNEL_NUMBER."
    return 0
}

function action_scan_wireless_network () {
    echo; info_msg "Ping sweeping ${YELLOW}$CONNECTED_ESSID${RESET} network"\
        "address range"\
        "${MAGENTA}$SUBNET_ADDRESS.$START_ADDRESS_RANGE-$END_ADDRESS_RANGE${RESET}..."
    clear_file "${DEFAULT['tmp-file']}" &> /dev/null
    echo; format_lan_scan
    EXIT_CODE=$?

    action_journal_entry "Scanned subnet address range"\
        "$SUBNET_ADDRESS.$START_ADDRESS_RANGE-$END_ADDRESS_RANGE."
    return $EXIT_CODE
}

function action_disconnect_from_wireless_access_point () {
    echo; info_msg "You are about to disconnect from wireless network."
    fetch_ultimatum_from_user "Are you sure about this? ${YELLOW}Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi

    check_safety_on
    if [ $? -eq 0 ]; then
        warning_msg "Safety is ${GREEN}ON${RESET}."\
            "Connection with wireless access point will not be performed."
        return 1
    fi

    disconnect_from_wireless_access_point
    if [ $? -ne 0 ]; then
        echo; warning_msg "Something went wrong."\
            "Could not disconnect from wireless access point."
        return 1
    fi

    action_journal_entry "Disconnected from wireless access point."
    return 0
}

function action_connect_to_wireless_access_point () {
    echo; symbol_msg "${BLUE}$SCRIPT_NAME${RESET}" \
        "${CYAN}Wireless Network Gateways (Radios)${RESET}"

    info_msg "Discovering wireless network access points..."; echo
    TARGET_ESSID=`fetch_wireless_essid_from_user`
    if [ $? -ne 0 ]; then
        return 1
    fi

    SANITIZED=`echo $TARGET_ESSID | sed 's/\"//g'`
    check_essid_password_protected "$SANITIZED"
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        PASSWORD=`fetch_wireless_password_from_user "$SANITIZED"`
        echo "
        "; check_safety_on
        if [ $? -eq 0 ]; then
            warning_msg "Safety is ${GREEN}ON${RESET}."\
                "Connection with wireless access point will not be performed."
        fi

        connect_to_wireless_access_point "password-on" "$SANITIZED" "$PASSWORD"
        if [ $? -ne 0 ]; then
            echo; warning_msg "Something went wrong."\
                "Could not connect to protected wireless access point"\
                "${RED}$SANITIZED${RESET}."
            return 1
        fi
        action_journal_entry "Connected to protected"\
            "wireless access point $SANITIZED."

    elif [ $EXIT_CODE -eq 1 ]; then
        echo; check_safety_on
        if [ $? -eq 0 ]; then
            warning_msg "Safety is ${GREEN}ON${RESET}."\
                "Connection with wireless access point will not be performed."
            return 1
        fi

        connect_to_wireless_access_point "password-off" "$SANITIZED" "$PASSWORD"
        if [ $? -ne 0 ]; then
            echo; warning_msg "Something went wrong."\
                "Could not connect to unprotected wireless access point"\
                "${RED}$SANITIZED${RESET}."
            return 1
        fi
        action_journal_entry "Connected to unprotected"\
            "wireless access point $SANITIZED."

    else
        echo; warning_msg "Could not determine if wireless network"\
            "${RED}$SANITIZED${RESET} is password protected."
        return 1
    fi
    return 0
}

function action_display_available_wireless_access_points () {
    echo; info_msg "Discovering wireless network access points..."
    display_available_wireless_access_points
    if [ $? -ne 0 ]; then
        echo; warning_msg "Something went wrong."\
            "Could not display wireless access points."
        return 1
    fi

    action_journal_entry "Displayed all available wireless access points."
    return 0
}

function action_set_black_book_journal_file () {
    echo; info_msg "Type absolute ${YELLOW}Black Book${RESET}"\
        "journal file path or ${MAGENTA}.back${RESET}."
    while :
    do
        FILE_PATH=`fetch_data_from_user "FilePath"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        check_file_exists $FILE_PATH
        if [ $? -ne 0 ]; then
            echo; qa_msg "File ${YELLOW}$FILE_PATH${RESET} does not exist."\
                "Would you like to create it now?"
            fetch_ultimatum_from_user "${YELLOW}Y/N${RESET}"
            if [ $? -ne 0 ]; then
                echo; info_msg "Aborting action."
                return 1
            fi
            create_file $FILE_PATH
        fi
        set_user_black_book_journal_file "$FILE_PATH"
        if [ $? -ne 0 ]; then
            warning_msg "Something went wrong."\
                "Could not set ${RED}$FILE_PATH${RESET}"\
                "as default ${YELLOW}Black Book${RESET} journal file."
            echo; continue
        fi; break
    done
    echo; ok_msg "Successfully set ${GREEN}$FILE_PATH${RESET}"\
        "as default ${YELLOW}Black Book${RESET} journal file."

    action_journal_entry "Set Black Book journal file path $FILE_PATH."
    return 0
}

function action_set_user_action_journal_file () {
    echo; info_msg "Type absolute ${YELLOW}Action Journal${RESET}"\
        "file path or ${MAGENTA}.back${RESET}."
    while :
    do
        FILE_PATH=`fetch_data_from_user "FilePath"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi

        check_file_exists $FILE_PATH
        if [ $? -ne 0 ]; then
            echo; qa_msg "File ${YELLOW}$FILE_PATH${RESET} does not exist."\
                "Would you like to create it now?"
            fetch_ultimatum_from_user "${YELLOW}Y/N${RESET}"
            if [ $? -ne 0 ]; then
                echo; info_msg "Aborting action."
                return 1
            fi
            create_file $FILE_PATH
        fi

        set_user_action_journal_file "$FILE_PATH"
        if [ $? -ne 0 ]; then
            warning_msg "Something went wrong."\
                "Could not set ${RED}$FILE_PATH${RESET}"\
                "as default ${YELLOW}Action Journal${RESET} file."
            echo; continue
        fi
        break
    done
    echo; ok_msg "Successfully set ${GREEN}$FILE_PATH${RESET}"\
        "as default ${YELLOW}Action Journal${RESET} file."

    action_journal_entry "Set Action Journal file path $FILE_PATH."
    return 0
}

function action_set_wpa_supplicant_configuration_file () {
    echo; info_msg "Type absolute ${YELLOW}WPA Supplicant${RESET}"\
        "configuration file path or ${MAGENTA}.back${RESET}."
    while :
    do
        FILE_PATH=`fetch_data_from_user "FilePath"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        check_file_exists $FILE_PATH
        if [ $? -ne 0 ]; then
            echo; qa_msg "File ${YELLOW}$FILE_PATH${RESET} does not exist."\
                "Would you like to create it now?"
            fetch_ultimatum_from_user "${YELLOW}Y/N${RESET}"
            if [ $? -ne 0 ]; then
                echo; info_msg "Aborting action."
                return 1
            fi
            create_file $FILE_PATH
        fi
        set_wpa_supplicant_configuration_file "$FILE_PATH"
        if [ $? -ne 0 ]; then
            warning_msg "Something went wrong."\
                "Could not set ${RED}$FILE_PATH${RESET}"\
                "as default ${YELLOW}WPA Supplicant${RESET}"\
                "configuration file."
            echo; continue
        fi
        break
    done
    echo; ok_msg "Successfully set ${GREEN}$FILE_PATH${RESET}"\
        "as default ${YELLOW}WPA Supplicant${RESET} configuration file."

    action_journal_entry "Set WPA Supplicant configuration file $FILE_PATH."
    return 0
}

function action_set_wpa_supplicant_log_file () {
    echo; info_msg "Type absolute ${YELLOW}WPA Supplicant${RESET}"\
        "log file path or ${MAGENTA}.back${RESET}."
    while :
    do
        FILE_PATH=`fetch_data_from_user "FilePath"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        check_file_exists $FILE_PATH
        if [ $? -ne 0 ]; then
            echo; qa_msg "File ${YELLOW}$FILE_PATH${RESET} does not exist."\
                "Would you like to create it now?"
            fetch_ultimatum_from_user "${YELLOW}Y/N${RESET}"
            if [ $? -ne 0 ]; then
                echo; info_msg "Aborting action."
                return 1
            fi
            create_file $FILE_PATH
        fi
        set_wpa_supplicant_log_file "$FILE_PATH"
        if [ $? -ne 0 ]; then
            warning_msg "Something went wrong."\
                "Could not set ${RED}$FILE_PATH${RESET}"\
                "as default ${YELLOW}WPA Supplicant${RESET} log file."
            echo; continue
        fi
        break
    done
    echo; ok_msg "Successfully set ${GREEN}$FILE_PATH${RESET}"\
        "as default ${YELLOW}WPA Supplicant${RESET} log file."

    action_journal_entry "Set WPA Supplicanr log file $FILE_PATH."
    return 0
}

function action_set_dhcpcd_log_file () {
    echo; info_msg "Type absolute ${YELLOW}DHCPD${RESET} log file path"\
        "or ${MAGENTA}.back${RESET}."
    while :
    do
        FILE_PATH=`fetch_data_from_user "FilePath"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        check_file_exists $FILE_PATH
        if [ $? -ne 0 ]; then
            echo; qa_msg "File ${YELLOW}$FILE_PATH${RESET} does not exist."\
                "Would you like to create it now?"
            fetch_ultimatum_from_user "${YELLOW}Y/N${RESET}"
            if [ $? -ne 0 ]; then
                echo; info_msg "Aborting action."
                return 1
            fi
            create_file $FILE_PATH
        fi
        set_dhcpcd_log_file "$FILE_PATH"
        if [ $? -ne 0 ]; then
            warning_msg "Something went wrong."\
                "Could not set ${RED}$FILE_PATH${RESET}"\
                "as default ${YELLOW}DHCPD${RESET} log file."
            echo; continue
        fi
        break
    done
    echo; ok_msg "Successfully set ${GREEN}$FILE_PATH${RESET}"\
        "as default ${YELLOW}DHCPD${RESET} log file."

    action_journal_entry "Set DHCPD log file $FILE_PATH."
    return 0
}

function action_set_temporary_file () {
    echo; info_msg "Type absolute temporary file path"\
        "or ${MAGENTA}.back${RESET}."
    while :
    do
        FILE_PATH=`fetch_data_from_user "FilePath"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        check_file_exists $FILE_PATH
        if [ $? -ne 0 ]; then
            echo; qa_msg "File ${YELLOW}$FILE_PATH${RESET} does not exist."\
                "Would you like to create it now?"
            fetch_ultimatum_from_user "${YELLOW}Y/N${RESET}"
            if [ $? -ne 0 ]; then
                echo; info_msg "Aborting action."
                return 1
            fi
            create_file $FILE_PATH
        fi
        set_temporary_file "$FILE_PATH"
        if [ $? -ne 0 ]; then
            warning_msg "Something went wrong."\
                "Could not set ${RED}$FILE_PATH${RESET}"\
                "as default temporary file."
            echo; continue
        fi
        break
    done
    echo; ok_msg "Successfully set ${GREEN}$FILE_PATH${RESET}"\
        "as default temporary file."

    action_journal_entry "Set temporary file $FILE_PATH."
    return 0
}

function action_set_file_editor () {
    echo; info_msg "Type file editor name or ${MAGENTA}.back${RESET}."
    while :
    do
        FILE_EDITOR=`fetch_data_from_user "FileEditor"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        set_file_editor "$FILE_EDITOR"
        if [ $? -ne 0 ]; then
            warning_msg "Something went wrong."\
                "Could not set default file editor"\
                "${RED}$FILE_EDITOR${RESET}."
            echo; continue
        fi
        break
    done
    echo; ok_msg "Successfully set ${GREEN}$FILE_EDITOR${RESET}"\
        "as the default file editor."

    action_journal_entry "Set file editor $FILE_EDIOR."
    return 0
}

function action_set_remote_resource_server () {
    echo; info_msg "Type remote resource server address"\
        "or ${MAGENTA}.back${RESET}."
    while :
    do
        REMOTE_RESOURCE=`fetch_data_from_user "ServerAddress"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        set_remote_resource_server "$REMOTE_RESOURCE"
        if [ $? -ne 0 ]; then
            warning_msg "Something went wrong."\
                "Could not set ${RED}$REMOTE_RESOURCE${RESET}"\
                "as the remote resource server."
            echo; continue
        fi
        break
    done
    echo; ok_msg "Successfully set ${GREEN}$REMOTE_RESOURCE${RESET}"\
        "as the remote resource server."

    action_journal_entry "Set remote resource server address $REMOTE_RESOURCE."
    return 0
}

function action_set_subnet_address_prefix () {
    echo; info_msg "Type subnet address prefix"\
        "or ${MAGENTA}.back${RESET}."
    while :
    do
        SUBNET_PREFIX=`fetch_data_from_user "SubnetPrefix"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        set_subnet_address_prefix "$SUBNET_PREFIX"
        if [ $? -ne 0 ]; then
            warning_msg "Something went wrong."\
                "Could not set subnet address prefix"\
                "${RED}$SUBNET_PREFIX${RESET}."
            echo; continue
        fi
        break
    done
    echo; ok_msg "Successfully set subnet address prefix"\
        "${GREEN}$SUBNET_PREFIX${RESET}."

    action_journal_entry "Set subnet address prefix $SUBNET_PREFIX."
    return 0
}

function action_set_address_range_end () {
    echo; info_msg "Type final subnet address range octet"\
        "or ${MAGENTA}.back${RESET}."
    while :
    do
        END_OCTET=`fetch_data_from_user "LastOctet"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        set_address_range_end_octet "$END_OCTET"
        if [ $? -ne 0 ]; then
            warning_msg "Something went wrong."\
                "Could not set final subnet address range octet"\
                "${RED}$END_OCTET${RESET}."
            echo; continue
        fi
        break
    done
    echo; ok_msg "Successfully set final subnet address range octet"\
        "${GREEN}$END_OCTET${RESET}."

    action_journal_entry "Set final subnet address range octet $END_OCTET."
    return 0
}

function action_set_address_range_start () {
    echo; info_msg "Type first subnet address range octet"\
        "or ${MAGENTA}.back${RESET}."
    while :
    do
        START_OCTET=`fetch_data_from_user "FirstOctet"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        set_address_range_start_octet "$START_OCTET"
        if [ $? -ne 0 ]; then
            warning_msg "Something went wrong."\
                "Could not set first subnet address range octet"\
                "${RED}$START_OCTET${RESET}."
            echo; continue
        fi
        break
    done
    echo; ok_msg "Successfully set first subnet address range octet"\
        "${GREEN}$START_OCTET${RESET}."

    action_journal_entry "Set first subnet address range octet $START_OCTET."
    return 0
}

function action_install_full_clip_logic_sniper_dependencies () {
    echo; info_msg "About to install ${WHITE}${#APT_DEPENDENCIES[@]}${RESET}"\
        "${YELLOW}$SCRIPT_NAME${RESET} dependencies."
    ANSWER=`fetch_ultimatum_from_user \
        "Are you sure about this? ${YELLOW}Y/N${RESET}"`
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi

    check_safety_on
    if [ $? -eq 0 ]; then
        warning_msg "Safety is ${GREEN}ON${RESET}."\
            "Connection with wireless access point will not be performed."
        return 1
    fi

    echo; apt_install_full_clip_logic_sniper_dependencies
    if [ $? -ne 0 ]; then
        nok_msg "Software failure!"\
            "Could not install ${RED}$SCRIPT_NAME${RESET} dependencies."
        echo; return 1
    else
        ok_msg "${GREEN}$SCRIPT_NAME${RESET}"\
            "dependency installation complete."
    fi

    action_journal_entry "Installed $SCRIPT_NAME dependencies."
    echo; return $EXIT_CODE
}

function action_set_safety_off () {
    check_safety_off
    if [ $? -eq 0 ]; then
        echo; info_msg "Safety already is ${RED}OFF${RESET}."
        return 1
    fi

    echo; qa_msg "Taking off the training wheels. Are you sure about this?"
    fetch_ultimatum_from_user "${YELLOW}Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi

    set_logic_sniper_safety 'off'
    if [ $? -ne 0 ]; then
        echo; warning_msg "Something went wrong."\
            "Could not set ${YELLOW}Logic Sniper${RESET}"\
            "safety to ${RED}OFF${RESET}."
        return 2
    fi
    echo; ok_msg "Safety is ${RED}OFF${RESET}."
    action_journal_entry "Set safety OFF."
    return 0
}

function action_set_safety_on () {
    check_safety_on
    if [ $? -eq 0 ]; then
        echo; info_msg "Safety already is ${GREEN}ON${RESET}."
        return 1
    fi

    echo; qa_msg "Getting scared, are we?"
    fetch_ultimatum_from_user "${YELLOW}Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi

    set_logic_sniper_safety 'on'
    if [ $? -ne 0 ]; then
        echo; warning_msg "Something went wrong."\
            "Could not set ${YELLOW}Logic Sniper${RESET}"\
            "safety to ${GREEN}ON${RESET}."
        return 2
    fi
    echo; ok_msg "Safety is ${GREEN}ON${RESET}."
    action_journal_entry "Set safety ON."
    return 0
}

function action_display_user_action_journal_records () {
    display_action_journal_records
    if [ $? -ne 0 ]; then
        echo; warning_msg "Something went wrong."\
            "Could not display ${RED}Action Journal${RESET} entries."
        echo; return 1
    fi
    action_journal_entry "Displayed action journal records."
    return 0
}

function action_edit_user_action_journal () {
    edit_file "${DEFAULT['action-journal']}"
    if [ $? -ne 0 ]; then
        echo; warning_msg "Something went wrong."\
            "Could not edit ${RED}Action Journal${RESET}."
        echo; return 1
    fi
    echo; ok_msg "${GREEN}Action Journal${RESET} edited."
    action_journal_entry "Edited action journal entries."
    return 0
}

function action_clear_user_action_journal () {
    echo; info_msg "About to clear all ${YELLOW}Action Journal${RESET} entries."
    fetch_ultimatum_from_user "Are you sure about this? ${YELLOW}Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi
    clear_file "${DEFAULT['action-journal']}"
    if [ $? -ne 0 ]; then
        echo; warning_msg "Something went wrong."\
            "Could not clear ${RED}Action Journal${RESET} entries."
        return 2
    fi
    echo; ok_msg "${GREEN}Action Journal${RESET} entries cleared."
    action_journal_entry "Cleared action journal entries."
    return 0
}

function action_display_user_black_book_records () {
    display_black_book_journal_records
    if [ $? -ne 0 ]; then
        echo; warning_msg "Something went wrong."\
            "Could not display ${RED}Black Book${RESET} journal entries."
        echo; return 1
    fi
    action_journal_entry "Displayed black book journal records."
    return 0
}

function action_edit_user_black_book () {
    edit_file "${DEFAULT['black-book']}"
    if [ $? -ne 0 ]; then
        echo; warning_msg "Something went wrong."\
            "Could not edit ${RED}Black Book${RESET} journal."
        echo; return 1
    fi
    echo; ok_msg "${GREEN}Black Book${RESET} journal edited."
    action_journal_entry "Edited black book journal entries."
    return 0
}

function action_clear_user_black_book () {
    echo; warning_msg "Clearing ${YELLOW}Black Book${RESET} journal entries"\
        "${RED}does not undo changes to network${RESET}!"
    fetch_ultimatum_from_user "Are you sure about this? ${YELLOW}Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi
    clear_file "${DEFAULT['black-book']}"
    if [ $? -ne 0 ]; then
        echo; warning_msg "Something went wrong."\
            "Could not clear ${RED}Black Book${RESET} journal entries."
        return 2
    fi
    echo; ok_msg "${GREEN}Black Book${RESET} journal entries cleared."
    action_journal_entry "Cleared black book journal entries."
    return 0
}

# HANDLERS

# TODO
function handle_action_kick_machine_from_network () {
    WIRELESS_INTERFACE=`fetch_default_wireless_interface`
    if [ $? -ne 0 ]; then echo
        warning_msg "No default ${RED}wireless interface${RESET} found."
        qa_msg "Would you like to manually override and insert it?"
        fetch_ultimatum_from_user "${YELLOW}Y/N${RESET}"
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            return 1
        fi
        WIRELESS_INTERFACE=`fetch_wireless_interface_from_user "WiFiInterface"`
    else
        echo; ok_msg "Using default wireless interface"\
            "${GREEN}$WIRELESS_INTERFACE${RESET}."
    fi

    WIRELESS_CHANNEL=`fetch_default_wireless_gateway_channel`
    if [ $? -ne 0 ]; then echo
        warning_msg "No default ${RED}wireless channel number${RESET} found."
        qa_msg "Would you like to manually override and insert it?"
        fetch_ultimatum_from_user "${YELLOW}Y/N${RESET}"
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            return 1
        fi
        WIRELESS_CHANNEL=`fetch_wireless_gateway_channel_from_user "Channel#"`
    else
        ok_msg "Using default wireless channel"\
            "${GREEN}$WIRELESS_CHANNEL${RESET}."
    fi

    ROUTER_BSSID=`fetch_default_router_bssid`
    if [ $? -ne 0 ]; then echo
        warning_msg "No default ${RED}wireless router BSSID${RESET} found."
        qa_msg "Would you like to manually override and insert it?"
        fetch_ultimatum_from_user "${YELLOW}Y/N${RESET}"
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            return 1
        fi
        ROUTER_BSSID=`fetch_router_bssid_from_user "BSSID"`
    else
        ok_msg "Using default wireless router BSSID"\
            "${GREEN}$ROUTER_BSSID${RESET}."
    fi

    echo; info_msg "Type machine ${YELLOW}MAC address${RESET}"\
        "or ${MAGENTA}.back${RESET}."
    DEVICE_MAC_ADDRESS=`fetch_mac_address_from_user "MACAddress"`
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi

    action_kick_machine_off_network \
        "$WIRELESS_INTERFACE" $WIRELESS_CHANNEL \
        "$ROUTER_BSSID" "$DEVICE_MAC_ADDRESS"
    if [ $? -ne 0 ]; then
        warning_msg "Something went wrong."\
            "Could not kick machine ${RED}$DEVICE_MAC_ADDRESS${RESET}"\
            "from wireless network."
        return 5
    fi
    return 0
}

function handle_action_banner_grab () {
    while :
    do
        action_banner_grab
        EXIT_CODE=$?
        echo; fetch_ultimatum_from_user "Go again?"
        if [ $? -ne 0 ]; then
            break
        fi
    done
    return 0
}

function handle_action_scan_machine_ports () {
    init_port_scanner_controller
    return $?
}

function handle_action_scan_wireless_network () {
    action_scan_wireless_network
    return $?
}

function handle_action_display_user_action_journal_records () {
    check_file_has_number_of_lines "${DEFAULT['action-journal']}" 0
    if [ $? -eq 0 ]; then
        echo; warning_msg "${RED}User Action Journal${RESET}"\
            "has no registered record entries."
        return 1
    fi
    action_display_user_action_journal_records
    return $?
}

function handle_action_edit_user_action_journal () {
    action_edit_user_action_journal
    return $?
}

function handle_action_clear_user_action_journal () {
    action_clear_user_action_journal
    return $?
}

function handle_action_display_user_black_book_records () {
    check_file_has_number_of_lines "${DEFAULT['black-book']}" 0
    if [ $? -eq 0 ]; then
        echo; warning_msg "${RED}Black Book${RESET}"\
            "journal has no registered record entries."
        return 1
    fi
    action_display_user_black_book_records
    return $?
}

function handle_action_edit_user_black_book () {
    action_edit_user_black_book
    return $?
}

function handle_action_clear_user_black_book () {
    action_clear_user_black_book
    return $?
}

# CONTROLLERS

function port_scanner_controller () {
    OPTIONS=( 'Single Port' 'Port Range' 'All Ports' 'Back' )
    echo; symbol_msg "${BLUE}$SCRIPT_NAME${RESET}" \
        "${CYAN}Machine Port Scanner${RESET}"; echo
    select opt in "${OPTIONS[@]}"; do
        case "$opt" in
            'Single Port')
                action_scan_machine_single_port; break
                ;;
            'Port Range')
                action_scan_machine_port_range; break
                ;;
            'All Ports')
                action_scan_machine_all_ports; break
                ;;
            'Back')
                return 1
                ;;
            *)
                echo; warning_msg "Invalid option."
                continue
                ;;
        esac
    done
    return 0
}

function full_clip_logic_sniper_controller () {
    OPTIONS=(
        'Scan Wireless Network'
        'Scan Machine Ports'
        'Kick Machine From Network'
#       'Ban Machine From Network'
        'Banner Grab'
        'Back'
    )
    echo; symbol_msg "${BLUE}$SCRIPT_NAME${RESET}" \
        "${CYAN}Full Clip${RESET}"; echo
    select opt in "${OPTIONS[@]}"; do
        case "$opt" in
            'Scan Wireless Network')
                handle_action_scan_wireless_network; break
                ;;
            'Scan Machine Ports')
                handle_action_scan_machine_ports; break
                ;;
            'Kick Machine From Network')
                handle_action_kick_machine_from_network; break
                ;;
#           'Ban Machine From Network')
                # TODO - To be continued...
#               handle_action_ban_machine_from_network; break
#               ;;
            'Banner Grab')
                handle_action_banner_grab; break
                ;;
            'Back')
                return 1
                ;;
            *)
                warning_msg "Invalid option."; continue
                ;;
        esac
    done
    return 0
}

function wifi_commander_controller () {
    OPTIONS=(
        'Display Wireless Access Points'
        'Connect To Network Gateway'
        'Disconnect From Network Gateway'
        'Back'
    )
    echo; symbol_msg "${BLUE}$SCRIPT_NAME${RESET}" \
        "${CYAN}WiFi Commander${RESET}"; echo
    select opt in "${OPTIONS[@]}"; do
        case "$opt" in
            'Display Wireless Access Points')
                action_display_available_wireless_access_points; break
                ;;
            'Connect To Network Gateway')
                action_connect_to_wireless_access_point; break
                ;;
            'Disconnect From Network Gateway')
                action_disconnect_from_wireless_access_point; break
                ;;
            'Back')
                return 1
                ;;
            *)
                warning_msg "Invalid option."; continue
                ;;
        esac
    done
    return 0
}

function control_panel_controller () {
    OPTIONS=(
        "Set Sniper ${RED}Safety OFF${RESET}"
        "Set Sniper ${GREEN}Safety ON${RESET}"
        'Set Subnet Prefix'
        'Set Address Range Start'
        'Set Address Range End'
        'Set Remote Resource'
        'Set Black Book Journal'
        'Set Action Journal'
        'Set WPA Supplicant Conf'
        'Set WPA Supplicant Log'
        'Set DHCPCD Log'
        'Set Temporary File'
        'Set File Editor'
        'Install Dependencies'
        'Back'
    )
    echo; symbol_msg "${BLUE}$SCRIPT_NAME${RESET}" \
        "${CYAN}Control Panel${RESET}"
    display_full_clip_logic_sniper_settings
    select opt in "${OPTIONS[@]}"; do
        case "$opt" in
            "Set Sniper ${RED}Safety OFF${RESET}")
                action_set_safety_off; break
                ;;
            "Set Sniper ${GREEN}Safety ON${RESET}")
                action_set_safety_on; break
                ;;
            'Set Address Range Start')
                action_set_address_range_start; break
                ;;
            'Set Address Range End')
                action_set_address_range_end; break
                ;;
            'Set Subnet Prefix')
                action_set_subnet_address_prefix; break
                ;;
            'Set Remote Resource')
                action_set_remote_resource_server; break
                ;;
            'Set Black Book Journal')
                action_set_black_book_journal_file; break
                ;;
            'Set Action Journal')
                action_set_user_action_journal_file; break
                ;;
            'Set WPA Supplicant Conf')
                action_set_wpa_supplicant_configuration_file; break
                ;;
            'Set WPA Supplicant Log')
                action_set_wpa_supplicant_log_file; break
                ;;
            'Set DHCPCD Log')
                action_set_dhcpcd_log_file; break
                ;;
            'Set Temporary File')
                action_set_temporary_file; break
                ;;
            'Set File Editor')
                action_set_file_editor; break
                ;;
            'Install Dependencies')
                action_install_full_clip_logic_sniper_dependencies; break
                ;;
            'Back')
                return 1
                ;;
            *)
                echo; warning_msg "Invalid option."
                echo; continue
                ;;
        esac
    done
    return 0
}

function journal_user_actions_controller () {
    OPTIONS=(
        'Display Journal Records'
        'Edit Journal Records'
        'Clear Journal Records'
        'Back'
    )
    echo; symbol_msg "${BLUE}$SCRIPT_NAME${RESET}" \
        "${CYAN}Action Journal${RESET}"; echo
    ensure_user_action_journal
    if [ $? -ne 0 ]; then
        warning_msg "Something went wrong."\
            "Could not ensure ${RED}User Action Journal${RESET}."
        return 1
    fi
    select opt in "${OPTIONS[@]}"; do
        case "$opt" in
            'Display Journal Records')
                handle_action_display_user_action_journal_records; break
                ;;
            'Edit Journal Records')
                handle_action_edit_user_action_journal; break
                ;;
            'Clear Journal Records')
                handle_action_clear_user_action_journal; break
                ;;
            'Back')
                return 1
                ;;
            *)
                echo; warning_msg "Invalid option."
                echo; continue
                ;;
        esac
    done
    return 0
}

function journal_black_book_controller () {
    OPTIONS=(
        'Display Journal Records'
        'Edit Journal Records'
        'Clear Journal Records'
        'Back'
    )
    echo; symbol_msg "${BLUE}$SCRIPT_NAME${RESET}" \
        "${CYAN}Black Book Journal${RESET}"; echo
    ensure_user_black_book_journal
    if [ $? -ne 0 ]; then
        warning_msg "Something went wrong."\
            "Could not ensure ${RED}Black Book${RESET} journal."
        return 1
    fi
    select opt in "${OPTIONS[@]}"; do
        case "$opt" in
            'Display Journal Records')
                handle_action_display_user_black_book_records; break
                ;;
            'Edit Journal Records')
                handle_action_edit_user_black_book; break
                ;;
            'Clear Journal Records')
                handle_action_clear_user_black_book; break
                ;;
            'Back')
                return 1
                ;;
            *)
                echo; warning_msg "Invalid option."
                echo; continue
                ;;
        esac
    done
    return 0
}

function journal_controller () {
    OPTIONS=(
        'Black Book'
        'Action Journal'
        'Back'
    )
    echo; symbol_msg "${BLUE}$SCRIPT_NAME${RESET}" \
        "${CYAN}System User ${YELLOW}`whoami`${CYAN} Journals${RESET}"; echo
    select opt in "${OPTIONS[@]}"; do
        case "$opt" in
            'Black Book')
                init_journal_black_book_controller; break
                ;;
            'Action Journal')
                init_journal_user_actions_controller; break
                ;;
            'Back')
                return 1
                ;;
            *)
                echo; warning_msg "Invalid option."
                echo; continue
                ;;
        esac
    done
    return 0
}

function logic_sniper_main_controller () {
    OPTIONS=(
        'Logic Sniper'
        'WiFi Commander'
        'Control Panel'
        'Action Journals'
        'Back'
    )
    echo; symbol_msg "${BLUE}$SCRIPT_NAME${RESET}" \
        "${CYAN}Logical Division${RESET}"; echo
    select opt in "${OPTIONS[@]}"; do
        case "$opt" in
            'Logic Sniper')
                init_full_clip_logic_sniper_controller; break
                ;;
            'WiFi Commander')
                init_wifi_commander_controller; break
                ;;
            'Control Panel')
                init_control_panel_controller; break
                ;;
            'Action Journals')
                init_action_journal_controller; break
                ;;
            'Back')
                clear; ok_msg "Terminating"\
                    "${BLUE}$SCRIPT_NAME${RESET}."
                exit 0
                ;;
            *)
                echo; warning_msg "Invalid option."
                echo; continue
                ;;
        esac
    done
    return 0
}

# INIT

# [ NOTE ]: Controllers can return to init either 1 (break) or 0 (continue)

function init_port_scanner_controller () {
    while :
    do
        port_scanner_controller
        if [ $? -ne 0 ]; then
            break
        fi
    done
    return 0
}

function init_journal_black_book_controller () {
    while :
    do
        journal_black_book_controller
        if [ $? -ne 0 ]; then
            break
        fi
    done
    return 0
}

function init_journal_user_actions_controller () {
    while :
    do
        journal_user_actions_controller
        if [ $? -ne 0 ]; then
            break
        fi
    done
    return 0
}

function init_full_clip_logic_sniper_controller () {
    while :
    do
        full_clip_logic_sniper_controller
        if [ $? -ne 0 ]; then
            break
        fi
    done
    return 0
}

function init_wifi_commander_controller () {
    while :
    do
        wifi_commander_controller
        if [ $? -ne 0 ]; then
            break
        fi
    done
    return 0
}

function init_control_panel_controller () {
    while :
    do
        control_panel_controller
        if [ $? -ne 0 ]; then
            break
        fi
    done
    return 0
}

function init_action_journal_controller () {
    while :
    do
        journal_controller
        if [ $? -ne 0 ]; then
            break
        fi
    done
    return 0
}

function init_logic_sniper_main_controller () {
    if [[ "$INITIALIZATION_SUBROUTINE" == 'on' ]]; then
        echo; symbol_msg "${BLUE}$SCRIPT_NAME${RESET}" \
            "${CYAN}Executing initialization subroutine...${RESET}"
        logic_sniper_setup_subroutine
    fi
    while :
    do
        logic_sniper_main_controller
        if [ $? -ne 0 ]; then
            break
        fi
    done
    return 0
}

# CLEANERS

# DISPLAY

function display_available_wireless_access_points () {
    AVAILABLE_ESSID=`${AUTOMATION['wifi-commander']} \
        "$CONF_FILE_PATH" --show-ssid | sed 's/\"//g'`
    EXIT_CODE=$?
    echo "
${CYAN}Wireless Network Access Points${RESET}
$AVAILABLE_ESSID"
    return $EXIT_CODE
}

function display_full_clip_logic_sniper_settings () {
    case "$LOGIC_SNIPER_SAFETY" in
        'on')
            local DISPLAY_SAFETY="${GREEN}$LOGIC_SNIPER_SAFETY${RESET}"
            ;;
        'off')
            local DISPLAY_SAFETY="${RED}$LOGIC_SNIPER_SAFETY${RESET}"
            ;;
        *)
            local DISPLAY_SAFETY="$LOGIC_SNIPER_SAFETY"
            ;;
    esac
    if [ ! -z $CONNECTION_ESSID ]; then
        echo "
[ ${CYAN}Network ESSID${RESET}        ]: $CONNECTION_ESSID"
    else echo; fi
    echo "[ ${CYAN}Wireless Interface${RESET}   ]: $WIRELESS_INTERFACE
[ ${CYAN}Subnet Prefix${RESET}        ]: ${MAGENTA}$SUBNET_ADDRESS${RESET}
[ ${CYAN}Subnet Address Range${RESET} ]: ${WHITE}$START_ADDRESS_RANGE - $END_ADDRESS_RANGE${RESET}
[ ${CYAN}Remote Resource${RESET}      ]: ${MAGENTA}$REMOTE_RESOURCE${RESET}
[ ${CYAN}WPA Supplicant Conf${RESET}  ]: ${YELLOW}$WPA_SUPPLICANT_CONF_FILE${RESET}
[ ${CYAN}WPA Supplicant Log${RESET}   ]: ${YELLOW}$LOG_FILE_WPA_SUPPLICANT${RESET}
[ ${CYAN}DHCPCD Log${RESET}           ]: ${YELLOW}$LOG_FILE_DHCPCD${RESET}
[ ${CYAN}Temporary File${RESET}       ]: ${YELLOW}${DEFAULT['tmp-file']}${RESET}
[ ${CYAN}File Editor${RESET}          ]: ${DEFAULT['file-editor']}
[ ${CYAN}Sniper Safety${RESET}        ]: $DISPLAY_SAFETY" | column
    echo; return 0
#[ ${CYAN}Black Book${RESET}           ]: ${YELLOW}${DEFAULT['black-book']}${RESET}
#[ ${CYAN}Action Journal${RESET}       ]: ${YELLOW}${DEFAULT['action-journal']}${RESET}
}

function display_action_journal_records () {
    echo "
${CYAN}*  Action Journal - JOURNAL ENTRIES "\
"(${WHITE}`fetch_file_length ${DEFAULT['action-journal']}`${CYAN})  *${RESET}"
    local COUNT=1
    while read line; do
        echo "${WHITE}$COUNT${RESET}) $line"
        local COUNT=$((COUNT + 1))
    done < "${DEFAULT['action-journal']}"
    return 0
}

function display_black_book_journal_records () {
    echo "
${CYAN}*  Black Book - JOURNAL ENTRIES "\
"(${WHITE}`fetch_file_length ${DEFAULT['black-book']}`${CYAN})  *${RESET}"
    local COUNT=1
    while read line; do
        echo "${WHITE}$COUNT${RESET}) $line"
        local COUNT=$((COUNT + 1))
    done < "${DEFAULT['black-book']}"
    return 0
}

function display_file_content () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH" && cat "$FILE_PATH"
    return $?
}

# MISCELLANEOUS

if [ $EUID -ne 0 ]; then
    warning_msg "${RED}FC:LogicSniper${RESET} requiers elevated privileges."\
        "Are you root?"
    exit 1
fi

init_logic_sniper_main_controller


# CODE DUMP

