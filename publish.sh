#!/bin/bash

SCRIPT_NAME=$(basename "$0")
SCRIPTS_FOLDER=$(dirname "$0")
PROJECT_ROOT=$SCRIPTS_FOLDER/../../

if [[ ! -e "$PROJECT_ROOT/.gitignore" ]]; then
    printf "E: %s is not the project root.\n" "$PROJECT_ROOT" >&2;
    exit 1
fi

function usage(){
    echo "$SCRIPT_NAME"
    echo "Builds the mdBook and publishes it to your server."
    echo
    echo "Usage:"
    echo "    $SCRIPT_NAME --hostname [HOSTNAME] --scp-loc [SCP_LOCATION]"
    echo
    echo "Arguments:"
    echo "    --hostname: Either the hostname or IP address of the remote server"
    echo "    --scp-loc:  This is typically going to be NGINX_ROOT/kb"
    exit 1
}

function confirm() {
    while true
    do
        read -p "$* (y/n): " -n 1 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        elif [[ $REPLY =~ ^[Nn]$ ]]; then
            exit 1
        fi
    done
}

HOSTNAME=
SCP_LOCATION=
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        --hostname)
            [[ -n "$HOSTNAME" ]] && usage
            HOSTNAME="$2"
            shift
            shift
            ;;
        -s|--scp-loc)
            [[ -n "$SCP_LOCATION" ]] && usage
            echo "$2"
            SCP_LOCATION="$2"
            shift
            shift
            ;;
        *)
            usage
    esac
done

[[ -z "$SCP_LOCATION" ]] && usage
[[ -z "$HOSTNAME" ]] && usage
if [[ "${SCP_LOCATION:(-3)}" != "/kb" ]]; then
  echo
  echo "SCP_LOCATION is not a folder named 'kb'!"
  echo "This could be fine, but dangerous to continue since we run a rm command on the SCP_LOCATION."
  echo "If you intended to do this, do so manually."
  echo
  exit 1
fi

echo
echo "This will overwrite the files for the mdBook on your server."
echo
confirm "Proceed?"
echo

mdbook build
ssh "$HOSTNAME" "rm $SCP_LOCATION/*.html"
ssh "$HOSTNAME" "rm $SCP_LOCATION/searchindex.js"
ssh "$HOSTNAME" "rm $SCP_LOCATION/searchindex.json"
scp book/*.html "$HOSTNAME:$SCP_LOCATION"
scp book/searchindex.js "$HOSTNAME:$SCP_LOCATION"
scp book/searchindex.json "$HOSTNAME:$SCP_LOCATION"
