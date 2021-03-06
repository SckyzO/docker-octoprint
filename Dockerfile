# Intermediate build container.
FROM python:3-alpine as build

ARG TARGETPLATFORM
ARG OCTOPRINT_VERSION

RUN apk --no-cache add build-base
RUN apk --no-cache add cmake
RUN apk --no-cache add libjpeg-turbo-dev
RUN apk --no-cache add linux-headers
RUN apk --no-cache add openssl
RUN [[ "${TARGETPLATFORM:6}" != "arm64" ]] && apk --no-cache add raspberrypi-dev raspberrypi-libs || true

# Download packages
RUN wget -qO- https://github.com/foosel/OctoPrint/archive/${OCTOPRINT_VERSION}.tar.gz | tar xz
RUN wget -qO- https://github.com/jacksonliam/mjpg-streamer/archive/master.tar.gz | tar xz

# Install mjpg-streamer
WORKDIR /mjpg-streamer-master/mjpg-streamer-experimental
RUN make
RUN make install

# Install OctoPrint
WORKDIR /OctoPrint-${OCTOPRINT_VERSION}
RUN pip3 install -r requirements.txt
RUN python3 setup.py install

# Build final image
FROM python:3-alpine

COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /mjpg-streamer-*/mjpg-streamer-experimental /opt/mjpg-streamer
COPY --from=build /OctoPrint-* /opt/octoprint

RUN apk --no-cache add build-base ffmpeg haproxy libjpeg openssh-client supervisor v4l-utils
RUN [[ "${TARGETPLATFORM:6}" != "arm64" ]] && apk --no-cache add raspberrypi-libs || true
RUN ln -s ~/.octoprint /data

VOLUME /data
WORKDIR /data

COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY start-mjpg-streamer /usr/local/bin/start-mjpg-streamer

ENV CAMERA_DEV /dev/video0
ENV MJPEG_STREAMER_AUTOSTART true
ENV MJPEG_STREAMER_INPUT -x 1280 -y 720 -fps 15 -ex auto
ENV PIP_USER true
ENV PYTHONUSERBASE /data/plugins
ENV PATH /data/plugins/bin:$PATH
ENV LD_LIBRARY_PATH /opt/vc/lib/

EXPOSE 80

LABEL description="OctoPrint is an open source 3D print controller application." \
      nextcloud="Octoprint v${OCTOPRINT_VERSION}" \
      maintainer="SckyzO <https://www.github.com/sckyzo>"

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
