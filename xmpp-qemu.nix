{
  xmpp = { config, pkgs, ... }: {
    deployment.targetEnv = "libvirtd";
    deployment.libvirtd.headless = true;
    deployment.libvirtd.memorySize = 4096;
    deployment.libvirtd.vcpu = 2;
  };
}

