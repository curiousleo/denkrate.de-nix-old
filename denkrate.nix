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
  network.description = "Denkrate";

  denkrate = { config, pkgs, ...}: {
    networking.firewall.allowedTCPPorts = [ kibanaPort publicHTTPPort ];
    containers = {
      kibana = {
        autoStart = true;
        config = { config, pkgs, ...}: {
          services.elasticsearch = {
            enable = true;
            package = pkgs.elasticsearch5;
            port = elasticsearchPort;
            extraJavaOptions = [ "-Xms256m" "-Xmx256m" ];
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
            clientID = "2e356c103cd8e4647e9c";
            clientSecret = "5f7da877f4016b80dc8948878aa9d5877d6ac656";
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

    services.journalbeat = journalbeatConfig;
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "logs.denkrate.de" = {
          locations."/" = {
            proxyPass = "http://localhost:${toString kibanaOAuthProxyPort}";
          };
        };
        "metrics.denkrate.de" = {
          locations."/" = {
            proxyPass = "http://localhost:${toString netdataOAuthProxyPort}";
          };
        };
      };
      appendHttpConfig = ''
        server_names_hash_bucket_size 64;
      '';
    };
  };
}

