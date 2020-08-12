{ stdenv, fetchFromGitHub, cmake, llvm, lld, clang-unwrapped }:
stdenv.mkDerivation rec {
  name = "rocm-opencl-driver";
  version = "2.10.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCm-OpenCL-Driver";
    rev = "roc-${version}";
    sha256 = "1cwkqk8b3d7yhriyxag63b3ikcx0bxj8j6nsh959hdn8xsv3c9dy";
  };
  nativeBuildInputs = [ cmake ];
  cmakeFlags = [
    "-DLLVM_DIR=${llvm}/lib/cmake/llvm"
  ];
  enableParallelBuilding = true;
  buildInputs = [ llvm lld clang-unwrapped ];
  patchPhase = ''
    sed -e 's|include(AddLLVM)|include_directories(${llvm.src}/lib/Target/AMDGPU)|' \
        -e 's|add_subdirectory(src/unittest)||' \
        -i CMakeLists.txt
    sed 's|\(target_link_libraries(roc-cl opencl_driver\))|find_package(Clang CONFIG REQUIRED)\n\1 lldELF lldCommon clangCodeGen clangFrontend)|' -i src/roc-cl/CMakeLists.txt
  '';
}
