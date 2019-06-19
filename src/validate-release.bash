#!/bin/bash

# Fail the script if any command returns a non-zero value
set -e

# Slurp in some functions...
source /usr/share/misc/func.bash

#
# Usage function
function usage {
    echo "Usage: $0 --source=/path/to/release-dir --manifest=/path/to/release-manifest.json"
}

# Set defaults
# Nothing

for i in "$@"; do
    case $i in
        -s=*|--source=*)
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

if [ -z "$RELEASE_DIR" -o ! -d "$RELEASE_DIR" ]; then
    log ERROR "You need to specify a valid path to the release (source) directory."
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

#
# Validating logic
for ARTEFACT_NAME in $(cat $MANIFEST | jq -r '.artefacts.artefact[].name'); do
    log MOCK "Validate GPG signature for $ARTEFACT_NAME..."
    log MOCK "Validate configuration for $ARTEFACT_NAME..."
    log MOCK "Validate deployment manifests for $ARTEFACT_NAME..."
    log MOCK "Validate reports for $ARTEFACT_NAME..."
done