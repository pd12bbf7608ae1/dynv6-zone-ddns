#!/bin/sh
get_local_ipv4(){
    # echo hello
    case ${1} in
        "curl")
            local bin="curl -4fsS"
        ;;
        "wget")
            local bin="wget -O- -4"
        ;;
        *)
            echo "Error command_type"
            rm $history_file
            exit 1
        ;;
    esac
    $bin "http://ip-api.com/json/?fields=query" 2>/dev/null | cut -d ":" -f 2 | sed -e "s/[\"}]//g"
}

get_local_ipv6(){
    local devices=$1
    ip -6 addr list scope global $device | grep -v " fd" | sed -n 's/.*inet6 \([0-9a-f:]\+\).*/\1/p' | head -n 1
}


get_linux_ipv4(){
    local user=$1
    local password=$2
    local ip=$3
    local port=$4
    local login_type=$5
    local bin_type=$6

    case $login_type in
        "key")
            if [ -r "$key" ]; then
                local connect="ssh ${user}@${ip} -p $port -i"
            else
                local connect="ssh ${user}@${ip} -p $port"
            fi
        ;;
        "password")
            local connect="sshpass -p $password ssh ${user}@${ip} -p $port"
        ;;
        *)
            echo "Error login_type" 1>&2
            rm $history_file
            exit 1
        ;;
    esac
    case $bin_type in
        "curl")
            local bin="curl -4fsS http://ip-api.com/json/?fields=query 2>/dev/null"
        ;;
        "wget")
            local bin="wget -4 -O- http://ip-api.com/json/?fields=query 2>/dev/null"
        ;;
        *)
            echo "Error command_type"
            rm $history_file
            exit 1
        ;;
    esac

    $connect "$key" $bin | cut -d ":" -f 2 | sed -e "s/[\"}]//g"

}


get_linux_ipv6(){
    local user=$1
    local password=$2
    local ip=$3
    local port=$4
    local login_type=$5
    local device=$6
    case $login_type in
        "key")
            if [ -r "$key" ]; then
                local connect="ssh ${user}@${ip} -p $port -i"
            else
                local connect="ssh ${user}@${ip} -p $port"
            fi
        ;;
        "password")
            local connect="sshpass -p $password ssh ${user}@${ip} -p $port"
        ;;
        *)
            echo "Error login_type" 1>&2
            rm $history_file
            exit 1
        ;;
    esac
    local bin="ip -6 addr list scope global $device"
    $connect "$key" $bin | grep -v " fd" | sed -n 's/.*inet6 \([0-9a-f:]\+\).*/\1/p' | head -n 1
}


get_windows_ipv4(){
    local user=$1
    local password=$2
    local ip=$3
    local port=$4
    local login_type=$5
    local bin_type=$6
    case $login_type in
        "key")
            if [ -r "$key" ]; then
                local connect="ssh ${user}@${ip} -p $port -i"
            else
                local connect="ssh ${user}@${ip} -p $port"
            fi
        ;;
        "password")
            local connect="sshpass -p $password ssh ${user}@${ip} -p $port"
        ;;
        *)
            echo "Error login_type" 1>&2
            rm $history_file
            exit 1
        ;;
    esac

    case $bin_type in
        "curl")
            local bin="curl -4fsS http://ip-api.com/json/?fields=query"
        ;;
        "wget")
            local bin="wget -4 -O- -q http://ip-api.com/json/?fields=query"
        ;;
        *)
            echo "Error command_type"
            rm $history_file
            exit 1
        ;;
    esac
    $connect "$key" $bin | cut -d ":" -f 2 | sed -e "s/[\"}]//g"
}


get_windows_ipv6(){
    local user=$1
    local password=$2
    local ip=$3
    local port=$4
    local login_type=$5
    local device=$6
    case $login_type in
        "key")
            if [ -r "$key" ]; then
                local connect="ssh ${user}@${ip} -p $port -i"
            else
                local connect="ssh ${user}@${ip} -p $port"
            fi
        ;;
        "password")
            local connect="sshpass -p $password ssh ${user}@${ip} -p $port"
        ;;
        *)
            echo "Error login_type" 1>&2
            rm $history_file
            exit 1
        ;;
    esac

    info=$($connect "$key" "chcp 437 & ipconfig /all")
    
    if [ -z "$device" ]; then
        echo "$info" | sed -e "s/^[[:alnum:]].*//g" -e "s/^[[:blank:]]*//g" | grep "Preferred" | grep "IPv6 Address" | grep -v "Link-local" | sed -n -e "1p" | sed -e "s/^.*: //g" -e "s/(.*)//g" -e "s/[[:blank:]]*//g" -e "s/\r//g"
    else
        temp=$(echo "$info" | grep "^[[:alnum:]]" -n | grep "${device}:" -A 1)
        local device_start=$(echo "$temp" | sed -n -e "1p" | cut -d ":" -f 1)
        local device_end=$(($(echo "$temp" | sed -n -e "2p" | cut -d ":" -f 1)-1))
        unset temp
        if [ -z "$device_start" ]; then
            echo "No device found!" 1>&2
        else
            test "$device_end" = "-1" && device_end=$(echo "$info" | wc -l)
            echo "$info" | sed -n -e "$(($device_start+1)),$device_end p" | sed -e "s/^[[:blank:]]*//g" | grep "Preferred" | grep "IPv6 Address" | grep -v "Link-local" | sed -n -e "1p" | sed -e "s/^.*: //g" -e "s/(.*)//g" -e "s/[[:blank:]]*//g" -e "s/\r//g"
        fi
    fi
}


get_esxi_ipv4(){
    local user=$1
    local password=$2
    local ip=$3
    local port=$4
    local login_type=$5

    case $login_type in
        "key")
            if [ -r "$key" ]; then
                local connect="ssh ${user}@${ip} -p $port -i"
            else
                local connect="ssh ${user}@${ip} -p $port"
            fi
        ;;
        "password")
            local connect="sshpass -p $password ssh ${user}@${ip} -p $port"
        ;;
        *)
            echo "Error login_type" 1>&2
            rm $history_file
            exit 1
        ;;
    esac

    local bin="wget -O- http://ip-api.com/json/?fields=query 2>/dev/null"
    $connect "$key" $bin | cut -d ":" -f 2 | sed -e "s/[\"}]//g"
}


get_esxi_ipv6(){
    local user=$1
    local password=$2
    local ip=$3
    local port=$4
    local login_type=$5
    local device=$6
    case $login_type in
        "key")
            if [ -r "$key" ]; then
                local connect="ssh ${user}@${ip} -p $port -i"
            else
                local connect="ssh ${user}@${ip} -p $port"
            fi
        ;;
        "password")
            local connect="sshpass -p $password ssh ${user}@${ip} -p $port"
        ;;
        *)
            echo "Error login_type" 1>&2
            rm $history_file
            exit 1
        ;;
    esac
    info=$($connect "$key" "esxcli network ip interface ipv6 address list")
    if [ -z "$device" ]; then
        echo "$info" | grep "PREFERRED" | grep -v "[[:blank:]]fe" | sed -n "1p" | awk '{printf $2 "\n"}'
    else
        device_info=$(echo "$info" | grep "^$device" || echo "")
        if [ -z "$device_info" ]; then
            echo "No device found!" 1>&2
        else
            echo "$device_info" | grep "PREFERRED" | grep -v "[[:blank:]]fe" | sed -n "1p" | awk '{printf $2 "\n"}'
        fi
    fi
}

zone_ipv4_update(){
    if [ -r "$dynv6_key" ]; then
        ssh api@$dynv6_server -i "$dynv6_key" "hosts $common_zone set ipv4addr $zone_ipv4"
    else
        ssh api@$dynv6_server "hosts $common_zone set ipv4addr $zone_ipv4"
    fi
    
}
zone_ipv6_update(){
    if [ -r "$dynv6_key" ]; then
        ssh api@$dynv6_server -i "$dynv6_key" "hosts $common_zone set ipv6addr $zone_ipv6"
    else
        ssh api@$dynv6_server "hosts $common_zone set ipv6addr $zone_ipv6"
    fi
    # echo "v6 Update disable"
}


host_ipv4_update(){
    if [ -r "$dynv6_key" ]; then
        ssh api@$dynv6_server -i "$dynv6_key" "hosts $common_zone records set $1 a addr $2"
    else
        ssh api@$dynv6_server "hosts $common_zone records set $1 a addr $2"
    fi
    # echo "v4 Update disable"
}

host_ipv6_update(){
    if [ -r "$dynv6_key" ]; then
        ssh api@$dynv6_server -i "$dynv6_key" "hosts $common_zone records set $1 aaaa addr $2"
    else
        ssh api@$dynv6_server "hosts $common_zone records set $1 aaaa addr $2"
    fi
    # echo "v6 Update disable"
}

if [ "$1" = "-h" ]; then
    echo "Print Help"
    exit 0
fi

if [ -f "$1" ];then
    configfile="$1"
else
    if [ -f "$PWD/ddns.conf" ]; then
        configfile="$PWD/ddns.conf"
        # echo pwd
        else
        if [ -f "$HOME/ddns.conf" ]; then
            configfile="$HOME/ddns.conf"
            # echo home
            else
            if [ -f "/etc/ddns.conf" ]; then
                configfile="/etc/ddns.conf"
                # echo etc
                else
                echo "No File"
                exit 1
            fi
        fi
    fi
fi

config=$(cat $configfile | sed -e "s/^[[:blank:]]*//g" -e "s/^#.*//g" -e "/^$/d")


common_start=$(echo "$config" | grep "^\[common\]" -n | cut -d ":" -f 1)
if [ -z "$common_start" ]; then
    echo "No common setting."
    exit 1
fi

common_end=$(($(echo "$config" | grep "^\[" -n | sed -e "2p" -n | cut -d ":" -f 1)-1))
if [ "$common_end" -eq "-1" ]; then
    common_end=$(echo "$config" | wc -l)
fi

common_config=$(echo "$config" | sed -n -e "$common_start,$common_end p")


dynv6_server=$(echo "$common_config" | grep "^dynv6_server" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
dynv6_key=$(echo "$common_config" | grep "^dynv6_key" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
history_file=$(echo "$common_config" | grep "^history_file" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
test -z "$history_file" && history_file="$HOME/.iphistory.log"
if [ ! -e "$history_file" ]; then
    touch "$history_file"
    if [ "$?" -ne "0" ]; then
        echo "Cannot create history file"
        exit 1
    fi
    echo "$(echo 'Config file status:')$(ls -l $configfile)" > "$history_file"
    echo "Create new history file"
    empty_flag=1
else
    configfile_status_record=$(cat "$history_file" | grep "Config file status:" | sed -e "s/Config file status://g")
    configfile_status=$(ls -l $configfile) 
    finish_flag=$(cat "$history_file" | grep -c "iphistory finish")
    if [ "$configfile_status_record" = "$configfile_status" -a "$finish_flag" = "1" ]; then
        empty_flag=0
    else
        echo "$(echo 'Config file status:')$(ls -l $configfile)" > "$history_file"
        echo "Create new history file"
        empty_flag=1
    fi
fi

common_zone=$(echo "$common_config" | grep "^zone" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
common_type=$(echo "$common_config" | grep "^type" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
common_devices=$(echo "$common_config" | grep "^devices" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
common_use_ipv6=$(echo "$common_config" | grep "^use_ipv6" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
common_use_ipv4=$(echo "$common_config" | grep "^use_ipv4" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
common_command_type=$(echo "$common_config" | grep "^command_type" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
common_login_type=$(echo "$common_config" | grep "^login_type" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
common_ip=$(echo "$common_config" | grep "^ip" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
common_port=$(echo "$common_config" | grep "^port" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
test -z "$common_port" && common_port="22"
common_key=$(echo "$common_config" | grep "^key" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
common_user=$(echo "$common_config" | grep "^user" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
test -z "$common_user" && common_user="$USER"
common_password=$(echo "$common_config" | grep "^password" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
test -z "$common_password" && common_password="null"

echo "--------------------------------"
echo "ddns log at $(date)"
echo "zone update begin:"

key="$common_key"
case "$common_use_ipv4" in
    "true")
    case "$common_type" in
        "local")
            zone_ipv4=$(get_local_ipv4 "$common_command_type")
            echo "zone local ipv4 $zone_ipv4"
        ;;
        "linux")
            ping -c 2 $common_ip > /dev/null
            if [ "$?" = "0" ]; then
                zone_ipv4=$(get_linux_ipv4 "$common_user" "$common_password" "$common_ip" "$common_port" "$common_login_type" "$common_command_type")
                echo "zone linux ipv4 $zone_ipv4"
            else
                zone_ipv4=""
                echo "zone linux offline"
            fi
        ;;
        "windows")
            ping -c 2 $common_ip > /dev/null
            if [ "$?" = "0" ]; then
                zone_ipv4=$(get_windows_ipv4 "$common_user" "$common_password" "$common_ip" "$common_port" "$common_login_type" "$common_command_type")
                echo "zone windows ipv4 $zone_ipv4"
            else
                zone_ipv4=""
                echo "zone windows offline"
            fi
        ;;
        "esxi")
            ping -c 2 $common_ip > /dev/null
            if [ "$?" = "0" ]; then
                zone_ipv4=$(get_esxi_ipv4 "$common_user" "$common_password" "$common_ip" "$common_port" "$common_login_type")
                echo "zone esxi ipv4 $zone_ipv4"
            else
                zone_ipv4=""
                echo "zone esxi offline"
            fi
        ;;
        "null")
            zone_ipv4=""
            echo "zone null!"
        ;;
        *)
            echo "Unknow zone type!"
            rm "$history_file"
            exit 1
        ;;
    esac
    ;;
    "false")
        zone_ipv4=""
    ;;
    *)
        echo "common_use_ipv4 error"
        rm "$history_file"
        exit 1
    ;;
esac

case "$common_use_ipv6" in
    "true")
    case "$common_type" in
        "local")
            zone_ipv6=$(get_local_ipv6 "$common_devices")
            echo "zone local ipv6 $zone_ipv6"
        ;;
        "linux")
            ping -c 2 $common_ip > /dev/null
            if [ "$?" = "0" ]; then
                zone_ipv6=$(get_linux_ipv6 "$common_user" "$common_password" "$common_ip" "$common_port" "$common_login_type" "$common_devices")
                echo "zone linux ipv6 $zone_ipv6"
            else
                zone_ipv6=""
                echo "zone linux offline"
            fi
        ;;
        "windows")
            ping -c 2 $common_ip > /dev/null
            if [ "$?" = "0" ]; then
                zone_ipv6=$(get_windows_ipv6 "$common_user" "$common_password" "$common_ip" "$common_port" "$common_login_type" "$common_devices")
                echo "zone windows ipv6 $zone_ipv6"
            else
                zone_ipv6=""
                echo "zone windows offline"
            fi
        ;;
        "esxi")
            ping -c 2 $common_ip > /dev/null
            if [ "$?" = "0" ]; then
                zone_ipv6=$(get_esxi_ipv6 "$common_user" "$common_password" "$common_ip" "$common_port" "$common_login_type" "$common_devices")
                echo "zone esxi ipv6 $zone_ipv6"
            else
                zone_ipv6=""
                echo "zone esxi offline"
            fi
        ;;
        "null")
            zone_ipv6=""
            echo "zone null!"
        ;;
        *)
            echo "Unknow zone type!"
            rm "$history_file"
            exit 1
        ;;
    esac
    ;;
    "false")
        zone_ipv6=""
    ;;
    *)
        echo "common_use_ipv6 error type"
        rm "$history_file"
        exit 1
    ;;
esac
unset key


if [ "$empty_flag" = "1" ]; then
    if [ -n "$zone_ipv4" ]; then
        zone_ipv4_update
        if [ "$?" -ne "0" ]; then
            echo "zone_ipv4_update ssh connection error!"
            zone_ipv4_log=""
        else
            zone_ipv4_log="$zone_ipv4"
        fi
    fi
    if [ -n "$zone_ipv6" ]; then
        zone_ipv6_update
        if [ "$?" -ne "0" ]; then
            echo "zone_ipv6_update ssh connection error!"
            zone_ipv6_log=""
        else
            zone_ipv6_log="$zone_ipv6"
        fi
    fi
    echo "zone $zone_ipv4_log $zone_ipv6_log" >> "$history_file"
else
    ip_history=$(cat "$history_file" | grep "^zone")
    zone_ipv4_history=$(echo "$ip_history" | cut -d " " -f 2)
    zone_ipv6_history=$(echo "$ip_history" | cut -d " " -f 3)
    unset ip_history
    if [ -n "$zone_ipv4" ]; then
        test "$zone_ipv4" = "$zone_ipv4_history" || zone_ipv4_update
        if [ "$?" -ne "0" ]; then
            echo "zone_ipv4_update ssh connection error!"
            zone_ipv4_log="$zone_ipv4_history"
        else
            update_flag=1
            zone_ipv4_log="$zone_ipv4"
        fi
    else
        zone_ipv4=$zone_ipv4_history
    fi

    if [ -n "$zone_ipv6" ]; then
        test "$zone_ipv6" = "$zone_ipv6_history" || zone_ipv6_update
        if [ "$?" -ne "0" ]; then
            echo "zone_ipv6_update ssh connection error!"
            zone_ipv6_log="$zone_ipv6_history"
        else
            update_flag=1
            zone_ipv6_log="$zone_ipv6"
        fi
    else
        zone_ipv6=$zone_ipv6_history
    fi
    test "$update_flag" = "1" && sed -i "s/^zone.*/zone $zone_ipv4_log $zone_ipv6_log/g" $history_file
    unset update_flag zone_ipv6_history zone_ipv4_history
fi
unset zone_ipv4_log zone_ipv6_log
echo "zone update end."
echo ""

host_mark=$(echo "$config" | grep "^\[.*\]" -n | grep -v "common")
host_number=$(echo "$host_mark" | grep -c "\[.*\]")
echo "host_number=$host_number"

i=1
while [ "$i" -le "$host_number" ]
do
    host_start=$(echo "$host_mark" | sed -n -e "${i}p" | cut -d ":" -f 1)
    host_end=$(echo "$host_mark" | sed -n -e "$(($i+1))p" | cut -d ":" -f 1)
    host_end=$(($host_end-1))
    test "$host_end" -eq "-1" && host_end=$(echo "$config" | wc -l)
    host_config=$(echo "$config" | sed -n -e "$host_start,$host_end p")
    echo "host#$i update begin:"

    host_name=$(echo "$host_config" | grep "^name" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
    test -z "$host_name" && host_name="host$i"
    host_use_ipv6=$(echo "$host_config" | grep "^use_ipv6" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
    host_use_zone_ipv6=$(echo "$host_config" | grep "^use_zone_ipv6" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
    host_use_ipv4=$(echo "$host_config" | grep "^use_ipv4" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
    host_use_zone_ipv4=$(echo "$host_config" | grep "^use_zone_ipv4" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
    host_type=$(echo "$host_config" | grep "^type" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
    host_command_type=$(echo "$host_config" | grep "^command_type" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
    host_device=$(echo "$host_config" | grep "^devices" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
    host_login_type=$(echo "$host_config" | grep "^login_type" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
    host_ip=$(echo "$host_config" | grep "^ip" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
    host_port=$(echo "$host_config" | grep "^port" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
    test -z "$host_port" && host_port="22"
    host_key=$(echo "$host_config" | grep "^key" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
    host_user=$(echo "$host_config" | grep "^user" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
    test -z "$host_user" && host_user="$USER"
    host_password=$(echo "$host_config" | grep "^password" | sed -e "s/^[[:alnum:]_[:blank:]]*=//g" -e "s/^[[:blank:]]*//g")
    test -z "$host_password" && host_password="null"

    key="$host_key"
    case "$host_use_ipv4" in
        "true")
        case "$host_use_zone_ipv4" in
            "true")
                host_ipv4=$zone_ipv4
                echo "host#$i use zone ipv4 $host_ipv4"
            ;;
            "false")
                case "$host_type" in
                "local")
                    host_ipv4=$(get_local_ipv4 "$host_command_type")
                    echo "host#$i local ipv4 $host_ipv4"
                ;;
                "linux")
                    ping -c 2 $host_ip > /dev/null
                    if [ "$?" = "0" ]; then
                        host_ipv4=$(get_linux_ipv4 "$host_user" "$host_password" "$host_ip" "$host_port" "$host_login_type" "$host_command_type")
                        echo "host#$i linux ipv4 $host_ipv4"
                    else
                        host_ipv4=""
                        echo "host#$i linux offline"
                    fi
                ;;
                "windows")
                    ping -c 2 $host_ip > /dev/null
                    if [ "$?" = "0" ]; then
                        host_ipv4=$(get_windows_ipv4 "$host_user" "$host_password" "$host_ip" "$host_port" "$host_login_type" "$host_command_type")
                        echo "host#$i windows ipv4 $host_ipv4"
                    else
                        host_ipv4=""
                        echo "host#$i windows offline"
                    fi
                ;;
                "esxi")
                    ping -c 2 $host_ip > /dev/null
                    if [ "$?" = "0" ]; then
                        host_ipv4=$(get_esxi_ipv4 "$host_user" "$host_password" "$host_ip" "$host_port" "$host_login_type")
                        echo "host#$i esxi ipv4 $host_ipv4"
                    else
                        host_ipv4=""
                        echo "host#$i esxi offline"
                    fi
                ;;
                "null")
                    host_ipv4=""
                    echo "host#$i null!"
                ;;
                *)
                    echo "Unknow host#$i type!"
                    rm "$history_file"
                    exit 1
                ;;
                esac
            ;;
            *)
                echo "host#$i use_zone_ipv4 error type"
                rm "$history_file"
                exit 1
            ;;

        esac
        ;;

        "false")
            host_ipv4=""
        ;;

        *)
            echo "host$i use_ipv4 error type"
            rm "$history_file"
            exit 1
        ;;
    esac

    case "$host_use_ipv6" in
        "true")
        case "$host_use_zone_ipv6" in
            "true")
                host_ipv6=$zone_ipv6
                echo "host#$i use zone ipv6 $host_ipv6"
            ;;
            "false")
                case "$host_type" in
                "local")
                    host_ipv6=$(get_local_ipv6 "$host_devices")
                    echo "host#$i local ipv6 $host_ipv6"
                ;;
                "linux")
                    ping -c 2 $host_ip > /dev/null
                    if [ "$?" = "0" ]; then
                        host_ipv6=$(get_linux_ipv6 "$host_user" "$host_password" "$host_ip" "$host_port" "$host_login_type" "$host_devices")
                        echo "host#$i linux ipv6 $host_ipv6"
                    else
                        host_ipv6=""
                        echo "host#$i linux offline"
                    fi
                ;;
                "windows")
                    ping -c 2 $host_ip > /dev/null
                    if [ "$?" = "0" ]; then
                        host_ipv6=$(get_windows_ipv6 "$host_user" "$host_password" "$host_ip" "$host_port" "$host_login_type" "$host_devices")
                        echo "host#$i windows ipv6 $host_ipv6"
                    else
                        host_ipv6=""
                        echo "host#$i windows offline"
                    fi
                ;;
                "esxi")
                    ping -c 2 $host_ip > /dev/null
                    if [ "$?" = "0" ]; then
                        host_ipv6=$(get_esxi_ipv6 "$host_user" "$host_password" "$host_ip" "$host_port" "$host_login_type" "$host_devices")
                        echo "host#$i esxi ipv6 $host_ipv6"
                    else
                        host_ipv6=""
                        echo "host#$i esxi offline"
                    fi
                ;;
                "null")
                    host_ipv6=""
                    echo "host#$i null!"
                ;;
                *)
                    echo "Unknow host#$i type!"
                    rm "$history_file"
                    exit 1
                ;;
                esac
            ;;
            *)
                echo "host#$i use_zone_ipv6 error type"
                rm "$history_file"
                exit 1
            ;;

        esac
        ;;
        "false")
            host_ipv6=""
        ;;

        *)
            echo "host$i use_ipv6 error type"
            rm "$history_file"
            exit 1
        ;;
    esac
    unset key
    
    if [ "$empty_flag" = "1" ]; then
        if [ -n "$host_ipv4" ]; then
            host_ipv4_update $host_name $host_ipv4
            if [ "$?" -ne "0" ]; then
                echo "host#${i}_ipv4_update ssh connection error!"
                host_ipv4_log=""
            else
                host_ipv4_log="$host_ipv4"
            fi
        fi
        if [ -n "$host_ipv6" ]; then
            host_ipv6_update $host_name $host_ipv6
            if [ "$?" -ne "0" ]; then
                echo "host#${i}_ipv6_update ssh connection error!"
                host_ipv6_log=""
            else
                host_ipv6_log="$host_ipv6"
            fi
        fi
        echo "host#$i $host_ipv4_log $host_ipv6_log" >> "$history_file"
    else
        ip_history=$(cat "$history_file" | grep "^host#$i")
        host_ipv4_history=$(echo "$ip_history" | cut -d " " -f 2)
        host_ipv6_history=$(echo "$ip_history" | cut -d " " -f 3)
        unset ip_history
    
        if [ -n "$host_ipv4" ]; then
            test "$host_ipv4" = "$host_ipv4_history" || host_ipv4_update $host_name $host_ipv4
            if [ "$?" -ne "0" ]; then
                echo "host#${i}_ipv4_update ssh connection error!"
                host_ipv4_log="$host_ipv4_history"
            else
                update_flag=1
                host_ipv4_log="$host_ipv4"
            fi
        else
            host_ipv4=$host_ipv4_history
        fi

        if [ -n "$host_ipv6" ]; then
            test "$host_ipv6" = "$host_ipv6_history" || host_ipv6_update $host_name $host_ipv6
            if [ "$?" -ne "0" ]; then
                echo "host#${i}_ipv6_update ssh connection error!"
                host_ipv6_log="$host_ipv6_history"
            else
                update_flag=1
                host_ipv6_log="$host_ipv6"
            fi
        else 
            host_ipv6=$host_ipv6_history
        fi
        test "$update_flag" = "1" && sed -i "s/^host#${i}.*/host#${i} $host_ipv4 $host_ipv6/g" "$history_file"
        unset host_ipv4_history host_ipv6_history
    fi
    unset host_ipv4_log host_ipv6_log
    
    echo "host#$i update end."
    echo ""
    i=$(($i+1))
done
test "$empty_flag" = "1" && echo "iphistory finish" >> "$history_file"
unset i
echo "ddns program finish at $(date)"
