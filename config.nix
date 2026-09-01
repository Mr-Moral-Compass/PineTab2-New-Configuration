{
  config,
  pkgs,
  lib,
  ...
}:
{
  system.stateVersion = "26.05";

  documentation.nixos.enable = false;

  nix.settings.trusted-users = [ username ];

  users.users.${username} = {
    initialPassword = secrets.initialPassword;
    openssh.authorizedKeys.keys = [ secrets.authorizedKey ];
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    uid = 1000;
  };

  boot.kernelParams = [ "console=tty0" "console=ttyS2,1500000n8" "rootwait" "root=LABEL=NIXOS_SD" "rw" ];

  networking.networkmanager = {
    enable = true;
    # bes2600 powersave causes wifi stability issues, dmesg:
    # bes2600_wlan mmc2:0001:1: bes2600_pwr_enter_lp_mode, wait pm ind timeout
    wifi.powersave = false;
   };
  };
  hardware.sensor.iio.enable = true;

  services.openssh = {
    enable = builtins.stringLength secrets.authorizedKey > 0;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  services.automatic-timezoned.enable = true;
  services.geoclue2.enableDemoAgent = lib.mkForce true;

  services.flatpak.enable = true;
  services.printing.enable = true;

  services.avahi = {
    enable = true;
    openFirewall = true;
  };

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
  };
  services.pulseaudio.enable = false;

  security.rtkit.enable = true;

  environment.systemPackages = with pkgs; [
    firefox
    chromium
    htop
    #(pkgs.callPackage ./intro.nix {})
  ];

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

  networking.hostName = "${hostname}";
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };


  nixpkgs.config.allowUnfree = true;

  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  # https://github.com/systemd/systemd/pull/35304#issuecomment-3855146191
  # gnome autorotate expects 'normal' is the _display panel_ normal, but
  # mutter autoconfiguration rotates by 90deg.
  # compensating with gdctl for now, though it would be better to 'properly'
  # fix this.
  services.udev = {
    extraHwdb = ''
      sensor:modalias:*sc7a20:*
        ACCEL_MOUNT_MATRIX=1, 0, 0; 0, 0, 1; 0, 1, 0
    '';
    extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="1018", ATTRS{idProduct}=="1006", ENV{SYSTEMD_WANTS}+="landscape.service", TAG+="systemd"
    '';
  };
  systemd.services.landscape = {
    script = ''
      ${pkgs.mutter}/bin/gdctl set --logical-monitor --primary --monitor=DSI-1 --transform normal
    '';
    serviceConfig.User = username;
    serviceConfig.Type = "oneshot";
    environment = {
      "DBUS_SESSION_BUS_ADDRESS" = "unix:path=/run/user/${toString config.users.users."${username}".uid}/bus";
    };
  };
  environment.systemPackages = with pkgs; [
    gnomeExtensions.arc-menu
    gnomeExtensions.dash-to-dock
    gnomeExtensions.dash-to-panel
    gnomeExtensions.gjs-osk
    gnomeExtensions.one-window-wonderland
  ];

}
