{pkgs, ...}:
{
  services.redshift = {
    enable = true;
    latitude = "51";
    longitude = "7";
    tray = true;
    temperature = {
      day = 6500;
      night = 3500;
    };
    package = pkgs.redshift-wlr;
    extraOptions = [ "-m wayland" ];
  };
}
