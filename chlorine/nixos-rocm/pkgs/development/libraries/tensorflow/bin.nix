# This is adapted from the nixpkgs tensorflow wheel-based derivation.
# Usage note: This derivation includes a `setupHook` that sets
# `LD_PRELOAD` to avoid a crash due to conflicting libstdc++
# definitions. To benefit from this hook, add `tensorflow-rocm` to a
# `nix-shell` as its own entity rather than among a list of packages
# in a `withPackages` call. For example:
# `nix-shell -p 'python36.withPackages (ps: [ps.jupyter])' -p tensorflow-rocm`
# 
# You can then start `jupyter-notebook` as normal.
{ stdenv
, lib
, fetchurl
, buildPythonPackage
, astor
, gast
, numpy
, six
, termcolor
, protobuf
, absl-py
, grpcio
, mock
, backports_weakref
, enum34
, tensorflow-tensorboard
, zlib
, python, bootstrapped-pip
, symlinkJoin
, keras-applications
, keras-preprocessing
, writeText

# ROCm components
, hcc, hcc-unwrapped, hip, miopen-hip, miopengemm, rocrand, rocfft, rocblas
, rocr, rccl, cxlactivitylogger
}:
assert python.pythonVersion == "3.6";

# We keep this binary build for two reasons:
# - the source build doesn't work on Darwin.
# - the source build is currently brittle and not easy to maintain

let
  rocmtoolkit_joined = symlinkJoin {
    name = "unsplit_rocmtoolkit";
    paths = [ hcc hcc-unwrapped hip miopen-hip miopengemm
              rocrand rocfft rocblas rocr rccl cxlactivitylogger ];
  };

in buildPythonPackage rec {
  pname = "tensorflow";
  version = "1.12.0";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/48/2e/81a8961bfa57b5fd4409c7941b7756e69d9c4a6a3711ffc83db4183a8516/tensorflow_rocm-1.12.0-cp36-cp36m-manylinux1_x86_64.whl";
    sha256 = "0rm2wyd2a31mxhfhs3dq7kz76abxrsz595q1avdj7bcpfl208xi9";
  };

  propagatedBuildInputs = [  protobuf numpy termcolor grpcio six astor absl-py gast tensorflow-tensorboard keras-applications keras-preprocessing ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/${python.sitePackages}"
    export PYTHONPATH="$out/${python.sitePackages}:$PYTHONPATH"

    pushd dist
    echo 'manylinux1_compatible = True' > _manylinux.py

    PYTHONPATH=$PWD:PYTHONPATH ${bootstrapped-pip}/bin/pip install *.whl --no-index --prefix=$out --no-cache ${toString installFlags} --build tmpbuild
    popd

    runHook postInstall
  '';

  # Upstream has a pip hack that results in bin/tensorboard being in both tensorflow
  # and the propageted input tensorflow-tensorboard which causes environment collisions.
  # another possibility would be to have tensorboard only in the buildInputs
  # https://github.com/tensorflow/tensorflow/blob/v1.7.1/tensorflow/tools/pip_package/setup.py#L79
  postInstall = ''
    rm $out/bin/tensorboard
  '';

  installFlags = "--no-dependencies"; # tensorflow wants setuptools 39, can't allow that.
  # Note that we need to run *after* the fixup phase because the
  # libraries are loaded at runtime. If we run in preFixup then
  # patchelf --shrink-rpath will remove the cuda libraries.
  postFixup = let
    rpath = stdenv.lib.makeLibraryPath
              [ stdenv.cc.cc.lib zlib rocmtoolkit_joined ];
  in
  lib.optionalString (stdenv.isLinux) ''
    rrPath="$out/${python.sitePackages}/tensorflow/:$out/${python.sitePackages}/tensorflow/contrib/tensor_forest/:${rpath}"
    internalLibPath="$out/${python.sitePackages}/tensorflow/python/_pywrap_tensorflow_internal.so"
    find $out -name '*${stdenv.hostPlatform.extensions.sharedLibrary}' -exec patchelf --set-rpath "$rrPath" {} \;
  '';

  # The tensorflow shared library statically links some libstdc++
  # definitions that are not compatible with our libstdc++.so. To deal
  # with this, we preload our libstdc++ before running anything so
  # that other libraries we have built can interoperate with the
  # tensorflow library.
  setupHook = writeText "setup-hook" ''
    export LD_PRELOAD="${stdenv.cc.cc.lib}/lib/libstdc++.so.6''${LD_PRELOAD:+":$LD_PRELOAD"}"
  '';

  meta = with stdenv.lib; {
    description = "Computation using data flow graphs for scalable machine learning";
    homepage = http://tensorflow.org;
    license = licenses.asl20;
    maintainers = with maintainers; [ acowley ];
    platforms = with platforms; linux;
  };
}
