FROM alpine:3.17

LABEL maintainer="Kurucz István <never@nevergone.hu>"
LABEL vendor="nevergone"

ARG VERSION=5.1.3

RUN apk update \
    && apk upgrade \
    && apk --no-cache add \
         npm \
         wget \
    && wget https://github.com/microsoft/pxt-microbit/archive/refs/tags/v$VERSION.tar.gz \
    && tar -xf v$VERSION.tar.gz \
    && rm v$VERSION.tar.gz \
    && cd pxt-microbit-$VERSION \
    && npm install -g pxt \
    && npm install

ENTRYPOINT ["pxt", "serve"]
CMD ["--rebundle"]

