#!/bin/bash

# Fail the script if any command returns a non-zero value
set -e

# Slurp in some functions...
source /usr/share/misc/func.bash

#
# Usage function
function usage {
    echo "Usage: $0 --source=/path/to/release-source.json --manifest=/path/to/release-manifest.json --destination=/path/to/dist-dir"
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
        DESTINATION="${i#*=}"
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

if [ -z "$DESTINATION" -o ! -f "$DESTINATION" ]; then
    log ERROR "You need to specify a valid path to the release destination JSON file."
    log WARN "$(usage)"
    log WARN "Exit process with error code 100."
    exit 100
fi

if [ -z "$SOURCE" -o ! -d "$SOURCE" ]; then
    log ERROR "You need to specify a valid path to the source directory."
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

# Only handling "local" now, hence we assume we are in pipeline mode.
for ARTEFACT_NAME in $(cat $MANIFEST | jq -r '.artefacts.artefact[].name'); do
    log "Start pushing artefact $ARTEFACT_NAME to XYZ..."

    log "Finished pushing artefact $ARTEFACT_NAME."
done