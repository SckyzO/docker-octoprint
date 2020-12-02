# OctoPrint

[![Build Status](https://travis-ci.org/SckyzO/docker-octoprint.svg?branch=master)](https://travis-ci.org/SckyzO/docker-octoprint)

New update : Octoprint 1.5.0

This is a Dockerfile to set up [OctoPrint](http://octoprint.org/). It supports the following architectures automatically:

- x86
- arm32v6 [<sup>1<sup>](###armv6-docker-bug)
- arm32v7
- arm64

Just run:

```sh
docker run sckyzo/octoprint
```

Now have a beer 🍻, and enjoy 😍

## Tags

- `1.5.0`, `alpine`, `latest`
- `1.4.2`

## Tested devices

| Device              | Working? |
| ------------------- | -------- |
| Raspberry Pi 2b     | ✅       |
| Raspberry Pi 3b+    | ✅       |
| Raspberry Pi Zero W | ✅       |

Please let me know if you test any others, would love to increase the compatibility list!

## Usage

```shell
$ docker run \
  --device=/dev/video0 \
  -p 80:80 \
  -v /mnt/data:/data \
  sckyzo/octoprint
```

## Environment Variables

| Variable                 | Description                    | Default Value            |
| ------------------------ | ------------------------------ | ------------------------ |
| CAMERA_DEV               | The camera device node         | `/dev/vchiq`            |
| MJPEG_STREAMER_AUTOSTART | Start the camera automatically | `true`                   |
| MJPEG_STREAMER_INPUT     | Flags to pass to mjpg_streamer | `-x 1280 -y 720 -fps 15` |

## CuraEngine integration

Cura engine integration was very outdated (using version `15.04.6`) and was removed.

It will return once OctoPrint [supports python3](https://github.com/foosel/OctoPrint/pull/1416#issuecomment-371878648) (needed for the newest versions of cura engine).

## Webcam integration

### Raspberry Pi camera module (default)

1. The camera module must be activated (sudo raspi-config -> interfacing -> Camera -> set it to YES)
2. Memory split must be at least 128mb, 256mb recommended. (sudo raspi-config -> Advanced Options -> Memory Split -> set it to 128 or 256)
3. You must allow access to device: /dev/vchiq
4. Change `MJPEG_STREAMER_INPUT` to use input_raspicam.so (ex: `input_raspicam.so -x 1280 -y 720 -fps 15`)

For more details on the parameters of mjpeg_stream, please refer to the [official documentation](https://github.com/jacksonliam/mjpg-streamer/blob/master/mjpg-streamer-experimental/plugins/input_raspicam/README.md).
For more details on the parameters of your Raspberry Pi Camera Module, please refer to the [official documentation](https://www.raspberrypi.org/documentation/raspbian/applications/camera.md)

It does support upto 1080p 30fps, but the bandwidth produced would be more than the usb bus (and therefore ethernet port / wifi dongle) can provide. 720p 15fps is a good compromise.

<sup>* Raspberry PI camera support is only available in `arm/v6` and `arm/v7` builds at the moment.<sup>

### USB Webcam

1. Bind the camera to the docker using --device=/dev/video0:/dev/videoX
2. Optionally, change `MJPEG_STREAMER_INPUT` to your preferred settings (ex: `input_uvc.so -y -n -x 1920 -y 1080 -fps 25`)

### Octoprint configuration

Use the following settings in octoprint:

```yaml
webcam:
  stream: /webcam/?action=stream
  snapshot: http://127.0.0.1:8080/?action=snapshot
  ffmpeg: /usr/bin/ffmpeg
```

### ARMv6 Docker Bug

_ARM32v6_ devices such as the Raspberry Pi Zero (W) are unfortunately unable to pull this image directly using `docker pull nunofgs/octoprint` due to a bug in Docker ([moby/moby#37647](https://github.com/moby/moby/issues/37647), [moby/moby#34875](https://github.com/moby/moby/issues/34875)). There's a [PR open](https://github.com/moby/moby/pull/36121#issuecomment-515243647) to fix this but it might be some time until it hits a stable Docker release.

Until then, you can run this container by specifying the armv6 image hash. Example on [HypriotOS 1.11.0](https://blog.hypriot.com):

```sh
$ docker manifest inspect sckyzo/octoprint | grep -e "variant.*v6" -B 4

# copy sha256 hash of the v6 image you want to run.

$ docker run sckyzo/octoprint@sha256:dce9b67ccd25bb63c3024ab96c55428281d8c3955c95c7b5133807133863da29
```

### Toggle the camera on/off

This image uses `supervisord` in order to launch 3 processes: _haproxy_, _octoprint_ and _mjpeg-streamer_.

This means you can disable/enable the camera at will from within octoprint by editing your `config.yaml`:

```yaml
system:
  actions:
  - action: streamon
    command: supervisorctl start mjpeg-streamer
    confirm: false
    name: Start webcam
  - action: streamoff
    command: supervisorctl stop mjpeg-streamer
    confirm: false
    name: Stop webcam
```

## Credits

Original credits go to [a2z Team](https://bitbucket.org/a2z-team/docker-octoprint). I initially ported this to the raspberry pi 2 and later moved to a multiarch image.

This repo is based on [nunofgs](https://github.com/nunofgs/docker-octoprint/) work.

## License

MIT

[travis-image]: https://img.shields.io/travis/nunofgs/docker-octoprint.svg?style=flat-square
[travis-url]: https://travis-ci.org/nunofgs/docker-octoprint

## Todo

List of news features

- [ ] Integrate Cura Engine in last version with python 3 support
- [ ] Add plugins support with Docker env
- [ ] Run container without root process
