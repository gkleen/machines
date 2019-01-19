pkgs: super: {
  ip2unix = pkgs.stdenv.mkDerivation rec {
    name = "ip2unix-${version}";

    version = let
      regex = " *project *\\([^)]*[ ,]+version *: *'([^']*)'.*";
      contents = builtins.readFile "${src}/meson.build";
    in builtins.head (builtins.match regex contents);

    src = pkgs.fetchFromGitHub {
      owner = "nixcloud";
      repo ="ip2unix";
      rev = "a8b3b204e403609851918b9afe714ceda128ed8c";
      sha256 = "0xxwx1ip5jhkq93b91gcqd1i4njlvl9c4vjzijbdhjrrzz971iwk";
    };

    nativeBuildInputs = [
      pkgs.meson pkgs.ninja pkgs.pkgconfig pkgs.asciidoc pkgs.libxslt.bin
      pkgs.docbook_xml_dtd_45 pkgs.docbook_xsl pkgs.libxml2.bin pkgs.docbook5
      pkgs.python3Packages.pytest pkgs.python3Packages.pytest-timeout
      pkgs.systemd
    ];
    buildInputs = [ pkgs.libyamlcpp ];

    doCheck = true;

    doInstallCheck = true;
    installCheckPhase = ''
      found=0
      for man in "$out/share/man/man1"/ip2unix.1*; do
        test -s "$man" && found=1
      done
      if [ $found -ne 1 ]; then
        echo "ERROR: Manual page hasn't been generated." >&2
        exit 1
      fi
    '';
  };
}
