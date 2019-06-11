FROM ruby:alpine

# Install HTMLProofer - https://github.com/gjtorikian/html-proofer
RUN apk add --no-cache --virtual build-dependencies build-base libxml2-dev libxslt-dev \
    && apk add --no-cache libcurl \
    && gem install html-proofer --no-document \
    && apk del build-dependencies
