{
  denkrate = { config, pkgs, ... }: {
    imports = [
      ./configuration.nix
      ./hardware-configuration.nix
    ];
    deployment.targetHost = "172.104.226.113";
  };
}

