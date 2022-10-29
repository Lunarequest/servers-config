{
  config,
  lib,
  ...
}: {
  imports = [./cloudflareupdated.nix];

  users.groups.cloudflareupdated = {};
}
