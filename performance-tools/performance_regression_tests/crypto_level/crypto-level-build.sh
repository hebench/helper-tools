#!/bin/bash

set -e

mkdir -p repos-crypto-level-$RUNTAG
pushd repos-crypto-level-$RUNTAG

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


# SEAL
if [ "$SEAL" = true ];
then
    git clone https://github.com/microsoft/SEAL.git
    pushd SEAL
    git checkout $SEALVERSION

    if [ "$SEALHEXLVERSION" != "default" ] && [ "$HEXL" == "ON" ];
    then
        REPLACECOMMIT=$(grep -hnr "GIT_TAG" ./cmake/ExternalIntelHEXL.cmake | awk -F ' ' '{print $3}')
        sed -i "s/$REPLACECOMMIT/$SEALHEXLVERSION/" ./cmake/ExternalIntelHEXL.cmake
    fi

    ../../../remove-pause-blocks.sh .
    mkdir build && pushd build
    cmake -DCMAKE_INSTALL_PREFIX=./install -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=g++-10 -DCMAKE_C_COMPILER=gcc-10 -DSEAL_BUILD_BENCH=ON -DSEAL_USE_INTEL_HEXL=$HEXL ..
    make -j install
    AUTO_SEAL_PATH=$PWD
    popd && popd
fi

# PALISADE
if [ "$PALISADE" = true ];
then
    git clone https://gitlab.com/palisade/palisade-release.git
    pushd palisade-release
    git checkout $PALISADEVERSION

    if [ "$PALISADEHEXLVERSION" != "default" ] && [ "$HEXL" == "ON" ];
    then
        REPLACECOMMIT=$(grep -hnr "set(INTEL_HEXL_GIT_LABEL" ./third-party/intel-hexl/intel-hexl.cmake | awk -F ' ' '{print $3}')
        sed -i "s/$REPLACECOMMIT/$PALISADEHEXLVERSION)/" ./third-party/intel-hexl/intel-hexl.cmake
    fi

    mkdir build && pushd build
    cmake -DCMAKE_INSTALL_PREFIX=./install -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=g++-10 -DCMAKE_C_COMPILER=gcc-10 -DWITH_OPENMP=OFF -DBUILD_BENCHMARKS=ON -DWITH_INTEL_HEXL=$HEXL ..
    make -j install
    AUTO_PALISADE_PATH=$PWD
    popd && popd
fi


# helib
if [ "$HELIB" = true ];
then
    mkdir helib
    pushd helib
    if [ "$HEXL" == "ON" ];
    then
        git clone https://github.com/intel/hexl.git
    fi
    git clone https://github.com/google/benchmark.git google-benchmark
    git clone https://github.com/homenc/HElib.git

    if [ "$HEXL" == "ON" ];
    then
        pushd hexl
        git checkout $HELIBHEXLVERSION
        mkdir build && pushd build
        cmake -DCMAKE_INSTALL_PREFIX=./install -DCMAKE_C_COMPILER=gcc-10 -DCMAKE_CXX_COMPILER=g++-10 -DCMAKE_BUILD_TYPE=Release .. && make -j install
        popd && popd
    fi
    pushd google-benchmark
    git checkout $HELIBGBENCHVERSION
    mkdir build && pushd build
    cmake -DBENCHMARK_ENABLE_GTEST_TESTS=OFF -DBENCHMARK_ENABLE_INSTALL=ON -DCMAKE_INSTALL_PREFIX=./install -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc-10 -DCMAKE_CXX_COMPILER=g++-10 .. && make -j install
    popd && popd
    pushd HElib
    git checkout $HELIBVERSION
    mkdir build && pushd build
    if [ "$HEXL" == "ON" ];
    then
        cmake -DPACKAGE_BUILD=OFF -DCMAKE_INSTALL_PREFIX=./install -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc-10 -DCMAKE_CXX_COMPILER=g++-10 -DUSE_INTEL_HEXL=ON -DHEXL_DIR=$(realpath ../../hexl/build/install/lib/cmake/hexl-1.2.3) .. && make -j install
    else
        cmake -DPACKAGE_BUILD=OFF -DCMAKE_INSTALL_PREFIX=./install -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc-10 -DCMAKE_CXX_COMPILER=g++-10 -DUSE_INTEL_HEXL=$HEXL .. && make -j install
    fi
    popd && popd
    pushd HElib/benchmarks
    mkdir build && pushd build
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=g++-10 -Dhelib_DIR=$(realpath ../../build/install/share/cmake/helib) -Dbenchmark_DIR=$(realpath ../../../google-benchmark/build/install/lib/cmake/benchmark) .. && make -j
    AUTO_HELIB_PATH=$PWD
    popd && popd
    popd
fi

popd
popd
