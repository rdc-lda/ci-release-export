FROM alpine:3.9

RUN apk update
RUN apk add bash

# Install aws-cli for S3 endpoints
RUN apk -Uuv add groff less python py-pip && \
    pip install awscli && \
    apk --purge -v del py-pip && \
    rm /var/cache/apk/*

# Install SSH for SFTP endpoints
RUN apk -Uuv add openssh && \
    rm /var/cache/apk/*

# Install JQ
RUN apk -Uuv add jq && \
    rm /var/cache/apk/*

# Add the scripts
ADD src/export-release.bash /usr/bin/export-release
RUN chmod a+x /usr/bin/export-release