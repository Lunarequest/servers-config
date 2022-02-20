{ config, lib, pkgs, ... }:
with lib; {
  options.cloudflareupdated.services.cloudflareupdatedbin.enable =
    mkEnableOption "Activates service to update ip on cloudflare)";

  config = mkIf config.cloudflareupdated.services.cloudflareupdatedbin.enable {
        users.users.cloudflareupdated = {
          createHome = true;
          description = "github.com/Lunarequest/cloudflareupdated";
          isSystemUser = true;
          group = "cloudflareupdated";
          home = "/srv/cloudlareupdated/cloudflare";
          extraGroups = [ "keys" ];
        };

        deployment.keys.cloudflareupdated = {
          text = builtins.readFile ./secrets/settings.yaml;
          user = "cloudflareupdated";
          group = "cloudflareupdated";
          permissions = "0640";
        };

        systemd.services.cloudflareupdated = {
          wantedBy =  [ "multi-user.target" ];
          after = [ "cloudflareupdated-key.service" ];
          wants = [ "cloudflareupdated-key.service" ];


          serviceConfig = {
            Type = "oneshot";
            User = "cloudflareupdated";
            Group = "cloudflareupdated";
          };

          script = let cloudflareupdated = pkgs.cloudflareupdated.cloudflareupdatedbin.defaultPackage.x86_64-linux;
            in ''
              exec ${cloudflareupdated}/bin/cloudflareupdated -c /run/keys/cloudflareupdated
            '';
        };

        systemd.timers.cloudflareupdated = {
            wantedBy = [ "timers.target" ];
            partOf = [ "cloudflareupdated.service" ];
            timerConfig = {
              OnBootSec=120;
              OnUnitActiveSec=1200;
        };
      };
  };
}