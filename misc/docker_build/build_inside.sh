#! /bin/bash
set -e

if [ ! -f /.dockerinit ]; then
    echo "this script meant to be run inside Docker" && exit 1;
fi

apt-get update && apt-get install -y --no-install-recommends\
    libsdl2-dev makeself

pushd /usr/src/ioq3\
 && make -j4\
 && pushd build\
 && pushd release-linux-armv7l\
 && rm -Rf client ded renderergl1 renderergl2 \
  tools/asm tools/cpp tools/etc tools/lburg tools/rcc \
  baseq3/cgame baseq3/game baseq3/qcommon baseq3/ui \
  missionpack/cgame missionpack/game missionpack/qcommon missionpack/ui \
 && popd\
 && mv release-linux-armv7l ioq3-linux-armv7l-${VERSION}\
 && tar cJvf /tmp/out/ioq3-linux-armv7l-${VERSION}.tar.xz ioq3-linux-armv7l-${VERSION} \
 && popd

echo "Sucessfuly built IOQ3"
