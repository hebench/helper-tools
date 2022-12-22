#!/bin/bash

set -e

mkdir -p repos-application-level-$RUNTAG
pushd repos-application-level-$RUNTAG

if [ "$HEXL" == "ON" ];
then
    rm -rf ./hexl
    mkdir hexl
    pushd hexl
else
    rm -rf ./nohexl
    mkdir nohexl
    pushd nohexl
fi


# REFERENCE SEAL BACKEND
if [ "$REFSEAL" = true ];
then
    if [ "$REFSEALVERSION" == "default" ];
    then
        echo "The primary commit (e.g. of the backend) must be set to a know value (tag/branch/commit)"
        echo
        exit 1
    fi

    git clone https://github.com/hebench/reference-seal-backend.git
    pushd reference-seal-backend
    git checkout $REFSEALVERSION

    if [ "$REFSEALFRONTENDVERSION" != "default" ];
    then
        echo "$REFSEALFRONTENDVERSION" > ./cmake/third-party/FRONTEND.version
    fi
    if [ "$SEALVERSION" != "default" ];
    then
        echo "$SEALVERSION" > ./cmake/third-party/SEAL.version
    fi
    
    mkdir build && pushd build
    cmake -DCMAKE_INSTALL_PREFIX=./install -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=g++-10 -DCMAKE_C_COMPILER=gcc-10 -DSEAL_BUILD_BENCH=ON -DSEAL_USE_INTEL_HEXL=$HEXL ..
    make -j install
    AUTO_REFSEAL_PATH=$PWD/install
    popd && popd
fi

# REFERENCE PALISADE BACKEND
if [ "$REFPALISADE" = true ];
then
    if [ "$REFPALISADEVERSION" == "default" ];
    then
        echo "The primary commit (e.g. of the backend) must be set to a know value (tag/branch/commit)"
        echo
        exit 1
    fi

    git clone https://github.com/hebench/reference-palisade-backend.git
    pushd reference-palisade-backend
    git checkout $REFPALISADEVERSION

    if [ "$REFPALISADEFRONTENDVERSION" != "default" ];
    then
        echo "$REFPALISADEFRONTENDVERSION" > ./cmake/third-party/FRONTEND.version
    fi
    if [ "$PALISADEVERSION" != "default" ];
    then
        echo "$PALISADEVERSION" > ./cmake/third-party/PALISADE.version
    fi

    mkdir build && pushd build
    cmake -DCMAKE_INSTALL_PREFIX=./install -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=g++-10 -DCMAKE_C_COMPILER=gcc-10 -DWITH_OPENMP=OFF -DBUILD_BENCHMARKS=ON -DWITH_INTEL_HEXL=$HEXL ..
    make -j install
    AUTO_REFPALISADE_PATH=$PWD/install
    popd && popd
fi

popd
popd
