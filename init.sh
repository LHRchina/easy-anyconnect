#!/bin/bash
USERNAME=""
PASSWORD=""
SECRET_KEY=""
VPN_URL=""
VPN_BIN="/opt/cisco/secureclient/bin/vpn"
ANYCONNECT_PATH="/Applications/Cisco/Cisco Secure Client.app"

get_anyclient_ui_pid() {
    local pid=$(ps -ef | grep "$ANYCONNECT_PATH" | grep -v 'grep' | awk '{print $2}')
    echo $pid

    if [[ -z "$pid" ]]; then
        return 1
    else
        return 0
    fi
}

kill_anyconnect_ui() {
    $VPN_BIN disconnect
    local pid=$(get_anyclient_ui_pid)
    # echo "PID: $pid"

    if [[ -n "$pid" ]]; then
        kill -9 $pid
    fi
}

open_client_ui() {
    if ! get_anyclient_ui_pid &> /dev/zero; then
        open "$ANYCONNECT_PATH"
    fi
}

get_google_auth_code() {
    python3 - <<EOF
import pyotp
secret_key = "$SECRET_KEY"
totp = pyotp.TOTP(secret_key)
print(totp.now())
EOF
}

connect() {
    kill_anyconnect_ui
    echo $USERNAME
    echo $PASSWORD

    # Get the Google Authenticator code
    PASSWORD2=$(get_google_auth_code)
    echo $PASSWORD2

    $VPN_BIN -s connect $VPN_URL << EOF

$PASSWORD$PASSWORD2
EOF

    open_client_ui
}

main() {
    case "$1" in
        stop|s )
            $VPN_BIN disconnect
            ;;
        * )
            connect
    esac
}

main "$*"
