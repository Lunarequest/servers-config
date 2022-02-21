{   
    cherno-alpha = { ... }: { 
        imports = [ ../../hosts/cherno-alpha/configuration.nix ];
        deployment.targetHost = "192.168.1.2"; 
    }; 
}
