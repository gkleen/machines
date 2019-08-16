{ stdenv, mkDerivation, fetchurl, cmake, ninja, coin3d, xercesc, ode, eigen, qt5, opencascade-occt, gts
, hdf5, vtk, medfile, zlib, python3Packages, swig, gfortran, libXmu
, soqt, libf2c, libGLU, makeWrapper, pkgconfig, libspnav
, mpi ? null }:

assert mpi != null;

let
  pythonPackages = python3Packages;
in mkDerivation rec {
  name = "freecad-${version}";
  version = "0.18.3";

  src = fetchurl {
    url = "https://github.com/FreeCAD/FreeCAD/archive/${version}.tar.gz";
    sha256 = "07j7azgnicmd8cqnyskp15y44ykgj5qqz5y3w1jdynrv3yrvk1kz";
  };

  nativeBuildInputs = [ cmake ninja pkgconfig pythonPackages.pyside2-tools ];
  buildInputs = [ cmake coin3d xercesc ode eigen opencascade-occt gts
    zlib swig gfortran soqt libf2c makeWrapper mpi vtk hdf5 medfile
    libGLU libXmu libspnav
  ] ++ (with qt5; [
    qtbase qttools qtwebkit qtx11extras
  ]) ++ (with pythonPackages; [
    matplotlib pycollada shiboken2 pyside2 pyside2-tools pivy python boost
  ]);

  cmakeFlags = [
    "-DBUILD_QT5=ON"
    "-DSHIBOKEN_INCLUDE_DIR=${pythonPackages.shiboken2}/include"
    "-DSHIBOKEN_LIBRARY=Shiboken2::libshiboken"
    ("-DPYSIDE_INCLUDE_DIR=${pythonPackages.pyside2}/include"
      + ";${pythonPackages.pyside2}/include/PySide2/QtCore"
      + ";${pythonPackages.pyside2}/include/PySide2/QtWidgets"
      + ";${pythonPackages.pyside2}/include/PySide2/QtGui"
      )
    "-DPYSIDE_LIBRARY=PySide2::pyside2"
  ];

  # This should work on both x86_64, and i686 linux
  preBuild = ''
    export NIX_LDFLAGS="-L${gfortran.cc}/lib64 -L${gfortran.cc}/lib $NIX_LDFLAGS";
  '';

  # Their main() removes PYTHONPATH=, and we rely on it.
  preConfigure = ''
    sed '/putenv("PYTHONPATH/d' -i src/Main/MainGui.cpp

    qtWrapperArgs+=(--prefix PYTHONPATH : "$PYTHONPATH")
  '';

  qtWrapperArgs = [
    "--set COIN_GL_NO_CURRENT_CONTEXT_CHECK 1"
  ];

  postFixup = ''
    mv $out/share/doc $out
  '';

  meta = with stdenv.lib; {
    description = "General purpose Open Source 3D CAD/MCAD/CAx/CAE/PLM modeler";
    homepage = "https://www.freecadweb.org/";
    license = licenses.lgpl2Plus;
    maintainers = with maintainers; [ viric gebner ];
    platforms = platforms.linux;
  };
}
