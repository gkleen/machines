{ stdenv, fetchFromGitHub
, meson, ninja, pkgconfig, scdoc
, wayland, wayland-protocols, sway, wlroots
, libpulseaudio, libinput, libnl, gtkmm3
, fmt, jsoncpp, libdbusmenu-gtk3
, glib
, spdlog
, mpd_clientlib
, gtk-layer-shell
, coreutils
, howard-hinnant-date
}:

let
  metadata = import ./metadata.nix;
in
stdenv.mkDerivation rec {
  name = "waybar-${version}";
  version = metadata.rev;

  src = fetchFromGitHub {
    owner = "Alexays";
    repo = "Waybar";
    rev = version;
    sha256 = metadata.sha256;
  };

  postPatch = ''
      date="$(date -d '${metadata.revdate}' +'%b %d %Y')"
      sed -i "s/\([ \t]\)version: '\(.*\)',/\1version: '\2-${stdenv.lib.substring 0 8 metadata.rev} ($date, branch \\\'${metadata.branch}\\\')',/" meson.build
  '';

  nativeBuildInputs = [ meson ninja pkgconfig scdoc ];
  buildInputs = [
    wayland wayland-protocols sway wlroots
    libpulseaudio libinput libnl gtkmm3
    fmt jsoncpp libdbusmenu-gtk3
    glib
    spdlog
    mpd_clientlib
    gtk-layer-shell
    coreutils
    howard-hinnant-date
  ];
  mesonFlags = [
    "-Dauto_features=enabled"
    "-Dout=${placeholder "out"}"
    "-Dsystemd=disabled"
  ];

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "Highly customizable Wayland Polybar like bar for Sway and Wlroots based compositors.";
    homepage    = https://github.com/Alexays/Waybar;
    license     = licenses.mit;
    platforms   = platforms.linux;
    maintainers = with maintainers; [ colemickens ];
  };
}

