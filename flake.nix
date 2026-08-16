{
  description = "NixOS configuration for PineTab2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixos-rockchip = {
      url = "github:nabam/nixos-rockchip";
      inputs.nixpkgsStable.follows = "nixpkgs";
    };
  };

  # Use the binary cache provided by nixos-rockchip.
  # This is especially important for the PineTab2 kernel.
  nixConfig = {
    extra-substituters = [
      "https://nabam-nixos-rockchip.cachix.org"
    ];

    extra-trusted-public-keys = [
      "nabam-nixos-rockchip.cachix.org-1:BQDltcnV8GS/G86tdvjLwLFz1WeFqSk7O9yl+DR0AVM="
    ];
  };

  outputs = { self, nixpkgs, nixos-rockchip, ... }:
    let
      system = "aarch64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # PineTab2-specific Linux 6.18 kernel.
      #
      # This is the current PineTab2 kernel provided by
      # nixos-rockchip and is based on DanctNIX linux-pinetab2.
      pinetabKernel =
        nixos-rockchip.legacyPackages.${system}.kernel_linux_6_18_pinetab_stable;

    in
    {
      nixosConfigurations.pinetab2 = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          # PineTab2 hardware support.
          nixos-rockchip.nixosModules.dtOverlayPineTab2
          nixos-rockchip.nixosModules.bes2600
          nixos-rockchip.nixosModules.noZFS

          {
            nixpkgs.hostPlatform = system;

            # PineTab2-specific kernel.
            boot.kernelPackages = pinetabKernel;

            # ------------------------------------------------------------
            # Existing PineTab2 SD-card filesystem
            # ------------------------------------------------------------

            fileSystems."/" = {
              device = "/dev/disk/by-uuid/72475447-7667-4f89-bc4a-fd19046236b3";
              fsType = "ext4";
            };

            fileSystems."/boot" = {
              device = "/dev/disk/by-uuid/14D2-6235";
              fsType = "vfat";
            };

            # The SD image already has PineTab2 U-Boot.
            #
            # Do NOT install GRUB.
            # Generate an extlinux configuration that the existing
            # U-Boot can consume.
            boot.loader.grub.enable = false;
            boot.loader.generic-extlinux-compatible.enable = true;

            # This is an existing installation originally based on the
            # older Asonix/PineTab2 configuration.  Keep its state version
            # independent of the current nixpkgs release.
            system.stateVersion = "23.05";

            # ------------------------------------------------------------
            # System
            # ------------------------------------------------------------

            networking.hostName = "pinetab2";

            networking.networkmanager.enable = true;

            # ------------------------------------------------------------
            # Desktop
            # ------------------------------------------------------------

            services.xserver.enable = true;

            services.xserver.desktopManager.gnome.enable = true;
            services.xserver.displayManager.gdm.enable = true;

            environment.variables.MOZ_ENABLE_WAYLAND = "1";

            # ------------------------------------------------------------
            # Audio
            # ------------------------------------------------------------

            services.pipewire = {
              enable = true;
              alsa.enable = true;
              alsa.support32Bit = true;
              pulse.enable = true;
            };

            security.rtkit.enable = true;

            # ------------------------------------------------------------
            # Hardware / desktop services
            # ------------------------------------------------------------

            services.geoclue2.enable = true;

            services.automatic-timezoned.enable = true;

            services.flatpak.enable = true;

            services.printing.enable = true;

            services.avahi = {
              enable = true;
              nssmdns4 = true;
              openFirewall = true;
            };

            # ------------------------------------------------------------
            # Packages
            # ------------------------------------------------------------

            environment.systemPackages = with pkgs; [
              firefox
              htop
            ];

            # ------------------------------------------------------------
            # Nix
            # ------------------------------------------------------------

            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
          }
        ];
      };
    };
}
