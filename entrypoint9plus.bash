#!/bin/bash

set -ex

JAVA_VERSION="${1}"
JDK="jdk"
JRE="jre"
OPENJ9="openj9"
OPENJ9_OPENJDK="${OPENJ9}-openjdk"
JDK_FLAVOR="${OPENJ9_OPENJDK}-${JDK}${JAVA_VERSION}"
JRE_FLAVOR="${OPENJ9_OPENJDK}-${JRE}${JAVA_VERSION}"
INSTRUCTION_SET="x86_64"

OS_TYPE="linux"
# cmake correct paths for
TOP_DIR=${HOME}
if [[ "${OSTYPE}" == "cygwin" || "${OSTYPE}" == "msys" ]]; then
  OS_TYPE="windows"
  TOP_DIR="/cygdrive/c"
  export JAVA_HOME=${HOME}/dev/tools/openjdk${JAVA_VERSION}
fi
OS_TYPE_AND_INSTRUCTION_SET="${OS_TYPE}-${INSTRUCTION_SET}"
JDK_DIR="${TOP_DIR}/${JDK_FLAVOR}"

BRANCH_TO_BUILD="v0.32.0-release"
#BRANCH_TO_BUILD="main"

git config --global user.email "anatoly.a.shipov@gmail.com"
git config --global user.name "Anatoly Shipov"

if [ ! -d "${JDK_DIR}/.git" ]
then
    cd ${TOP_DIR}
    git clone https://github.com/ibmruntimes/${JDK_FLAVOR}.git
    cd ${JDK_DIR}
    git checkout ${BRANCH_TO_BUILD}
else
    cd ${JDK_DIR}
    git checkout master
    git pull
    git checkout ${BRANCH_TO_BUILD}
    git pull
fi

bash get_source.sh -openj9-branch=${BRANCH_TO_BUILD} -omr-branch=${BRANCH_TO_BUILD}

VERSION_STRING=$(awk -F" := " '{print $2}' ${JDK_DIR}/closed/openjdk-tag.gmk)

# https://github.com/archlinux/svntogit-packages/blob/packages/java11-openjdk/trunk/PKGBUILD
# Avoid optimization of HotSpot being lowered from O3 to O2
GCC_FLAGS="-O3"

bash configure \
--with-debug-level=release \
--with-native-debug-symbols=none \
--with-jvm-variants=server \
--with-extra-cflags="${GCC_FLAGS}" \
--with-extra-cxxflags="${GCC_FLAGS}" \
--enable-unlimited-crypto \
--disable-warnings-as-errors \
--disable-warnings-as-errors-omr \
--disable-warnings-as-errors-openj9 \
--disable-keep-packaged-modules \
--with-version-string="${VERSION_STRING#${JDK}-}" \

make clean
STARTTIME=$(date +%s)
make images legacy-jre-image docs
ENDTIME=$(date +%s)
echo "Compilation took $((${ENDTIME} - ${STARTTIME})) seconds"

if [[ $? -eq 0 ]]
then
    if [[ "${JAVA_VERSION}" == "11" ]]
    then
        cd ${JDK_DIR}/build/${OS_TYPE_AND_INSTRUCTION_SET}-normal-server-release/images/
    elif [[ "${JAVA_VERSION}" == "17" ]]
    then
        cd ${JDK_DIR}/build/${OS_TYPE_AND_INSTRUCTION_SET}-server-release/images/
    fi
    find "${PWD}" -type f -name '*.debuginfo' -exec rm {} \;
    find "${PWD}" -type f -name '*.diz' -exec rm {} \;
    tar -I 'gzip -9' -chf ./${JDK_FLAVOR}-${OS_TYPE_AND_INSTRUCTION_SET}-${BRANCH_TO_BUILD}.tar.gz jdk/
    tar -I 'gzip -9' -chf ./${JRE_FLAVOR}-${OS_TYPE_AND_INSTRUCTION_SET}-${BRANCH_TO_BUILD}.tar.gz jre/
fi
