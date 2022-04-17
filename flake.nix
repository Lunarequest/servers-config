{
  description = "Deployment for my server cluster";

  # For accessing `deploy-rs`'s utility Nix functions
  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, deploy-rs, sops-nix }: {
    nixosConfigurations = {
      cherno-alpha = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./hosts/cherno-alpha/configuration.nix ];
      };
      striker-eureka = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
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
    checks =
      builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy)
      deploy-rs.lib;
  };
}
