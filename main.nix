{
  host,
  acme,
}:
let
  publicHttpPort = 80;
  publicHttpsPort = 443;
  privateSynapsePort = 8447;
  journaldHttpGatewayPort = 19531;
  journaldHttpGatewayOAuthProxyPort = 4182;
  netdataPort = 19999;
  netdataOAuthProxyPort = 4181;
  secrets = import ./secrets.nix;
  oauth2Proxy = { host, listen, upstream } : with secrets.oauth."${host}"; {
    enable = true;
    httpAddress = "http://127.0.0.1:${toString listen}";
    upstream = "http://127.0.0.1:${toString upstream}";
    provider = "github";
    github.org = "denkrate-admin";
    email.domains = [ "*" ];
    clientID = clientID;
    clientSecret = clientSecret;
    cookie.secret = cookieSecret;
    cookie.secure = acme;
  };
in
{
  network.description = "Denkrate";

  denkrate = { config, pkgs, ...}: {
    networking.firewall.allowedTCPPorts = [ publicHttpPort publicHttpsPort ];

    services.netdata = {
      enable = true;
      configText = ''
        [global]
        bind to = 127.0.0.1:${toString netdataPort}
      '';
    };
    services.journald.enableHttpGateway = true;
    #services.matrix-synapse = {
    #  enable = true;
    #  allow_guest_access = false;
    #  enable_registration = false;
    #  server_name = "matrix-internal.${host}";
    #  public_baseurl = "https://matrix-internal.${host}/";
    #  registration_shared_secret = secrets.synapse.sharedSecret;
    #  database_type = "sqlite3";
    #  listeners = [
    #    {
    #      bind_address = "127.0.0.1";
    #      port = privateSynapsePort;
    #      resources = [
    #        {
    #          compress = true;
    #          names = [ "client" "webclient" ];
    #        }
    #      ];
    #      tls = false;
    #      type = "http";
    #      x_forwarded = true;
    #    }
    #  ];
    #  extraConfig = ''
    #    max_upload_size: "50M"
    #  '';
    #};
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "logs.${host}" = {
          forceSSL = acme;
          enableACME = acme;
          locations."/".proxyPass = "http://127.0.0.1:${toString journaldHttpGatewayOAuthProxyPort}";
        };
        "metrics.${host}" = {
          forceSSL = acme;
          enableACME = acme;
          locations."/".proxyPass = "http://127.0.0.1:${toString netdataOAuthProxyPort}";
        };
        #"chat.${host}" = {
        #  forceSSL = acme;
        #  enableACME = acme;
        #  locations."/".proxyPass = "http://127.0.0.1:${toString privateSynapsePort}";
        #};
        "${host}" = {
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
          services.oauth2_proxy = oauth2Proxy {
            host = "logs.${host}";
            listen = journaldHttpGatewayOAuthProxyPort;
            upstream = journaldHttpGatewayPort;
          };
        };
      };
      netdataOAuth = {
        autoStart = true;
        config = { config, pkgs, ... }: {
          services.oauth2_proxy = oauth2Proxy {
            host = "metrics.${host}";
            listen = netdataOAuthProxyPort;
            upstream = netdataPort;
          };
        };
      };
    };
  };
}

