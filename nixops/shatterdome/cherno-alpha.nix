{
  cherno-alpha = { config, ... }: {
    imports = [
      ../../hosts/cherno-alpha/configuration.nix
      <sops-nix/modules/sops>
    ];
    deployment.targetHost = "192.168.1.2";
    services.hercules-ci-agent = {
      enable = true;
      settings = { concurrentTasks = 2; };
    };
    sops.defaultSopsFile = ../../hosts/cherno-alpha/herculeci.yaml;
    sops.age.keyFile = "/home/nullrequest/.config/sops/age/keys.txt";
    sops.secrets.hercules-ci-agent.cluster-join-token = {};
    sops.secrets.hercules-ci-agent.binary-caches = {};
    deployment.keys."cluster-join-token.key".keyFile =
      /run/secrets/hercules-ci-agent/cluster-join-token;
    deployment.keys."binary-caches.json".keyFile =
      /run/secrets/hercules-ci-agent/binary-caches;
  };
}
