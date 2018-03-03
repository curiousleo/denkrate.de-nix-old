let
  publicHttpsPort = 443;
  publicHttpPort = 80;
  journaldHttpGatewayPort = 19531;
  journaldHttpGatewayOAuthProxyPort = 4182;
  netdataPort = 19999;
  netdataOAuthProxyPort = 4181;
  elasticsearchPort = 9200;
in
{
  network.description = "Denkrate";

  denkrate = { config, pkgs, ...}: {
    networking.firewall.allowedTCPPorts = [ publicHttpPort publicHttpsPort ];
    services.netdata = {
      enable = true;
      configText = ''
        [global]
        bind to = 0.0.0.0:${toString netdataPort}
      '';
    };
    services.journald.enableHttpGateway = true;
    services.matrix-synapse = {
      enable = true;
      allow_guest_access = false;
      enable_registration = false;
      server_name = "matrix.denkrate.de";
      registration_shared_secret = "secret";
      database_type = "sqlite3";
      extraConfig = ''
        max_upload_size: "50M"
      '';
    };
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "logs.denkrate.de" = {
          forceSSL = true;
          enableACME = true;
          locations."/".proxyPass = "http://localhost:${toString journaldHttpGatewayOAuthProxyPort}";
        };
        "metrics.denkrate.de" = {
          forceSSL = true;
          enableACME = true;
          locations."/".proxyPass = "http://localhost:${toString netdataOAuthProxyPort}";
        };
        "denkrate.de" = {
          locations."/".extraConfig = "return 301 https://de.wikipedia.org/wiki/Karl_der_Gro%C3%9Fe;";
        };
        "127.0.0.1" = {
          listen = [ { addr = "127.0.0.1"; } ];
          locations."/nginx_status".extraConfig = ''
            stub_status on;
            allow 127.0.0.1;
            deny all;
          '';
        };
      };
      appendHttpConfig = ''
        server_names_hash_bucket_size 64;
      '';
    };

    containers = {
      journaldHttpGatewayOAuth = {
        autoStart = true;
        config = { config, pkgs, ... }: {
          services.oauth2_proxy = {
            enable = true;
            clientID = "2e356c103cd8e4647e9c";
            clientSecret = "5f7da877f4016b80dc8948878aa9d5877d6ac656";
            provider = "github";
            github.org = "denkrate-admin";
            cookie.secret = "2d3e06d2ab66275d0e69abe293e5592432f9a1bb7fd2df18b02e42cea6935f2d";
            cookie.secure = false;
            email.domains = [ "*" ];
            httpAddress = "http://0.0.0.0:${toString journaldHttpGatewayOAuthProxyPort}";
            upstream = "http://localhost:${toString journaldHttpGatewayPort}";
          };
        };
      };
      netdataOAuth = {
        autoStart = true;
        config = { config, pkgs, ... }: {
          services.oauth2_proxy = {
            enable = true;
            clientID = "6c0f9128b090d0b23629";
            clientSecret = "d72c99799375ca8c54bf6fdbfc927e94485f0ce3";
            provider = "github";
            github.org = "denkrate-admin";
            cookie.secret = "2d3e06d2ab66275d0e69abe293e5592432f9a1bb7fd2df18b02e42cea6935f2d";
            cookie.secure = false;
            email.domains = [ "*" ];
            httpAddress = "http://0.0.0.0:${toString netdataOAuthProxyPort}";
            upstream = "http://localhost:${toString netdataPort}";
          };
        };
      };
    };
  };
}

