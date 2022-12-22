#!/bin/bash


sudo apt install -y cmake
sudo timeout 10.0 sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt install -y gcc g++
sudo apt install -y gcc-9 g++-9
sudo apt install -y gcc-10 g++-10
sudo apt install -y gcc-11 g++-11
sudo apt install -y gcc-12 g++-12
sudo apt-get install libntl43 libntl-dev
sudo apt-get install libgmp-dev
sudo apt-get install autoconf
