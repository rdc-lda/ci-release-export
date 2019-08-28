#!/bin/bash

# Fail the script if any command returns a non-zero value
set -e

# Slurp in some functions...
source /usr/share/misc/func.bash

# Set defaults
MANIFESTS_DIR=/var/data/manifests
RELEASE_BASE_DIR=/var/data/release-download

if [ -z "$MANIFESTS_DIR" -o \
        ! -d "$MANIFESTS_DIR" -o \
        ! -f "$MANIFESTS_DIR/release-destination.json" -o \
        ! -f "$MANIFESTS_DIR/release-source.json" -o \
        ! -f "$MANIFESTS_DIR/release-manifest.json" ]; then
    
    log ERROR "You do not seem to have all release manifest files in the directory $MANIFESTS_DIR"
    log WARN "Exit process with error code 100."
    exit 100
fi

# Set the release tag
RELEASE_NAME="$(cat $MANIFESTS_DIR/release-manifest.json | jq -r '.name')"
RELEASE_VERSION="$(cat $MANIFESTS_DIR/release-manifest.json | jq -r '.version')"
RELEASE_DIR=$RELEASE_BASE_DIR/$RELEASE_NAME/$RELEASE_VERSION

if [ ! -d $RELEASE_DIR ]; then
    # Create the dir...
    mkdir -p $RELEASE_DIR

    # Download the release
    download-release --source=$MANIFESTS_DIR/release-source.json \
        --manifest=$MANIFESTS_DIR/release-manifest.json \
        --destination=$RELEASE_DIR/

    # Validate the release
    validate-release --source=$RELEASE_DIR \
        --manifest=$MANIFESTS_DIR/release-manifest.json

    # Push the release to remote endpoint
    push-release --source=$RELEASE_DIR \
        --destination=$MANIFESTS_DIR/release-destination.json \
        --manifest=$MANIFESTS_DIR/release-manifest.json

    # Clean up
    log INFO "Removing local release artefacts..."
    rm -Rf $RELEASE_DIR

else
    log ERROR "Existing release directory found: $RELEASE_NAME/$RELEASE_VERSION, aborting!"
    log WARN "Exit process with error code 101."
    exit 101    
fi
