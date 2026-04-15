#!/bin/sh

# Setup spack
source ../spack/share/spack/setup-env.sh

# Load & Build dependencies
module load cuda/12.4.0 openmpi/5.0.8-gcc13.3.1 gcc/13.3.1-p20240614
spack env activate .
spack install

# Build clang and hpac-ml
spack load cmake
module load cuda/12.4.0 openmpi/5.0.8-gcc13.3.1 gcc/13.3.1-p20240614

base=/jet/home/bpanthi/ccr180031p/bpanthi/hpacml_build_gpu/ ./setup.sh

