#!/bin/bash

function displaytime {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  (( $D > 0 )) && printf '%d days ' $D
  (( $H > 0 )) && printf '%d hours ' $H
  (( $M > 0 )) && printf '%d minutes ' $M
  (( $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
  printf '%d seconds\n' $S
}

#
# Log function
function log {
    # Set default loglevel to INFO
    if [ -z "$2" ]; then
        loglevel=INFO
        message=$1
    else
        loglevel=$(echo $1 | tr [a-z] [A-Z])
        message=$2
    fi

    # Log so stderr in case of ERROR or FATAL
    if [ "$loglevel" = "ERROR" -o "$loglevel" = "FATAL" ]; then
        printf "%s %-6s %s\n" "$(date)" "${loglevel}" "${message}" >&2
    else
        printf "%s %-6s %s\n" "$(date)" "${loglevel}" "${message}"
    fi
}

#
# Usage function
function usage {
    echo "Usage: $0 --source=/path/to/release-source.json --manifest=/path/to/release-manifest.json"
}

# Set defaults
# Nothing

for i in "$@"; do
    case $i in
        -s=*|--source=*)
        SOURCE="${i#*=}"
        shift # past argument=value
        ;;
        -m=*|--manifest=*)
        MANIFEST="${i#*=}"
        shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [ -z "$SOURCE" -o ! -f "$SOURCE" ]; then
    log ERROR "You need to specify a valid path to the release source JSON file."
    log WARN "$(usage)"
    log WARN "Exit process with error code 100."
    exit 100
fi

if [ -z "$MANIFEST" -o ! -f "$MANIFEST" ]; then
    log ERROR "You need to specify a valid path to the release manifest JSON file."
    log WARN "$(usage)"
    log WARN "Exit process with error code 102."
    exit 102
fi

#
# Download the release from source
RELEASE_SOURCE_TYPE=$(cat $SOURCE | jq -r '.endpoint.type')
RELEASE_TEMP_LOCATION=./tmp

# Extract the base url for S3
BASE_URL="$(cat $SOURCE | jq -r '.endpoint.base_url')"

# Only handling "local" now, hence we assume we are in pipeline mode.
for ARTEFACT_NAME in $(cat $MANIFEST | jq -r '.artefacts.artefact[].name'); do
    ARTEFACT_VERSION=$(cat $MANIFEST | jq -r '.artefacts.artefact[] | select(.name == "'$ARTEFACT_NAME'") | .version')
    case $RELEASE_SOURCE_TYPE in
        s3)
            if [ -z "$AWS_ACCESS_KEY_ID" -o -z "$AWS_SECRET_ACCESS_KEY" ]; then
                log ERROR "AWS Access or Secret keys not found in environment, exit."
                log WARN "Exit process with error code 202."
                exit 202
            else
                aws s3 cp $BASE_URL/$ARTEFACT_NAME/$ARTEFACT_VERSION $RELEASE_TEMP_LOCATION --recursive
            fi
        ;;
        *)
            log ERROR "Unkown source type $RELEASE_SOURCE_TYPE specified."
            log WARN "Exit process with error code 201."
            exit 201
        ;;
    esac
done