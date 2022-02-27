let
  hercules-ci-agent =
      builtins.fetchTarball "https://github.com/hercules-ci/hercules-ci-agent/archive/stable.tar.gz";
in
{ 
  cherno-alpha = {config, ... }: {
    imports = [ 
        ../../hosts/cherno-alpha/configuration.nix
        (hercules-ci-agent + "/module.nix")
    ];
    deployment.targetHost = "192.168.1.2";
    services.hercules-ci-agent.enable = true;
    services.hercules-ci-agent.concurrentTasks = 2;
    deployment.keys."cluster-join-token.key".keyFile = ../../hosts/cherno-alpha/secrets/cluster-join-token.key;
    deployment.keys."binary-caches.json".keyFile = ../../hosts/cherno-alpha/secrets/binary-caches.json;
  };
}
