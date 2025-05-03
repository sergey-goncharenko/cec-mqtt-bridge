#
#
#

FROM alpine:3.21

LABEL maintainer="Sergey G <s.gonch@hotmail.com>"

ARG LIBCEC_VERSION="4.0.7"
ARG LIBCEC_SHA256="bcd92c376993a5721d346edcc09eb17289451f9156b1d1d113c9663c2046315a"

ARG P8PLATFORM_VERSION="2.1.0.1"
ARG P8PLATFORM_SHA256="064f8d2c358895c7e0bea9ae956f8d46f3f057772cb97f2743a11d478a0f68a0"

RUN apk add --no-cache --virtual .build-deps \
        build-base \
        git \
        curl \
        musl-dev \
        make \
        cmake \
        swig \
        python3-dev \
        libxrandr-dev \
        eudev-dev \
        raspberrypi-dev \
    && apk add --no-cache \
        eudev \
        eudev-libs \
        python3 \
        py3-pip \
        libxrandr \
        raspberrypi-libs \
        libstdc++ \
    && cd /tmp \
    && python3 -m pip config set global.break-system-packages true \
    && pip3 install --no-cache --upgrade pip setuptools \
    && echo "==> p8 platform..." \
    && curl -fSL https://github.com/Pulse-Eight/platform/archive/p8-platform-${P8PLATFORM_VERSION}.tar.gz -o p8-platform-${P8PLATFORM_VERSION}.tar.gz \
    && echo "${P8PLATFORM_SHA256}  p8-platform-${P8PLATFORM_VERSION}.tar.gz" | sha256sum -c - \
    && tar xzf p8-platform-${P8PLATFORM_VERSION}.tar.gz \
    && mkdir /tmp/platform-p8-platform-${P8PLATFORM_VERSION}/build \
    && cd /tmp/platform-p8-platform-${P8PLATFORM_VERSION}/build \
    && cmake .. \
    && make \
    && make install \
    && cd /tmp \
    && echo "==> libcec..." \
    && curl -fSL https://github.com/Pulse-Eight/libcec/archive/refs/tags/libcec-${LIBCEC_VERSION}.tar.gz -o libcec-${LIBCEC_VERSION}.tar.gz \
    && echo "${LIBCEC_SHA256}  libcec-${LIBCEC_VERSION}.tar.gz" | sha256sum -c - \
    && tar xzf libcec-${LIBCEC_VERSION}.tar.gz \
    && ls -l /tmp \
    && mkdir /tmp/libcec-libcec-${LIBCEC_VERSION}/build \
    && cd /tmp/libcec-libcec-${LIBCEC_VERSION}/build \
    && cmake -D CMAKE_CXX_FLAGS="-fpermissive" -DHAVE_RPI_LIB=0 -DHAVE_LINUX_API=1 .. \
    && make \
    && make install \
    && ln -s /usr/local/lib/python3.12/site-packages/_cec.so /usr/lib/python3.12/ \
    && ln -s /usr/local/lib/python3.12/site-packages/cec.py /usr/lib/python3.12/ \
    && cd /tmp \
    && echo "==> Installing cec-bridge" \
    && mkdir /app \
    && git clone https://github.com/sergey-goncharenko/cec-mqtt-bridge.git \
    && cd /tmp/cec-mqtt-bridge \
    && pip3 install -r requirements.txt \
    && cp bridge.py /app \
    && echo "==> Cleaning up ..." \
    && cd /tmp \
    && rm -rf \
        libcec-${LIBCEC_VERSION}.tar.gz libcec-libcec-${LIBCEC_VERSION} \
        p8-platform-${P8PLATFORM_VERSION}.tar.gz platform-p8-platform-${P8PLATFORM_VERSION} \
        cec-mqtt-bridge \
        /usr/local/include/p8-platform/ /usr/local/lib/libp8-platform.a /usr/local/lib/pkgconfig/p8-platform.pc /usr/local/lib/p8-platform/p8-platform-config.cmake \
        /usr/local/include/libcec \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/*

COPY config.default.ini /app/config.ini

ENV LD_LIBRARY_PATH=/opt/vc/lib

STOPSIGNAL SIGTERM

CMD ["python3","/app/bridge.py"]
