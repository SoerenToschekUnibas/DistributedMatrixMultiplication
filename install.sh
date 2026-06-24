#!/bin/bash
#set -euo pipefail

PMT_REPO="https://git.astron.nl/RD/pmt.git"
INSTALL_PREFIX="${HOME}/lib_installed/pmt"
PMT_SRC_DIR="${HOME}/pmt"

mkdir -p "${HOME}/lib_installed"

git clone ${PMT_REPO} ${PMT_SRC_DIR}

cd "${PMT_SRC_DIR}"

ml purge
ml CMake
ml HDF5/1.14.6-gompi-2025b
ml CUDA/13.1.0

mkdir -p build
cd build

export LD_LIBRARY_PATH=/scicore/soft/easybuild/apps/CUDA/13.1.0/stubs/lib64:$LD_LIBRARY_PATH

echo "${INSTALL_PREFIX}"

cmake .. -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" -DPMT_BUILD_NVML=ON -DPMT_BUILD_RAPL=ON -DPMT_BUILD_BINARY=ON

make -j8
make install
