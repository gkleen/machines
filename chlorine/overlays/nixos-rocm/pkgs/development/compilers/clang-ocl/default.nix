{ stdenv, fetchFromGitHub, cmake
, rocm-cmake, rocm-opencl-runtime, rocm-device-libs, llvm, lld
, clang, clang-unwrapped }:
stdenv.mkDerivation rec {
  name = "clang-ocl";
  version = "3.5.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "clang-ocl";
    rev = "rocm-${version}";
    sha256 = "1majwzl3h9xx87rnk4bzl9vw0jf0fcwdknxvyk7snygaqyxjzqmj";
  };
  propagatedBuildInputs = [ lld ];
  nativeBuildInputs = [ cmake rocm-cmake rocm-opencl-runtime ];
  cmakeFlags = [
    "-DOPENCL_ROOT=${rocm-opencl-runtime}"
    "-DCLINFO=${rocm-opencl-runtime}/bin/clinfo"
    "-DCMAKE_C_COMPILER=${clang}/bin/clang"
    "-DCMAKE_CXX_COMPILER=${clang}/bin/clang++"
  ];
  patches = [ ./no-hcc.patch ];
  postPatch = ''
    sed -e 's,^CLANG_BIN=.*$,CLANG_BIN=${clang}/bin,' \
        -e 's,^BITCODE_DIR=.*$,BITCODE_DIR=${rocm-device-libs}/lib,' \
        -e 's,^OPENCL_INCLUDE=.*$,OPENCL_INCLUDE=$(echo | ''${CLANG_BIN}/clang -E -v -x c++ - |\& grep clang | tail -n1),' \
        -e 's,^CLANG=.*$,CLANG=${clang}/bin/clang,' \
        -e 's,^LLVM_LINK=.*$,LLVM_LINK=${llvm}/bin/llvm-link,' \
        -e 's,#!/bin/bash,#!${stdenv.shell},' \
        -i clang-ocl.in
  '';
}
