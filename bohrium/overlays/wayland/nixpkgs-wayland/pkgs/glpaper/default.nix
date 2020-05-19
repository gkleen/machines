{ stdenv, fetchhg
, meson, ninja, pkgconfig
, wlroots, wayland, wayland-protocols
, pixman, libxkbcommon
, libudev, mesa_noglu, libX11
, libGL, libglvnd
}:

let
  metadata = import ./metadata.nix;
in
stdenv.mkDerivation rec {
  name = "glpaper-${version}";
  version = metadata.rev;

  src = fetchhg {
    url = "https://hg.sr.ht/~scoopta/glpaper";
    rev = version;
    sha256 = metadata.sha256;
  };

  nativeBuildInputs = [ meson ninja pkgconfig ];
  buildInputs = [
    wlroots wayland wayland-protocols wlroots
    pixman libxkbcommon libudev mesa_noglu libX11
    libGL libglvnd
  ];

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "GLPaper is a wallpaper program for wlroots based wayland compositors such as sway that allows you to render glsl shaders as your wallpaper";
    homepage    = "https://bitbucket.org/Scoopta/glpaper";
    platforms   = platforms.linux;
    maintainers = with maintainers; [ colemickens ];
  };
}
