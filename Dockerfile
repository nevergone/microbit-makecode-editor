ARG PXT_MICROBIT_VERSION=7.0.57
ARG NODE_MAJOR=18

# developer tools
FROM ubuntu:22.04 AS tools

ARG NODE_MAJOR
ARG PXT_MICROBIT_VERSION
ARG USERNAME=unpriv
ENV DEBIAN_FRONTEND=noninteractive
ENV PXT_NODOCKER='1'
ENV TZ=Etc/UTC

RUN echo $USERNAME > /.username \
    && apt-get update \
    && apt-get upgrade -y --force-yes \
    && apt-get install -y --force-yes --no-install-recommends \
         ca-certificates \
         curl \
         gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --force-yes --no-install-recommends \
         cargo \
         cmake \
         gcc \
         gcc-arm-none-eabi \
         git \
         libnewlib-arm-none-eabi \
         libstdc++-arm-none-eabi-dev \
         libstdc++-arm-none-eabi-newlib \
         make \
         ninja-build \
         nodejs \
         openocd \
         python-is-python3 \
         srecord \
         sudo \
         wget \
         yotta \
    && useradd -s /bin/bash -m $USERNAME -p '' \
    && npm install -g makecode \
    && npm install -g node-hid \
    && npm install -g pxt \
    && apt-get autoremove --purge -y \
    && rm -rf /var/lib/apt/* \
    && rm -rf /var/cache/*

COPY usr /usr
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]


# build developer variant
FROM tools AS devel
  
ARG PXT_MICROBIT_VERSION
ARG NODE_MAJOR
ENV NODE_MAJOR=$NODE_MAJOR
ENV PXT_MICROBIT_VERSION=$PXT_MICROBIT_VERSION

## download and extract pxt-microbit: https://github.com/microsoft/pxt-microbit/
RUN wget https://github.com/microsoft/pxt-microbit/archive/refs/tags/v$PXT_MICROBIT_VERSION.tar.gz \
    && mkdir pxt-microbit \
    && tar -xf v$PXT_MICROBIT_VERSION.tar.gz -C pxt-microbit --strip-components 1 \
    && rm v$PXT_MICROBIT_VERSION.tar.gz \
    ## pxt-microbit build
    && cd ../pxt-microbit \
    && npm install \
    && pxt staticpkg \
    && rm -rf /pxt-microbit/built/packaged/hexcache/*

WORKDIR /pxt-microbit


## create destination image
FROM nginx:1.27-alpine

ARG PXT_MICROBIT_VERSION
ENV PXT_MICROBIT_VERSION=$PXT_MICROBIT_VERSION

LABEL maintainer="Kurucz István <never@nevergone.hu>"
 
COPY --from=devel /pxt-microbit/built/packaged /usr/share/nginx/html
COPY config/default.conf /etc/nginx/conf.d/default.conf
