{ config, lib, pkgs, ... }:

with lib;

let
  kibanaPort = 5601;
  netdataPort = 19999;
  netdataOauthProxyPort = 4180;
  kibanaOauthProxyPort = 4181;
in
{ 
  boot.isContainer = true;

  containers.kibana.autoStart = true;
  containers.kibana.config = {
    services.elasticsearch = {
      enable = true;
      package = pkgs.elasticsearch5;
    };
    services.kibana = {
      enable = true;
      package = pkgs.kibana5;
      listenAddress = "localhost";
      port = kibanaPort;
    };
    services.journalbeat = {
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
          hosts: ["localhost:9200"]
      '';
    };
    services.oauth2_proxy = {
      enable = true;
      clientID = "c306667938ce52592a1a";
      clientSecret = "69b8ef30be9cb1b78e207873dcff190d1ac80d75";
      provider = "github";
      github.org = "denkrate-admin";
      cookie.secret = "2d3e06d2ab66275d0e69abe293e5592432f9a1bb7fd2df18b02e42cea6935f2d";
      cookie.secure = false;
      email.domains = [ "*" ];
      httpAddress = "http://localhost:${toString kibanaOauthProxyPort}";
      upstream = "http://localhost:${toString kibanaPort}";
    };
  };
  containers.netdata.autoStart = true;
  containers.netdata.config = {
    services.journalbeat = {
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
          hosts: ["localhost:9200"]
      '';
    };
    services.netdata = {
      enable = true;
      configText = ''
        [global]
          bind to = localhost-netdata:${toString netdataPort}
      '';
    };
    services.oauth2_proxy = {
      enable = true;
      clientID = "c306667938ce52592a1a";
      clientSecret = "69b8ef30be9cb1b78e207873dcff190d1ac80d75";
      provider = "github";
      github.org = "denkrate-admin";
      cookie.secret = "2d3e06d2ab66275d0e69abe293e5592432f9a1bb7fd2df18b02e42cea6935f2d";
      cookie.secure = false;
      email.domains = [ "*" ];
      httpAddress = "http://localhost-oauth:${toString netdataOauthProxyPort}";
      upstream = "http://localhost-http:${toString netdataPort}";
    };
  };


  networking.hostName = mkDefault "xmpp-test";
  networking.useDHCP = false;
  networking.firewall.allowedTCPPorts = [ 80 443 4180 ];

  services.ejabberd.enable = true;
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = {};
    appendHttpConfig = ''
      server {
        listen      80;
        server_name status.denkrate-dev.de;

        location /logs/ {
            proxy_pass http://localhost:${toString kibanaOauthProxyPort};
        }
        location /metrics/ {
            proxy_pass http://localhost:${toString netdataOauthProxyPort};
        }
      }
    '';
    # virtualHosts."logs.denkrate-dev.de" = {
    #   locations."/".proxyPass = "http://localhost:${toString kibanaPort}";
    # };
    # virtualHosts."metrics.denkrate-dev.de" = {
    #   locations."/".proxyPass = "http://localhost:${toString netdataPort}";
    # };
  };
}

