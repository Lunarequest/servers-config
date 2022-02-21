{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./services
      ../common/security.nix
    ];

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      cloudflareupdated = {
        cloudflareupdatedbin = import (builtins.fetchTarball 
          "https://github.com/Lunarequest/cloudflareupdated/archive/refs/heads/mistress.tar.gz"
          );
      };
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
  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

  };

  networking = { 
        hostName = "striker-eureka"; # Define your hostname.
        timeServers = [ "time.cloudflare.com" ];
  };
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp1s0.useDHCP = true;
  networking.interfaces.wlp3s0.useDHCP = true;

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
  
  services.printing = { 
        enable = true; 
        drivers = with pkgs; [ epson-201401w ];
        browsing = true;
        listenAddresses = [ "*:631" ];
        allowFrom = [ "all" ];
        defaultShared = true;
  };
  services.avahi = { 
        enable = true;
        publish = {
                enable = true;
                userServices = true;
        };
  };
  cloudflareupdated.services = {
    cloudflareupdatedbin.enable = true;
  };
  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  users.users.root.initialHashedPassword = "";
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nullrequest = {
     isNormalUser = true;
     extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
     subUidRanges = [{
      startUid = 100000;
      count = 65536;
    }];
    subGidRanges = [{
      startGid = 100000;
      count = 65536;
    }];
  };
  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
    };
  };
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     wget
     git
     gcc
     usbutils
     cargo 
     openssl
     binutils
     pkgconfig
     screen
     ghostscript
  ];
  environment.sessionVariables = {
        PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  };
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  
  # List services that you want to enable:
  # postgresql for nextcloud
  services.postgresql = {
        enable = true;
        package = pkgs.postgresql;
        enableTCPIP = true;
        authentication = "local   all             postgres                                peer";
        ensureDatabases = [ 
                "nextcloud"
                "gogs-db"
        ];
        ensureUsers = [
         { 
                name = "nextcloud";
                ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
         }
        ];

  };
  systemd.services."nextcloud-setup" = {
    requires = ["postgresql.service"];
    after = ["postgresql.service"];
  };
  # nextcloud setup
  services.nextcloud = {
        enable = true;
        https = true;
        hostName = "nextcloud.nullrequest.com";
        package = pkgs.nextcloud23;
        config = {
                dbtype = "pgsql";
                dbuser = "nextcloud";
                dbhost = "/run/postgresql";
                adminuser = "nullrequest";
                adminpassFile = "/etc/nextcloudpassword";
        };
        appstoreEnable = true;
  };
  #gogs
  services.gogs = {
        enable = true;
        domain = "git.nullrequest.com";
        useWizard = true;
        rootUrl = "https://git.nullrequest.com/";
        database = {
                type = "postgres";
                port = 5432;
                host = "/run/postgresql";
                name = "gogs";
                user = "gogsdb";
        };
        cookieSecure = true;
        appName = "luna's git server";
  };
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 443 631 3000 8080 ];
  networking.firewall.allowedUDPPorts = [ 631 ];
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

