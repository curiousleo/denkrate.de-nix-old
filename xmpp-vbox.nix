{
  xmpp = { config, pkgs, ... }: {
    deployment.targetEnv = "virtualbox";
    deployment.virtualbox.headless = true;
    deployment.virtualbox.memorySize = 1024;
    deployment.virtualbox.vcpu = 2;
  };
  kibana = { config, pkgs, ... }: {
    deployment.targetEnv = "virtualbox";
    deployment.virtualbox.headless = true;
    deployment.virtualbox.memorySize = 8 * 1024;
    deployment.virtualbox.vcpu = 2;
  };
  netdata = { config, pkgs, ... }: {
    deployment.targetEnv = "virtualbox";
    deployment.virtualbox.headless = true;
    deployment.virtualbox.memorySize = 1024;
    deployment.virtualbox.vcpu = 2;
  };
  http = { config, pkgs, ... }: {
    deployment.targetEnv = "virtualbox";
    deployment.virtualbox.headless = true;
    deployment.virtualbox.memorySize = 1024;
    deployment.virtualbox.vcpu = 2;
  };
}

