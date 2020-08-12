{ stdenv, fetchFromGitHub, cmake, rocm-runtime, rocm-thunk }:
stdenv.mkDerivation rec {
  name = "rocm-bandwidth";
  version = "3.5.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm_bandwidth_test";
    rev = "rocm-${version}";
    sha256 = "0bnms7h1qdvfkjiy537snjgjv96g4bjwqbxr9298hswdhk17pd3f";
  };
  nativeBuildInputs = [ cmake ];
  buildInputs = [ rocm-runtime rocm-thunk ];
  cmakeFlags = [
    "-DROCR_INC_DIR=${rocm-runtime}/include"
    "-DROCR_LIB_DIR=${rocm-runtime}/lib"
  ];
  # A non-void function doesn't return on all paths, so building with
  # -Werror fails with some compilers (eg. gcc 7.4.0)
  patchPhase = ''
    sed 's/\(add_executable(''${TEST_NAME} ''${Src})\)/\1\ntarget_compile_options(''${TEST_NAME} PRIVATE -Wno-return-type)/' -i CMakeLists.txt
  '';

  meta = {
    description = "Bandwidth test for ROCm";
    homepage = https://github.com/RadeonOpenCompute/rocm_bandwidth_test;
    license = stdenv.lib.licenses.ncsa;
    platforms = stdenv.lib.platforms.linux;
  };
}
