#!/bin/bash

# Fail the script if any command returns a non-zero value
set -e

# Slurp in some functions...
source /usr/share/misc/func.bash

#
# Usage function
function usage {
    echo "Usage: $0 --source=/path/to/release-dir --manifest=/path/to/release-manifest.json --destination=/path/to/release-destination.json"
}

# Set defaults
# Nothing

for i in "$@"; do
    case $i in
        -s=*|--source=*)
            RELEASE_DIR="${i#*=}"
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

if [ -z "$RELEASE_DIR" -o ! -d "$RELEASE_DIR" ]; then
    log ERROR "You need to specify a valid path to the release (source) directory."
    log WARN "$(usage)"
    log WARN "Exit process with error code 101."
    exit 101
fi

if [ -z "$DESTINATION" -o ! -f "$DESTINATION" ]; then
    log ERROR "You need to specify a valid path to the release destination JSON file."
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
# Upload logic
DESTINATION_TYPE="$(cat $DESTINATION | jq -r '.endpoint.type')"

case $DESTINATION_TYPE in
    sftp)
        log INFO "Destination for release set to SFTP"
    ;;
    *)
        # Unknown option
        log ERROR "Source for release set to $SOURCE_TYPE, not yet supported!"
        log WARN "Exit process with error code 201."
        exit 201
    ;;
esac

# Set the release tag
RELEASE_NAME="$(cat $MANIFEST | jq -r '.name')"
RELEASE_VERSION="$(cat $MANIFEST | jq -r '.version')"

# SFTP
if [ "$DESTINATION_TYPE" = "sftp" ]; then
    if [ -z "$DESTINATION_SFTP_USERNAME" -o -z "$DESTINATION_SFTP_PASSWORD" ]; then
        log ERROR "SFTP credentials not found in environment, exit."
        log WARN "Exit process with error code 200."
        exit 200
    fi

    # We are SSHPASS security here...
    export SSHPASS=$DESTINATION_SFTP_PASSWORD

    # Upload the release from the locally cached directory
    HOST="$(cat $DESTINATION | jq -r '.endpoint.host')"
    PORT="$(cat $DESTINATION | jq -r '.endpoint.port')"
    BASE_DIR="$(cat $DESTINATION | jq -r '.endpoint.base_dir')"

    SFTP_URI=$DESTINATION_SFTP_USERNAME@$HOST

    # Check if the release on the SFTP server not already exists...
    echo "cd $BASE_DIR/$RELEASE_NAME-$RELEASE_VERSION" > check4directory
    echo "bye" >> check4directory
    chmod +x check4directory

    # This section will generate an error (expected), hence disable bash option e
    set +e
    sshpass -e sftp -o "StrictHostKeyChecking no" -oBatchMode=no -b check4directory -P $PORT $SFTP_URI &> /dev/null
    if [ $? -eq "0" ] ; then
        log ERROR "The release already exists on the remote SFTP server under $BASE_DIR/$RELEASE_NAME-$RELEASE_VERSION"
        exit 1
    fi
    if [ $? -ge "2" ] ; then
        log ERROR "There was a connection issue with SFTP server "
        exit 1
    fi
    set -e

    #
    # Create the directory
    log INFO "Creating remote SFTP release destination directory"
    echo "mkdir $BASE_DIR/$RELEASE_NAME-$RELEASE_VERSION" > create_directory
    echo "bye" >> create_directory
    chmod +x create_directory

    # This section will generate an possible error (expected), hence disable bash option e
    set +e
    sshpass -e sftp -o "StrictHostKeyChecking no" -oBatchMode=no -b create_directory -P $PORT $SFTP_URI &> /dev/null
    set -e

    #
    # Upload the artefacts
    log INFO "Uploading release to SFTP server $HOST (tcp/$PORT) under $BASE_DIR"

    for ARTEFACT_NAME in $(cat $MANIFEST | jq -r '.artefacts.artefact[].name'); do
        ARTEFACT_VERSION=$(cat $MANIFEST | jq -r '.artefacts.artefact[] | select(.name == "'$ARTEFACT_NAME'") | .version')

        log "Start uploading artefact $ARTEFACT_NAME with version $ARTEFACT_VERSION..."
        echo "cd $BASE_DIR/$RELEASE_NAME-$RELEASE_VERSION" > upload_directory
        echo "lcd $RELEASE_DIR" >> upload_directory
        echo "put -r $ARTEFACT_NAME" >> upload_directory
        echo "rename $ARTEFACT_NAME $ARTEFACT_NAME-$ARTEFACT_VERSION" >> upload_directory
        echo "bye" >> upload_directory
        chmod +x upload_directory
        sshpass -e sftp -o "StrictHostKeyChecking no" -oBatchMode=no -b upload_directory -P $PORT $SFTP_URI &> /dev/null
        log "Finished uploading artefact $ARTEFACT_NAME."
    done

    # Finally... copy the release manifest!
    log "Start uploading release manifest..."
    sshpass -e sftp -o "StrictHostKeyChecking no" -P $PORT $SFTP_URI:$BASE_DIR/$RELEASE_NAME-$RELEASE_VERSION <<< $'put '$MANIFEST &> /dev/null
    log "Finished uploading release manifest."
fi

# Finally... copy the release manifest!
