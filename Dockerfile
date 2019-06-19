FROM alpine:3.9

RUN apk update
RUN apk -Uuv add bash ca-certificates openssl git openssh && \
    rm /var/cache/apk/*

# Install aws-cli for S3 endpoints
RUN apk -Uuv add groff less python py-pip && \
    pip install awscli && \
    apk --purge -v del py-pip && \
    rm /var/cache/apk/*

# Install JQ
RUN apk -Uuv add jq && \
    rm /var/cache/apk/*

# Add the libs
ADD src/func.bash /usr/share/misc/func.bash

# Add the scripts
ADD src/download-release.bash /usr/bin/download-release
ADD src/validate-release.bash /usr/bin/validate-release
ADD src/push-release.bash /usr/bin/push-release
RUN chmod a+x /usr/bin/*-release