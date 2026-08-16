{
  description = "NixOS configuration for PineTab2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixos-rockchip = {
      url = "github:nabam/nixos-rockchip";
      inputs.nixpkgsStable.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-rockchip, ... }:
    let
      system = "aarch64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      pinetabKernel =
        nixos-rockchip.legacyPackages.${system}.kernel_linux_7_0_pinetab_unstable;

    in
    {
      nixosConfigurations.pinetab2 = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          nixos-rockchip.nixosModules.dtOverlayPineTab2
          nixos-rockchip.nixosModules.bes2600
          nixos-rockchip.nixosModules.noZFS

          {
            nixpkgs.hostPlatform = system;

            boot.kernelPackages = pinetabKernel;

            boot.kernelParams = [
              "root=/dev/mmcblk1p2"
              "rw"
              "rootwait"
            ];

            system.stateVersion = "26.05";

            networking.hostName = "pinetab2";
            networking.networkmanager.enable = true;

            services.xserver.enable = true;

            services.xserver.desktopManager.gnome.enable = true;
            services.xserver.displayManager.gdm.enable = true;

            services.pipewire = {
              enable = true;
              alsa.enable = true;
              alsa.support32Bit = true;
              pulse.enable = true;
            };

            security.rtkit.enable = true;

            services.geoclue2.enable = true;
            services.automatic-timezoned.enable = true;

            services.flatpak.enable = true;

            services.printing.enable = true;

            services.avahi = {
              enable = true;
              nssmdns4 = true;
              openFirewall = true;
            };

            environment.variables.MOZ_ENABLE_WAYLAND = "1";

            environment.systemPackages = with pkgs; [
              firefox
              htop
            ];

            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
          }
        ];
      };
    };
}
