{
    striker-eureka = { ... }: { 
        imports = [ ../../hosts/striker-eureka/configuration.nix ];
        deployment.targetHost = "192.168.1.57"; 
    };
}
