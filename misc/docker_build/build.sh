#! /bin/bash

pushds() {
   pushd "$@" > /dev/null
}

popds() {
   popd > /dev/null
}

pushds $(dirname "${BASH_SOURCE[0]}") > /dev/null

if [ -z "${1}" ]; then
    echo "First argument must be a valid release tag VERSION REL_ is prepended automatically";
    popds ; exit 1
fi

IOQ3_REL=$1
hash=$(git rev-parse REL-${IOQ3_REL}) || ""

if [ "${hash}" != "$(git rev-parse HEAD)" ]; then
    echo "Working copy does not match tag REL-${IOQ3_REL} revision hash, try git checkout REL-${IOQ3_REL}"
    popds ; exit 2
fi

buildDir=`mktemp -d`

cleanup() {
    popds
    rm -Rf ${buildDir}
}

docker run --rm -t -v ${buildDir}:/tmp/out -v `realpath ../..`:/usr/src/ioq3\
   -e VERSION=${IOQ3_REL} -e USE_GIT=0\
   zsoltm/buildpack-deps:jessie-armhf /usr/src/ioq3/misc/build-docker/build-ioq3.sh\
 || (cleanup ; exit 5)

## Create & Upload github release

curl -nfLX POST https://api.github.com/repos/zsoltm/ioq3/releases\
 -H "Content-Type: application/json; encoding=UTF-8"\
 --data "{\"tag_name\":\"REL-${IOQ3_REL}\",\"name\":\"${IOQ3_REL}\"}" > ${buildDir}/git-release.json\
 || (cleanup ; exit 3)

uploadUrl=$(grep '"upload_url": "' ${buildDir}/git-release.json |\
    grep -o 'https://[^"{]*')

curl -nfLX POST "${uploadUrl}?name=ioq3-linux-armv7l-${IOQ3_REL}.tar.xz"\
 -H "Content-Type: application/octet-stream"\
 --data-binary @${buildDir}/ioq3-linux-armv7l-${IOQ3_REL}.tar.xz\
 || (cleanup ; exit 4)

echo "Release of ${IOQ3_REL} was successful"

cleanup
