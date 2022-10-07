#!/bin/bash

get_distro () {
  EXT=""
  if [[ $2 == *.tar.bz2* ]] ; then
    EXT="tar.bz2"
  elif [[ $2 == *.zip* ]] ; then
    EXT="zip"
  elif [[ $2 == *.tar.gz* ]] ; then
    EXT="tar.gz"
  elif [[ $2 == *.tgz* ]] ; then
    EXT="tgz"
  else
    echo "I don't understand the file type for $1"
    exit 1
  fi
  rm -f $1.$EXT
  if hash curl 2>/dev/null; then
    curl --retry 10 -sS -o $1.$EXT -L $2
  else
    wget --tries=10 -nv -O $1.$EXT $2
  fi
}

get_file () {
# output, source
  if hash curl 2>/dev/null; then
    curl -sS -o $1 -L $2
  else
    wget -nv -O $1 $2
  fi
}

if [ "$#" -ne "1" ] ; then
  echo "Please provide an installation path  such as /opt/ICGC"
  exit 0
fi

CPU=`grep -c ^processor /proc/cpuinfo`
if [ $? -eq 0 ]; then
  if [ "$CPU" -gt "6" ]; then
    CPU=6
  fi
else
  CPU=1
fi
echo "Max compilation CPUs set to $CPU"

INST_PATH=$1

# get current directory
INIT_DIR=`pwd`

set -e
# cleanup inst_path
mkdir -p $INST_PATH
cd $INST_PATH
INST_PATH=`pwd`
mkdir -p $INST_PATH/bin
cd $INIT_DIR

export PATH="$INST_PATH/bin:$PATH"

#create a location to build dependencies
SETUP_DIR=$INIT_DIR/install_tmp
mkdir -p $SETUP_DIR

echo -n "Building libdeflate ..."
if [ -e $SETUP_DIR/libdeflate.success ]; then
  echo " previously built ...";
else
  echo
  cd $SETUP_DIR
  mkdir -p libdeflate
  get_distro "libdeflate" "https://github.com/ebiggers/libdeflate/archive/$VER_LIBDEFLATE.tar.gz"
  tar --strip-components 1 -C libdeflate -zxf libdeflate.tar.gz
  cd libdeflate
  make -j$CPU CFLAGS="-fPIC -O3" libdeflate.a
  PREFIX=$INST_PATH make install
  cd $SETUP_DIR
  rm -r libdeflate.tar.gz
  touch $SETUP_DIR/libdeflate.success
fi

echo -n "Building htslib ..."
if [ -e $SETUP_DIR/htslib.success ]; then
  echo " previously built ...";
else
  echo
  cd $SETUP_DIR
  mkdir -p htslib
  get_distro "htslib" "https://github.com/samtools/htslib/releases/download/$VER_HTSLIB/htslib-$VER_HTSLIB.tar.bz2"
  tar --strip-components 1 -C htslib -jxf htslib.tar.bz2
  cd htslib
  export CFLAGS="-I$INST_PATH/include"
  export LDFLAGS="-L$INST_PATH/lib"
  ./configure --disable-plugins  --enable-libcurl --with-libdeflate --prefix=$INST_PATH
  make -j$CPU
  make install
  cd $SETUP_DIR
  rm -r htslib.tar.bz2
  unset CFLAGS
  unset LDFLAGS
  touch $SETUP_DIR/htslib.success
fi

echo -n "Building samtools ..."
if [ -e $SETUP_DIR/samtools.success ]; then
  echo " previously built ...";
else
  echo
  cd $SETUP_DIR
  rm -rf samtools
  get_distro "samtools" "https://github.com/samtools/samtools/releases/download/$VER_SAMTOOLS/samtools-$VER_SAMTOOLS.tar.bz2"
  mkdir -p samtools
  tar --strip-components 1 -C samtools -xjf samtools.tar.bz2
  cd samtools
  ./configure --with-htslib=$SETUP_DIR/htslib --enable-plugins --enable-libcurl --prefix=$INST_PATH
  make -j$CPU
  make install
  cd $SETUP_DIR
  rm -f samtools.tar.bz2
  touch $SETUP_DIR/samtools.success
fi

echo -n "Building kourami ..."
if [ -e $SETUP_DIR/kourami.success ]; then
  echo " previously built ...";
else
  echo
  cd $SETUP_DIR
  rm -rf kourami
  get_distro "kourami" "https://github.com/Kingsford-Group/kourami/archive/refs/tags/${VER_KOURAMI}.tar.gz"
  mkdir -p kourami
  tar --strip-components 1 -C kourami -xzf kourami.tar.gz
  cd kourami
  mvn install
  cp -r target $INST_PATH/java
  cp scripts/* $INST_PATH/bin
  cd $SETUP_DIR
  rm -f kourami.tar.gz
  touch $SETUP_DIR/kourami.success
fi

echo -n "Building BamUtil ..."
if [ -e $SETUP_DIR/bamutil.success ]; then
  echo " previously built ...";
else
  echo
  cd $SETUP_DIR
  rm -rf bamutil
  get_distro "bamutil" "https://github.com/statgen/bamUtil/archive/refs/tags/${VER_BAMUTIL}.tar.gz"
  mkdir -p bamutil
  tar --strip-components 1 -C bamutil -xzf bamutil.tar.gz
  mkdir libStatGen
  get_distro "libStatGen" "https://github.com/statgen/libStatGen/archive/refs/tags/${VER_BAMUTIL}.tar.gz"
  tar --strip-components 1 -C libStatGen -xzf libStatGen.tar.gz
  cd bamutil
  make install INSTALLDIR=$INST_PATH/bin
  cd $SETUP_DIR
  rm -f kamutil.tar.gz
  touch $SETUP_DIR/bamutil.success
fi

echo -n "Building bwa ..."
if [ -e $SETUP_DIR/bwa.success ]; then
  echo " previously built ...";
else
  echo
  cd $SETUP_DIR
  rm -rf bwa 
  get_distro "bwa" "https://github.com/lh3/bwa/archive/refs/tags/${VER_BWA}.tar.gz"
  mkdir -p bwa
  tar --strip-components 1 -C bwa -xzf bwa.tar.gz
  cd bwa
  sed -i '/const uint8_t rle_auxtab\[8\];/d' ./rle.h #need to remove this for gcc10
  make
  mv bwa $INST_PATH/bin
  touch $SETUP_DIR/bwa.success
fi

