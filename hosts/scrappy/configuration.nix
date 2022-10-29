# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../common/security.nix
    ./cachix.nix
    "${
      builtins.fetchTarball {
        url = "https://github.com/Mic92/sops-nix/archive/master.tar.gz";
        sha256 = "0qvbgq2di15x316w5c7r9xn5yw63l2k7h3vmfbh43ljb26f8amxb";
      }
    }/modules/sops"
    inputs.cloudflared.nixosModules.cloudflared
    inputs.arion.nixosModules.arion
  ];
  nixpkgs.config = {
    packageOverrides = pkgs: {
      blog = inputs.myblog.outputs.packages.${pkgs.system}.website;
    };
    allowUnfree = true;
  };

  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 2;
    };
    tmpOnTmpfs = true;
    loader.efi.canTouchEfiVariables = false;
    initrd = {
      compressor = "zstd";
      availableKernelModules = ["usbhid" "usb_storage"];
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  virtualisation = {
    docker.enable = false;
    podman = {
      enable = true;
      dockerSocket.enable = true;
      defaultNetwork.dnsname.enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
    };
  };

  virtualisation.arion = {
    backend = "podman-socket";
    projects.blog.settings = {
      # Specify you project here, or import it from a file.
      # NOTE: This does NOT use ./arion-pkgs.nix, but defaults to NixOS' pkgs.
      imports = [./arion-compose.nix];
    };
  };

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = false;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  hardware.enableRedistributableFirmware = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  networking = {
    hostName = "scrapy"; # Define your hostname.
    interfaces.eth0.useDHCP = true;
    nameservers = ["100.100.100.100" "8.8.8.8" "1.1.1.1"];
    hosts = {"127.0.0.1" = ["nextcloud"];};
  };

  nix = {
    settings = {
      trusted-users = ["root" "nullrequest"];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # Free up to 1GiB whenever there is less than 100MiB left.
    extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  services.tailscale.enable = true;

  services.hercules-ci-agent = {
    enable = false;
    settings = {
      concurrentTasks = 2;
      staticSecretsDirectory = "/run/secrets/";
    };
  };
  users.users.root.initialHashedPassword = "";
  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = {
  #   "eurosign:e";
  #   "caps:escape" # map caps to escape.
  # };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nullrequest = {
    isNormalUser = true;
    extraGroups = ["wheel" "podman"]; # Enable ‘sudo’ for the user.
  };

  # List packages installed in system profile. To search, run:
  # $ nix seaenableget
  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    wget
    cachix
    blog
    cloudflared
    screen
    docker-client
    nodejs-16_x
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  services.cloudflared = {
    enable = true;
    tokenFile = "/run/secrets/data";
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  # nginx as ingres server and blog
  services.nginx = with pkgs; {
    enable = true;
    virtualHosts = {
      "127.0.0.1" = {
        root = "${pkgs.blog}";
        sslCertificate = "/etc/ssl/nullrequest.pem";
        sslCertificateKey = "/etc/ssl/nullrequest.key";
        onlySSL = true;
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
      "nextcloud.nullrequest.com" = {
        onlySSL = true;
        listen = [
          {
            addr = "0.0.0.0";
            port = 8443;
          }
        ];
        sslCertificate = "/etc/ssl/nullrequest.pem";
        sslCertificateKey = "/etc/ssl/nullrequest.key";
        locations = {
          "/" = {
            proxyPass = "https://192.168.1.5";
            extraConfig = ''
              proxy_redirect     off;
              proxy_read_timeout 60s;

              proxy_set_header          Host            nextcloud.nullrequest.com;
              proxy_set_header          X-Real-IP       $remote_addr;
              proxy_set_header          X-Forwarded-For $proxy_add_x_forwarded_for;

              client_max_body_size 50M;
            '';
          };
        };
      };
    };
  };
  services.journald.extraConfig = "Storage=volatile";
  sops.defaultSopsFile = ./token;
  sops.secrets.data = {
    mode = "0440";
    owner = "cloudflared";
    group = "cloudflared";
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [443];
  networking.firewall.allowedUDPPorts = [443];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
