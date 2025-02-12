ARG PXT_MICROBIT_VERSION=7.0.57

# build components
FROM alpine:3.21 AS build

ARG PXT_MICROBIT_VERSION
ARG USERNAME=unpriv

RUN echo $USERNAME > /.username \
    && apk update \
    && apk upgrade \
    && apk --no-cache add \
         bash \
         gcc \
         g++ \
         make \
         npm \
         shadow \
         sudo \
         wget \
    && useradd -s /bin/bash -m $USERNAME -p '' \
    && usermod -s /bin/bash root \
    ## download and extract pxt-microbit: https://github.com/microsoft/pxt-microbit/
    && wget https://github.com/microsoft/pxt-microbit/archive/refs/tags/v$PXT_MICROBIT_VERSION.tar.gz \
    && mkdir pxt-microbit \
    && tar -xf v$PXT_MICROBIT_VERSION.tar.gz -C pxt-microbit --strip-components 1 \
    && rm v$PXT_MICROBIT_VERSION.tar.gz \
    ## pxt-microbit build
    && cd ../pxt-microbit \
    && npm install -g pxt \
    && npm install -g yotta \
    && ln -s /usr/local/bin/yotta /usr/local/bin/yt \
    && npm install \
    && pxt staticpkg \
    && rm -rf /pxt-microbit/built/packaged/hexcache/*

COPY usr /usr
ENV ENV='/etc/profile' LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8' PXT_NODOCKER='1'
WORKDIR /pxt-microbit
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]


## create destination image
FROM nginx:1.27-alpine

ARG PXT_MICROBIT_VERSION
ENV PXT_MICROBIT_VERSION=$PXT_MICROBIT_VERSION

LABEL maintainer="Kurucz István <never@nevergone.hu>"
 
COPY --from=build /pxt-microbit/built/packaged /usr/share/nginx/html
COPY config/default.conf /etc/nginx/conf.d/default.conf
