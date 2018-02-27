let
  publicHTTPPort = 80;
  kibanaPort = 5601;
  kibanaOAuthProxyPort = 4180;
  netdataPort = 19999;
  netdataOAuthProxyPort = 4181;
  elasticsearchPort = 9200;
  journalbeatConfig = {
    enable = true;
    extraConfig = ''
      journalbeat:
        seek_position: cursor
        cursor_seek_fallback: head
        write_cursor_state: true
        cursor_flush_period: 5s
        clean_field_names: true
        convert_to_numbers: false
        move_metadata_to_field: journal
        default_type: journal
      output.elasticsearch:
        enabled: true
        template.enabled: false
        hosts: ["localhost:${toString elasticsearchPort}"]
    '';
  };
in
{
  network.description = "XMPP server";

  xmpp = { config, pkgs, ...}: {
    networking.firewall.allowedTCPPorts = [ publicHTTPPort ];
    containers = {
      xmpp = {
        autoStart = true;
        config = { config, pkgs, ... }: {
          services.ejabberd.enable = true;
          services.journalbeat = journalbeatConfig;
        };
      };

      kibana = {
        autoStart = true;
        config = { config, pkgs, ...}: {
          services.elasticsearch = {
            enable = true;
            package = pkgs.elasticsearch5;
            port = elasticsearchPort;
          };
          services.journalbeat = journalbeatConfig;
          services.kibana = {
            enable = true;
            package = pkgs.kibana5;
            listenAddress = "0.0.0.0";
            port = kibanaPort;
          };
          services.oauth2_proxy = {
            enable = true;
            clientID = "c306667938ce52592a1a";
            clientSecret = "69b8ef30be9cb1b78e207873dcff190d1ac80d75";
            provider = "github";
            github.org = "denkrate-admin";
            cookie.secret = "9abe293e5592432f9a1bb7fd2df18b02e42cea6935f2d";
            cookie.secure = false;
            email.domains = [ "*" ];
            httpAddress = "http://0.0.0.0:${toString kibanaOAuthProxyPort}";
            upstream = "http://localhost:${toString kibanaPort}";
          };
        };
      };

      netdata = {
        autoStart = true;
        config = { config, pkgs, ... }: {
          services.journalbeat = journalbeatConfig;
          services.netdata = {
            enable = true;
            configText = ''
              [global]
              bind to = 0.0.0.0:${toString netdataPort}
            '';
          };
          services.oauth2_proxy = {
            enable = true;
            clientID = "4b22496b65a98f87140e";
            clientSecret = "8d5cddd2ae899ced42c9871e6f52afef9a9925e9";
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

      http = {
        autoStart = true;
        config = { config, pkgs, ...}: {
          services.journalbeat = journalbeatConfig;
          services.nginx = {
            enable = true;
            recommendedGzipSettings = true;
            recommendedOptimisation = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            virtualHosts = {};
            appendHttpConfig = ''
              server_names_hash_bucket_size 64;

              server {
                listen      ${toString publicHTTPPort};
                server_name logs.denkrate-dev.de;

                location / {
                  proxy_pass http://localhost:${toString kibanaOAuthProxyPort};
                }
              }

              server {
                listen      ${toString publicHTTPPort};
                server_name metrics.denkrate-dev.de;

                location / {
                  proxy_pass http://localhost:${toString netdataOAuthProxyPort};
                }
              }
            '';
          };
        };
      };
    };
  };
}

