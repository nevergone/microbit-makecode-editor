FROM alpine:3.16 as build

ARG PXT_VERSION=8.6.11
ARG PXT_COMMON_PACKAGES_VERSION=10.4.5
ARG PXT_MICROBIT_VERSION=5.1.3

RUN apk update \
    && apk upgrade \
    && apk --no-cache add \
         npm \
         wget \
    ## download and extract pxt (https://unix.stackexchange.com/a/11019): https://github.com/microsoft/pxt/
    && wget https://github.com/microsoft/pxt/archive/refs/tags/v$PXT_VERSION.tar.gz \
    && mkdir pxt \
    && tar xf v$PXT_VERSION.tar.gz -C pxt --strip-components 1 \
    && rm v$PXT_VERSION.tar.gz \
    ## download and extract pxt-common-packages: https://github.com/microsoft/pxt-common-packages/
    && wget https://github.com/microsoft/pxt-common-packages/archive/refs/tags/v$PXT_COMMON_PACKAGES_VERSION.tar.gz \
    && mkdir pxt-common-packages \
    && tar -xf v$PXT_COMMON_PACKAGES_VERSION.tar.gz -C pxt-common-packages --strip-components 1 \
    && rm v$PXT_COMMON_PACKAGES_VERSION.tar.gz \
    ## download and extract pxt-microbit: https://github.com/microsoft/pxt-microbit/
    && wget https://github.com/microsoft/pxt-microbit/archive/refs/tags/v$PXT_MICROBIT_VERSION.tar.gz \
    && mkdir pxt-microbit \
    && tar -xf v$PXT_MICROBIT_VERSION.tar.gz -C pxt-microbit --strip-components 1 \
    && rm v$PXT_MICROBIT_VERSION.tar.gz \
    ## pxt build
    && cd pxt \
    && npm install \
    && npm run build \
    ## pxt-common-packages build
    && cd ../pxt-common-packages \
    && npm install \
    && npm link ../pxt \
    ## pxt-microbit build
    && cd ../pxt-microbit \
    && npm install -g pxt \
    && npm install uglify-js \
    && npm install \
    && npm link ../pxt \
    && npm link ../pxt-common-packages \
    && pxt staticpkg -m -o /static

## create destination image
FROM nginx:1.23-alpine

LABEL maintainer="Kurucz István <never@nevergone.hu>"
LABEL vendor="nevergone"

ENV PXT_VERSION=$PXT_VERSION
ENV PXT_COMMON_PACKAGES_VERSION=$PXT_COMMON_PACKAGES_VERSION
ENV PXT_MICROBIT_VERSION=$PXT_MICROBIT_VERSION

COPY --from=build /static /usr/share/nginx/html
