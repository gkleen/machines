{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./users.nix
      ./networking.nix

      ./mailserver.nix
      ../seaborgium/secrets.nix
    ];

  nix = {
    nixPath = [
      "nixpkgs=${pkgs.path}"
      "nixpkgs-overlays=${./overlays}"
    ];

    binaryCaches = [
      "https://cache.nixos.org/"
      "https://ntqrfoedxliczzavdvuwhzvhkxbhxbpv.cachix.org"
    ];

    binaryCachePublicKeys = [
      "seaborgium.1:0cDg6+fSZ4Z4L7T24SPPal5VN4m51P5o2NDfUycbKmo="
      "freyr.1:d8VFt+9VtvwWAMKEGEERpZtWWh8Z3bDf+O2HrOLjBYQ="
      "ntqrfoedxliczzavdvuwhzvhkxbhxbpv.cachix.org-1:reOmDDtgU13EasMsy993sq3AuzGmXwfSxNTYPfGf3Hc="
    ];
  };

  nix.useSandbox = true;
  nix.trustedUsers = [ "root" ];

  time.timeZone = "UTC";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = [ ];
  networking.hostId = "c4decb69";
  environment.etc."machine-id".text = "c4decb69165ba83fa1167e065c1a5bc7";

  environment.systemPackages = with pkgs; [
    wget vim mosh tmux
  ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "yes";
  };

  security.sudo.configFile =
  ''
    Defaults:root,%wheel env_keep+=TERMINFO_DIRS
    Defaults:root,%wheel env_keep+=TERMINFO
    Defaults env_keep+=SSH_AUTH_SOCK
    Defaults !lecture,insults,rootpw

    root        ALL=(ALL) SETENV: ALL
    %wheel      ALL=(ALL:ALL) SETENV: ALL
  '';

  services.ntp.enable = false;
  services.chrony.enable = true;
  services.chrony.servers = [
    "0.north-america.pool.ntp.org"
    "1.north-america.pool.ntp.org"
    "2.north-america.pool.ntp.org"
    "3.north-america.pool.ntp.org"
  ];
  services.chrony.extraConfig = ''
    bindcmdaddress 127.0.0.1
    bindcmdaddress ::1
    port 0
    rtcsync
  '';

  services.udisks2.enable = false;
  services.xserver.enable = false;
  hardware.opengl.enable = false;
}
