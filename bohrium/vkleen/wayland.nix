{ config, pkgs, ... }:
let
  start-sway = pkgs.writeShellScriptBin "start-sway" ''
    # first import environment variables from the login manager
    systemctl --user import-environment
    # then start the service
    exec systemctl --user start sway.service
  '';

  start-waybar = pkgs.writeShellScriptBin "start-waybar" ''
    export SWAYSOCK=/run/user/$(id -u)/sway-ipc.$(id -u).$(pgrep -f 'sway$').sock
    ${pkgs.waybar}/bin/waybar
  '';
in {
  home.packages = with pkgs; [
    grim wl-clipboard slurp brightnessctl
    start-sway
  ];

  systemd.user.sockets.dbus = {
    Unit = {
      Description = "D-Bus User Message Bus Socket";
    };
    Socket = {
      ListenStream = "%t/bus";
      ExecStartPost = "${pkgs.systemd}/bin/systemctl --user set-environment DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus";
    };
    Install = {
      WantedBy = [ "sockets.target" ];
      Also = [ "dbus.service" ];
    };
  };
  systemd.user.services.dbus = {
    Unit = {
      Description = "D-Bus User Message Bus";
      Requires = [ "dbus.socket" ];
    };
    Service = {
      ExecStart = "${pkgs.dbus}/bin/dbus-daemon --session --address=systemd: --nofork --nopidfile --systemd-activation";
      ExecReload = "${pkgs.dbus}/bin/dbus-send --print-reply --session --type=method_call --dest=org.freedesktop.DBus / org.freedesktop.DBus.ReloadConfig";
    };
    Install = {
      Also = [ "dbus.socket" ];
    };
  };

  systemd.user.services.sway = {
    Unit = {
      Description = "Sway - Wayland window manager";
      Documentation = [ "man:sway(5)" ];
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.sway}/bin/sway";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  systemd.user.services.mako = {
    Unit = {
      Description = "Mako notification daemon";
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${pkgs.mako}/bin/mako";
      RestartSec = 5;
      Restart = "always";
    };
  };
  xdg.configFile."mako/config".text = ''
    font="PragmataPro 13"
    background-color=#282c34
    text-color=#bbc2cf
    icons=0
    format=<b>%s</b>\n%b
    default-timeout=6000
    border-color=#98be65
    border-radius=10

    [urgency=low]
    border-color=#51afef
    default-timeout=4000

    [urgency=normal]
    border-color=#98be65
    default-timeout=6000

    [urgency=high]
    border-color=#ff6c6b
    default-timeout=8000
  '';

  systemd.user.services.clipman = {
    Unit = {
      Description = "Clipman clipboard manager";
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.local/share";
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store --max-items=1";
      RestartSec = 5;
      Restart = "always";
    };
  };

  systemd.user.services.kanshi = {
    Unit = {
      Description = "Kanshi dynamic display configuration";
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.kanshi}/bin/kanshi";
      RestartSec = 5;
      Restart = "always";
    };
  };

  xdg.configFile."kanshi/config".text = ''
    {
      output eDP-1 mode 1920x1080 position 0,0
    }
  '';

  systemd.user.services.waybar = {
    Unit = {
      Description = "Wayland bar for Sway and Wlroots based compositors";
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${start-waybar}/bin/start-waybar";
      RestartSec = 5;
      Restart = "always";
    };
  };
}
