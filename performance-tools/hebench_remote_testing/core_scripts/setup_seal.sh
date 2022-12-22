#!/bin/bash

set -e

if [[ $# -lt 1 ]]; then
        echo "Script arguments: HEXL(ON,*OFF) [COMPILER_C] [COMPILER_CXX] [seal_version]" >&2
        exit 2
fi

if [ -z "$1" ]
  then
    HEXL_OPT=OFF
  else
    HEXL_OPT="$1"
fi

if [ -z "$2" ]
  then
    C_OPT=gcc
  else
    C_OPT="$2"
fi

if [ -z "$3" ]
  then
    CXX_OPT=g++
  else
    CXX_OPT="$3"
fi

if [ -z "$4" ]
  then
    SEAL_OPT="v3.7.2"
  else
    SEAL_OPT="$4"
fi


CMAKE_OPTIONS_BASE="-DCMAKE_BUILD_TYPE=Release -DSEAL_USE_INTEL_HEXL=$HEXL_OPT -DCMAKE_C_COMPILER=$C_OPT -DCMAKE_CXX_COMPILER=$CXX_OPT -DCMAKE_INSTALL_PREFIX=. .."

cd reference-seal-backend/
echo -e "v\n0\n8\n2\nbeta" | tee cmake/third-party/FRONTEND.version
echo -e $SEAL_OPT | tee cmake/third-party/SEAL.version
rm -rf build
mkdir build
cd build
cmake $CMAKE_OPTIONS_BASE
make -j
