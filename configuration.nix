# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nix-laptop"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland = {
      enable = true;
    };
  };


programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/tommy/mydots"; # sets NH_OS_FLAKE variable for you
  };


  #BTRFS options

fileSystems = {
  "/".options = [ "compress=zstd" ];
  "/home".options = [ "compress=zstd" ];
  "/nix".options = [ "compress=zstd" "noatime" ];
};

  # Enable the service and the firewall
  services.tailscale = {
    enable = true;
    extraSetFlags = ["--netfilter-mode=nodivert"]; # #For not to bypass firewall rules
    extraDaemonFlags = ["--no-logs-no-support"]; # Disable logging and telemetry
  };
  networking.nftables.enable = true;
  networking = {
    firewall = {
      enable = true;
      # Always allow traffic from your Tailscale network
      trustedInterfaces = ["tailscale0"];
      # Allow DHCP for libvirtd
      interfaces.virbr0.allowedUDPPorts = [53 67];
      # Allow the Tailscale UDP port through the firewall
      allowedUDPPorts = [config.services.tailscale.port];
    };
    # Enable NAT for traffic from the virbr0 interface
    nat.enable = true;
    nat.internalInterfaces = ["virbr0"];
  };

  # Force tailscaled to use nftables (Critical for clean nftables-only systems)
  # This avoids the "iptables-compat" translation layer issues.
  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];

  # Optimization: Prevent systemd from waiting for network online
  # (Optional but recommended for faster boot with VPNs)
  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;

  environment.variables.EDITOR = "vim";

  time.timeZone = "Europe/Budapest";

  #Hyprland with USWM
  programs.niri.enable = true;


  #For laptop power managment
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  services.fstrim.enable = true; # SSD Optimizer
  services.gvfs.enable = true; # For Mounting USB & More

  nixpkgs.config.allowUnfree = true;

  #Steam
  hardware.steam-hardware.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = false; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = false; # Open ports in the firewall for Steam Local Network Game Transfers
    gamescopeSession.enable = true;
    extraCompatPackages = [pkgs.proton-ge-bin];
  };

  programs.gamemode.enable = true;

  programs.gamescope = {
    enable = true;
    capSysNice = true;
    args = [
      "--rt"
      "--expose-wayland"
    ];
  };

  # Better latency for audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 256;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 256;
      };
    };
    extraConfig.pipewire-pulse."92-low-latency" = {
      context.modules = [
        {
          name = "libpipewire-module-protocol-pulse";
          args = {
            pulse.min.req = "256/48000";
            pulse.default.req = "256/48000";
            pulse.max.req = "256/48000";
            pulse.min.quantum = "256/48000";
            pulse.max.quantum = "256/48000";
          };
        }
      ];
    };
  };

  services.libinput.enable = true;

  #Virt
  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = ["tommy"];
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu = {
    swtpm.enable = true;
  };
  virtualisation.spiceUSBRedirection.enable = true;

  #user
  users.users.tommy = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "libvirtd"]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };

  environment.systemPackages = with pkgs; [
    #wget
    vim #basic editor
    librewolf #web browser
    lynx #TUI web browser
    brightnessctl #for laptop  brightness
    btop
    mpv #terminal video player
    imv #terminal image viwer
    usbutils
    playerctl
    pavucontrol #GUI for the audio
    yazi #teminal file manager
    foot #terminal
    keepassxc #password manager
    udiskie #for mounting USB
    geany #GUI text editor
    #thunderbird
    unzip
    ffmpeg #codecs
    yt-dlp #
    neomutt #terminal email program
    newsboat #terminal RSS feed reader
    #seahorse #gnupg GUI
    fuzzel #app laucher
    noctalia #desktop shell
    xwayland-satellite #Xorg compat. for Niri
    thunar #GUI file manager
    helix #IDE
    nixd #nix lang. for helix
    jujutsu #version control
    git #version control
    kdePackages.polkit-kde-agent-1 #polkit agent
    #heroic 
    #android-tools
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Privacy = "device";
        JustWorksRepairing = "always";
        Class = "0x000100";
        FastConnectable = true;
      };
    };
  };

  services.blueman.enable = true; # Bluetooth Support
  qt.enable = true; #Needed for theming

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  #services.gnome.gnome-keyring.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  system.stateVersion = "26.05"; # Did you read the comment?

}

