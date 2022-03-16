{ config, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../common/security.nix
    ../common/nix-config.nix
  ];
  nixpkgs.config = {
    packageOverrides = pkgs: {
      blog = import (builtins.fetchTarball
        "https://codeberg.org/lunarequest/myblog/archive/mistress.tar.gz");
    };
  };

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  networking = {
    hostName = "cherno-alpha"; # Define your hostname.
    timeServers = [ "time.cloudflare.com" ]; # time servers for ntp
  };
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s25.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true; 

  users.users.root.initialHashedPassword = "";
  #users.motd = "";
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nullrequest = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    hugo
    neofetch
    nixfmt
    bpytop
    screen
    blog.packages.x86_64-linux.website
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.nginx = with pkgs; {
    enable = true;
    virtualHosts = {
      "nullrequest.com" = {
        onlySSL = true;
        root = "${blog.packages.x86_64-linux.website}";
        sslCertificate = "/etc/ssl/nullrequest.pem";
        sslCertificateKey = "/etc/ssl/nullrequest.key";
        locations = {
          "/" = {
            index = "index.html index.htm";
            extraConfig = ''
              location ~* \.(?:css|js)$ {
                      expires 1M;
                      add_header Cache-Control "public";
                      try_files $uri $uri/ =404;
              }
              location ~* \.(?:json)$ {
                      expires 1y;
                      add_header Cache-Control "public";
                      try_files $uri $uri/ =404;
              }
              try_files $uri $uri/ =404;
            '';
          };

        };
        extraConfig = "error_page 404 404.html;";
      };
      "git.nullrequest.com" = {
        onlySSL = true;
        sslCertificate = "/etc/ssl/nullrequest.pem";
        sslCertificateKey = "/etc/ssl/nullrequest.key";
        locations = {
          "/" = {
            proxyPass = "http://192.168.1.57:3000";
            extraConfig = ''
              proxy_redirect off;
              proxy_set_header Host $host:$server_port;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            '';
          };
        };
      };
      "nextcloud.nullrequest.com" = {
        onlySSL = true;
        sslCertificate = "/etc/ssl/nullrequest.pem";
        sslCertificateKey = "/etc/ssl/nullrequest.key";
        locations = {
          "/" = {
            proxyPass = "http://192.168.1.57";
            extraConfig = ''
              proxy_redirect off;
              proxy_set_header Host $host:$server_port;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            '';
          };

        };
      };
    };
  };
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 443 ];
  networking.firewall.allowedUDPPorts = [ 443 ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}

