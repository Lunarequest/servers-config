{
  description = "Deployment for shatterdome";

  # For accessing `deploy-rs`'s utility Nix functions
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cloudflareupdated = {
      url = "github:Lunarequest/cloudflareupdated";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    myblog = {
      type = "tarball";
      url = "https://codeberg.org/lunarequest/myblog/archive/mistress.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, nixpkgs, deploy-rs, sops-nix, cloudflareupdated, myblog }: {
      nixosConfigurations = {
        cherno-alpha = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/cherno-alpha/configuration.nix ];
        };
        scrappy = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [ ./hosts/scrappy/configuration.nix ];
        };
        striker-eureka = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/striker-eureka/configuration.nix ];
        };
      };

      deploy.nodes = {
        cherno-alpha = {
          sshUser = "root";
          hostname = "192.168.1.2";
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos
              self.nixosConfigurations.cherno-alpha;
          };
        };

        scrappy = {
          sshUser = "root";
          hostname = "192.168.1.56";
          profiles = {
            system = {
              user = "root";
              path = deploy-rs.lib.aarch64-linux.activate.nixos
                self.nixosConfigurations.scrappy;
            };
          };
        };

        striker-eureka = {
          sshUser = "root";
          hostname = "192.168.1.57";
          profiles = {
            system = {
              user = "root";
              path = deploy-rs.lib.x86_64-linux.activate.nixos
                self.nixosConfigurations.striker-eureka;
            };
          };
        };
      };

      # This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
