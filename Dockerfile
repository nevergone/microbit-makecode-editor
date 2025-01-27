ARG PXT_MICROBIT_VERSION=7.0.57

# build components
FROM alpine:3.21 AS build

ARG PXT_MICROBIT_VERSION

RUN apk update \
    && apk upgrade \
    && apk --no-cache add \
         npm \
         wget \
    ## download and extract pxt-microbit: https://github.com/microsoft/pxt-microbit/
    && wget https://github.com/microsoft/pxt-microbit/archive/refs/tags/v$PXT_MICROBIT_VERSION.tar.gz \
    && mkdir pxt-microbit \
    && tar -xf v$PXT_MICROBIT_VERSION.tar.gz -C pxt-microbit --strip-components 1 \
    && rm v$PXT_MICROBIT_VERSION.tar.gz \
    ## pxt-microbit build
    && cd ../pxt-microbit \
    && npm install -g pxt \
    && npm install \
    && pxt staticpkg \
    && rm -rf /pxt-microbit/built/packaged/hexcache/*


## create destination image
FROM nginx:1.27-alpine

ARG PXT_MICROBIT_VERSION
ENV PXT_MICROBIT_VERSION=$PXT_MICROBIT_VERSION

LABEL maintainer="Kurucz István <never@nevergone.hu>"
 
COPY --from=build /pxt-microbit/built/packaged /usr/share/nginx/html
COPY config/default.conf /etc/nginx/conf.d/default.conf
