ARG PXT_MICROBIT_VERSION=7.0.57
ARG SRECORD_VERSION=1.65.0

# build components
FROM alpine:3.21 AS build

ARG PXT_MICROBIT_VERSION
ARG SRECORD_VERSION
ARG USERNAME=unpriv

COPY patches /patches

RUN echo $USERNAME > /.username \
    && apk update \
    && apk upgrade \
    && apk --no-cache add \
         bash \
         boost-dev \
         cargo \
         clang19 \
         cmake \
         gcc \
         gcc-arm-none-eabi \
         gcompat \
         git \
         g++ \
         g++-arm-none-eabi \
         libgcrypt-dev \
         libtool \
         make \
         npm \
         openssl-dev \
         patch \
         py3-cryptography \
         py3-pip \
         py3-virtualenv \
         python3-dev \
         shadow \
         slibtool \
         sudo \
         wget \
    && useradd -s /bin/bash -m $USERNAME -p '' \
    && usermod -s /bin/bash root \
    ## download & build srecord
    && DIR_VERSION=`echo $SRECORD_VERSION | grep -Eo '[0-9]\.[0-9]+'` \
    && wget https://sourceforge.net/projects/srecord/files/srecord/$DIR_VERSION/srecord-$SRECORD_VERSION-Source.tar.gz -O srecord.tar.gz \
    && tar xf srecord.tar.gz \
    && cd srecord-$SRECORD_VERSION-Source \
    && patch -p1 < /patches/01-srecord-disable_doxygen.patch \
    && patch -p1 < /patches/02-srecord-ldconfig_install_bug.patch \
    && mkdir build \
    && cd build \
    && cmake .. \
    && cmake --build . \
    && cmake --install . \
    && cd / \
    && rm -rf /patches srecord.tar.gz srecord-$SRECORD_VERSION-Source \
    ## install yotta
    && mkdir -p /opt/yotta \
    && virtualenv /opt/yotta/ \
    && source /opt/yotta/bin/activate \
    && pip install markupsafe==2.0.1 maturin ninja setuptools setuptools_scm \
    && pip install --no-build-isolation PyYAML==5.3.1 yotta \
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
    && rm -rf /pxt-microbit/built/packaged/hexcache/* \
    && rm -rf /root/.cache

COPY usr /usr
ENV ENV='/etc/profile' LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8' PXT_NODOCKER='1' PXT_MICROBIT_VERSION=$PXT_MICROBIT_VERSION PATH="$PATH:/opt/yotta/bin"
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
