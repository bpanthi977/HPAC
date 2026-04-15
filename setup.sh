#!/bin/bash


#prefix=/jet/home/bpanthi/ccr180031p/bpanthi/hpacml_build_gpu/
prefix=$base/install
threads=5
current_dir=$(pwd)
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'

clang_bin=$prefix/bin/clang
approx_runtime_lib=$prefix/lib/libapprox.so
openmp_lib=$prefix/lib/libomp.so


if [ ! -f $clang_bin ]; then
  mkdir -p $base/build_compiler
  pushd $base/build_compiler
  cmake -G Ninja \
    -DCMAKE_INSTALL_PREFIX=$prefix/ \
    -DLLVM_CCACHE_BUILD='Off'\
    -DCMAKE_EXPORT_COMPILE_COMMANDS='On' \
    -DCMAKE_BUILD_TYPE='RelWithDebInfo' \
    -DLLVM_ENABLE_PROJECTS='clang' \
    -DLLVM_FORCE_ENABLE_STATS='On' \
    -DCMAKE_C_COMPILER='gcc' \
    -DCMAKE_CXX_COMPILER='g++' \
    -DLLVM_ENABLE_TERMINFO='Off' \
    -DLLVM_OPTIMIZED_TABLEGEN='On' \
    -DBUILD_SHARED_LIBS='On' \
    -DLLVM_ENABLE_ASSERTIONS='Off' \
    $current_dir/llvm

    ninja -j $threads
    ninja -j $threads install
    popd
    pushd $base
    rm -f hpac_env.sh
    echo "#!/bin/bash" > hpac_env.sh
    echo "export PATH=$prefix/bin/:\$PATH" >> hpac_env.sh
    echo "export LD_LIBRARY_PATH=$prefix/lib/:\$LD_LIBRARY_PATH" >> hpac_env.sh
    echo "export C_INCLUDE_PATH=$prefix/include:$C_INCLUDE_PATH" >> hpac_env.sh 
    echo "export CPLUS_INCLUDE_PATH=$prefix/include:$CPLUS_INCLUDE_PATH" >> hpac_env.sh 
    echo "export CC=clang" >> hpac_env.sh
    echo "export CPP=clang++" >> hpac_env.sh
    popd
fi

if [ ! -f $approx_runtime_lib ]; then

  full_path=$(python -c "import torch; print(torch.__file__)")
  torch_path=$(dirname "$full_path")
  torch_d=$(echo "$torch_path"/share/cmake/Torch)
  echo Torch directory: $torch_d


  gpuarchsm=$(python3 approx/approx_utilities/detect_arch.py $prefix)
  gpuarch=$(echo $gpuarchsm | cut -d ';' -f 1)
  gpusm=$(echo $gpuarchsm | cut -d ';' -f 2)

  # echo "export HPAC_GPU_ARCH=$gpuarch" >> hpac_env.sh
  # echo "export HPAC_GPU_SM=$gpusm" >> hpac_env.sh

  if [ ! $? -eq 0 ]; then

     echo "ERROR: No GPU architecture targets found, exiting..."

     exit 1
  else

     echo "Building for GPU architecture $gpuarch, compute capability $gpusm"
  fi
  source $base/hpac_env.sh


  mkdir $base/build_hpac
  pushd $base/build_hpac
  echo "PATH is " $PATH
  echo "Cmake version is:" $(cmake --version)
  CC=clang CPP=clang++ cmake -G Ninja \
      -DCMAKE_INSTALL_PREFIX=$prefix \
      -DLLVM_EXTERNAL_CLANG_SOURCE_DIR=${current_dir}/clang/ \
      -DPACKAGE_VERSION=17 \
      -DCMAKE_EXPORT_COMPILE_COMMANDS='On'\
      -DCMAKE_C_COMPILER=`which clang` \
      -DCMAKE_CXX_COMPILER=`which clang++` \
    -DCMAKE_BUILD_TYPE='Debug' \
    -DCAFFE2_USE_CUDNN='On' \
      -DTorch_DIR=$torch_d \
      -DMKL_THREADING=gnu_thread \
      -DCMAKE_CUDA_ARCHITECTURES=70 \
     $current_dir/approx
    ninja -j $threads
    ninja -j $threads install
    popd
    echo "export HPAC_LIBRARY_LOCATION=$prefix/lib" >> $base/hpac_env.sh
fi


if [ ! -f $openmp_lib ]; then
    mkdir -p $base/openmp/build/
    pushd $base/openmp/build/
      cmake -GNinja $current_dir/openmp/ -DLIBOMP_OMPD_SUPPORT=OFF -DCMAKE_INSTALL_PREFIX=$prefix
      ninja -j 20
      ninja install
    popd
fi
exit
