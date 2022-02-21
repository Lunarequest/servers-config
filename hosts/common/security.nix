{ config, lib, pkgs, modulesPath, ... }:
{
  security = {
    audit.enable = true;
    polkit.enable = true;
    rtkit.enable = true;
  };
}