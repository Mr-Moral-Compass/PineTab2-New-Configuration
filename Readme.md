NixOS
NixOS.webp

NixOS is an immutable Linux distribution built around the Nix configuration language. The NixOS image for PineTab2 uses some downstream modifications to packages, such as an U-Boot package based on 2023.07-rc4 and a kernel also used by the Arch Linux Arm image.

This image is extremely basic and currently boots to a console. A NixOS configuration can be applied after booting to gain a full graphical system.
Download

    https://github.com/nabam/nixos-rockchip/releases

Notes

After booting, enable networking [with wpa_supplicant](https://nixos.org/manual/nixos/unstable/#sec-installation-manual-networking) and download (for example by entering `nix-shell -p wget` to get access to wget) this flake to the pinetab and place it at /etc/nixos/flake.nix:

    

Run the following commands:

    nmtui # to connect/activate Wifi SSID
> 
    nix-shell -p wget # May take a few minutes... like every command
> 
    wget https://raw.githubusercontent.com/Mr-Moral-Compass/PineTab2-New-Configuration/refs/heads/main/flake.nix
> 
    sudo cp flake.nix /etc/nixos/flake.nix
> 
    sudo su
> 
    cd /etc/nixos/
> 
    sudo nixos-rebuild switch --flake '.#pinetab2' --option experimental-features "nix-command flakes" --option substituters "https://cache.nixos.org https://nixos-rockchip.cachix.org" --option trusted-public-keys "nabam-nixos-rockchip.cachix.org-1:BQDltcnV8GS/G86tdvjLwLFz1WeFqSk7O9yl+DR0AVM="
> 
    reboot

After the first `nixos-rebuild`, you may need to reconnect to the network using `nmtui`.

After rebooting, there will be a new user account.

Note that booting can take a while, and does not show anything on the screen. After about 18 seconds the keyboard backlight turns on, then it's about 30 seconds until the first text appears on the screen, and another 10 seconds before the session manager shows up.
Default credentials
Default user 	pinetab2/changeme
