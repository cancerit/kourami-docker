#!/bin/bash

set -ex

if [[ -z "${TMPDIR}" ]]; then
  TMPDIR=/tmp
fi

set -u

if [ "$#" -lt "1" ] ; then
  echo "Please provide an installation path such as /opt/ICGC"
  exit 1
fi

# get path to this script
SCRIPT_PATH=`dirname $0`;
SCRIPT_PATH=`(cd $SCRIPT_PATH && pwd)`

# get the location to install to
INST_PATH=$1
mkdir -p $1
INST_PATH=`(cd $1 && pwd)`
echo $INST_PATH

# get current directory
INIT_DIR=`pwd`


# Install Kourami
cd $INST_PATH
wget https://github.com/Kingsford-Group/kourami/archive/${VER_KOURAMI}.tar.gz
tar -vxzf ${VER_KOURAMI}.tar.gz

mkdir -p ${INST_PATH}/bin

