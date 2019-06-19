#!/bin/bash

# Fail the script if any command returns a non-zero value
set -e

# Slurp in some functions...
source /usr/share/misc/func.bash

#
# Usage function
function usage {
    echo "Usage: $0 --source=/path/to/release-source.json --manifest=/path/to/release-manifest.json --destination=/path/to/release-dir"
}

# Set defaults
# Nothing

for i in "$@"; do
    case $i in
        -s=*|--source=*)
        SOURCE="${i#*=}"
        shift # past argument=value
        ;;
        -d=*|--destination=*)
        RELEASE_DIR="${i#*=}"
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

if [ -z "$RELEASE_DIR" -o ! -d "$RELEASE_DIR" ]; then
    log ERROR "You need to specify a valid path to the release (destination) directory (needs to exist)."
    log WARN "$(usage)"
    log WARN "Exit process with error code 101."
    exit 101
fi

if [ -z "$MANIFEST" -o ! -f "$MANIFEST" ]; then
    log ERROR "You need to specify a valid path to the release manifest JSON file."
    log WARN "$(usage)"
    log WARN "Exit process with error code 102."
    exit 102
fi

if [ -z "$AWS_ACCESS_KEY_ID" -o -z "$AWS_SECRET_ACCESS_KEY" ]; then
    log ERROR "AWS Access or Secret keys not found in environment, exit."
    log WARN "Exit process with error code 200."
    exit 200
fi

#
# Download logic

# Download the release from source
S3_BUCKET="$(cat $SOURCE | jq -r '.endpoint.base_url')"

for ARTEFACT_NAME in $(cat $MANIFEST | jq -r '.artefacts.artefact[].name'); do
    log "Start downloading artefact $ARTEFACT_NAME from S3 bucket $S3_BUCKET..."
    mkdir -p $RELEASE_DIR/$ARTEFACT_NAME
    ARTEFACT_VERSION=$(cat $MANIFEST | jq -r '.artefacts.artefact[] | select(.name == "'$ARTEFACT_NAME'") | .version')
    aws s3 cp $S3_BUCKET/$ARTEFACT_NAME/$ARTEFACT_VERSION $RELEASE_DIR/$ARTEFACT_NAME --recursive
    log "Finished downloading artefact $ARTEFACT_NAME."
done