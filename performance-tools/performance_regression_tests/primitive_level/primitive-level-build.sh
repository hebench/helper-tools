#!/bin/bash

set -e

mkdir -p repos-primitive-level-$RUNTAG
pushd repos-primitive-level-$RUNTAG

# HEXL
if [ "$HEXL" = true ];
then
    git clone https://github.com/intel/hexl.git
    pushd hexl
    git checkout $HEXLVERSION
    mkdir build && pushd build
    cmake -DCMAKE_INSTALL_PREFIX=./install -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=g++-10 -DCMAKE_C_COMPILER=gcc-10 ..
    make -j install
    AUTO_HEXL_PATH=$PWD
    popd && popd
fi

popd
