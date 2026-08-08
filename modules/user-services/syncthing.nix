{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.services.syncthing;

  # Map an enabled folder attr-name to the set of peer device IDs it shares with,
  # each resolved to the full syncthing device ID from cfg.devices.
  folderDeviceIds = folderName: let
    folder = cfg.folders.${folderName};
    devId = name: cfg.devices.${name}.id;
  in
    map devId folder.devices;

  # Render one <folder> block (sendreceive with trashcan versioning).
  renderFolder = name: ''
    <folder id="${cfg.folders.${name}.id}" label="${cfg.folders.${name}.label}" path="${cfg.folders.${name}.path}" type="sendreceive" rescanIntervalS="3600" fsWatcherEnabled="true" fsWatcherDelayS="10" fsWatcherTimeoutS="0" ignorePerms="false" autoNormalize="true">
        <filesystemType>basic</filesystemType>
        ${lib.concatMapStringsSep "\n" (id: ''      <device id="${id}" introducedBy="">
          <encryptionPassword></encryptionPassword>
      </device>'') (folderDeviceIds name)}
        <minDiskFree unit="%">1</minDiskFree>
        <versioning>
            <cleanupIntervalS>3600</cleanupIntervalS>
            <fsPath></fsPath>
            <fsType>basic</fsType>
            <params>
                <param key="cleanoutDays" val="0"></param>
            </params>
        </versioning>
        <copiers>0</copiers>
        <pullerMaxPendingKiB>0</pullerMaxPendingKiB>
        <hashers>0</hashers>
        <order>random</order>
        <ignoreDelete>false</ignoreDelete>
        <scanProgressIntervalS>0</scanProgressIntervalS>
        <pullerPauseS>0</pullerPauseS>
        <pullerDelayS>1</pullerDelayS>
        <maxConflicts>10</maxConflicts>
        <disableSparseFiles>false</disableSparseFiles>
        <paused>false</paused>
        <markerName>.stfolder</markerName>
        <copyOwnershipFromParent>false</copyOwnershipFromParent>
        <modTimeWindowS>0</modTimeWindowS>
        <maxConcurrentWrites>16</maxConcurrentWrites>
        <disableFsync>false</disableFsync>
        <blockPullOrder>standard</blockPullOrder>
        <copyRangeMethod>standard</copyRangeMethod>
        <caseSensitiveFS>false</caseSensitiveFS>
        <junctionsAsDirs>false</junctionsAsDirs>
        <syncOwnership>false</syncOwnership>
        <sendOwnership>false</sendOwnership>
        <syncXattrs>false</syncXattrs>
        <sendXattrs>false</sendXattrs>
        <xattrFilter>
            <maxSingleEntrySize>1024</maxSingleEntrySize>
            <maxTotalSize>4096</maxTotalSize>
        </xattrFilter>
    </folder>
  '';

  # Render one <device> block for a peer device.
  renderDevice = name: let
    dev = cfg.devices.${name};
    compression =
      if dev ? compression
      then dev.compression
      else "metadata";
  in ''
    <device id="${dev.id}" name="${dev.name or name}" compression="${compression}" introducer="false" skipIntroductionRemovals="false" introducedBy="">
        <address>dynamic</address>
        <paused>false</paused>
        <autoAcceptFolders>false</autoAcceptFolders>
        <maxSendKbps>0</maxSendKbps>
        <maxRecvKbps>0</maxRecvKbps>
        <maxRequestKiB>0</maxRequestKiB>
        <untrusted>false</untrusted>
        <remoteGUIPort>0</remoteGUIPort>
        <numConnections>0</numConnections>
    </device>
  '';

  # The set of folders to actually enable on this host.
  enabledFolderNames =
    if cfg.enabledFolders == null
    then builtins.attrNames cfg.folders
    else cfg.enabledFolders;

  folderXml = lib.concatMapStringsSep "\n" renderFolder enabledFolderNames;
  deviceXml = lib.concatMapStringsSep "\n" renderDevice (builtins.attrNames cfg.devices);

  # Declarative seed config.xml. syncthing upgrades/expands this on first load,
  # so we only need the folders/devices/gui/options that matter; missing fields
  # get standard defaults.
  seedConfigXml = pkgs.writeText "syncthing-config.xml" ''
    <configuration version="52">
    ${folderXml}
    ${deviceXml}
    <gui enabled="true" tls="false" sendBasicAuthPrompt="false">
        <address>127.0.0.1:8384</address>
        <metricsWithoutAuth>false</metricsWithoutAuth>
        <apikey></apikey>
        <theme>default</theme>
        <sessionCookieDurationS>604800</sessionCookieDurationS>
        <sessionCookiePath>/</sessionCookiePath>
    </gui>
    <ldap></ldap>
    <options>
        <listenAddress>default</listenAddress>
        <globalAnnounceServer>default</globalAnnounceServer>
        <globalAnnounceEnabled>true</globalAnnounceEnabled>
        <localAnnounceEnabled>true</localAnnounceEnabled>
        <localAnnouncePort>21027</localAnnouncePort>
        <localAnnounceMCAddr>[ff12::8384]:21027</localAnnounceMCAddr>
        <maxSendKbps>0</maxSendKbps>
        <maxRecvKbps>0</maxRecvKbps>
        <reconnectionIntervalS>20</reconnectionIntervalS>
        <relaysEnabled>true</relaysEnabled>
        <relayReconnectIntervalM>10</relayReconnectIntervalM>
        <startBrowser>true</startBrowser>
        <natEnabled>true</natEnabled>
        <natLeaseMinutes>60</natLeaseMinutes>
        <natRenewalMinutes>30</natRenewalMinutes>
        <natTimeoutSeconds>10</natTimeoutSeconds>
        <urAccepted>-1</urAccepted>
        <urSeen>3</urSeen>
        <urUniqueID></urUniqueID>
        <urURL>https://data.syncthing.net/newdata</urURL>
        <urPostInsecurely>false</urPostInsecurely>
        <urInitialDelayS>1800</urInitialDelayS>
        <autoUpgradeIntervalH>12</autoUpgradeIntervalH>
        <upgradeToPreReleases>false</upgradeToPreReleases>
        <keepTemporariesH>24</keepTemporariesH>
        <cacheIgnoredFiles>false</cacheIgnoredFiles>
        <progressUpdateIntervalS>5</progressUpdateIntervalS>
        <limitBandwidthInLan>false</limitBandwidthInLan>
        <minHomeDiskFree unit="%">1</minHomeDiskFree>
        <releasesURL>https://upgrades.syncthing.net/meta.json</releasesURL>
        <overwriteRemoteDeviceNamesOnConnect>false</overwriteRemoteDeviceNamesOnConnect>
        <tempIndexMinBlocks>10</tempIndexMinBlocks>
        <unackedNotificationID>authenticationUserAndPassword</unackedNotificationID>
        <trafficClass>0</trafficClass>
        <setLowPriority>true</setLowPriority>
        <maxFolderConcurrency>0</maxFolderConcurrency>
        <crashReportingURL>https://crash.syncthing.net/newcrash</crashReportingURL>
        <crashReportingEnabled>true</crashReportingEnabled>
        <stunKeepaliveStartS>180</stunKeepaliveStartS>
        <stunKeepaliveMinS>20</stunKeepaliveMinS>
        <stunServer>default</stunServer>
        <maxConcurrentIncomingRequestKiB>0</maxConcurrentIncomingRequestKiB>
        <announceLANAddresses>true</announceLANAddresses>
        <sendFullIndexOnUpgrade>false</sendFullIndexOnUpgrade>
        <auditEnabled>false</auditEnabled>
        <auditFile></auditFile>
        <connectionLimitEnough>0</connectionLimitEnough>
        <connectionLimitMax>0</connectionLimitMax>
        <connectionPriorityTcpLan>10</connectionPriorityTcpLan>
        <connectionPriorityQuicLan>20</connectionPriorityQuicLan>
        <connectionPriorityTcpWan>30</connectionPriorityTcpWan>
        <connectionPriorityQuicWan>40</connectionPriorityQuicWan>
        <connectionPriorityRelay>50</connectionPriorityRelay>
        <connectionPriorityUpgradeThreshold>0</connectionPriorityUpgradeThreshold>
    </options>
    <defaults>
        <folder id="" label="" path="" type="sendreceive" rescanIntervalS="3600" fsWatcherEnabled="true" fsWatcherDelayS="10" fsWatcherTimeoutS="0" ignorePerms="false" autoNormalize="true">
            <filesystemType>basic</filesystemType>
            <minDiskFree unit="%">1</minDiskFree>
        </folder>
        <device id="" compression="metadata" introducer="false" skipIntroductionRemovals="false" introducedBy="">
            <address>dynamic</address>
            <paused>false</paused>
            <autoAcceptFolders>false</autoAcceptFolders>
            <maxSendKbps>0</maxSendKbps>
            <maxRecvKbps>0</maxRecvKbps>
            <maxRequestKiB>0</maxRequestKiB>
            <untrusted>false</untrusted>
            <remoteGUIPort>0</remoteGUIPort>
            <numConnections>0</numConnections>
        </device>
        <ignores></ignores>
    </defaults>
    </configuration>
  '';
in {
  options.user.services.syncthing = {
    enable = lib.mkEnableOption "Syncthing service";

    user = lib.mkOption {
      type = lib.types.str;
      default = config.user.name;
      description = "User to run Syncthing as";
    };

    devices = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {
        desktop.id = "KII4S2Y-KWA6M4K-MCQAUOO-C6PMX4L-V5JVDPW-HHZF52D-HP57BNH-EKCCZQC";
        laptop.id = "EAHAPON-XKBJVGI-44SGTXR-WU6BF5U-WZKHJXS-7QNTBHQ-D4ICOVA-I346HQ7";
        framework.id = "ICJT4KW-Q4KTA73-W2CO2HS-DCG6AFG-NXZTZPA-UI34ITG-4LW4NOT-BGB36AB";
        server.id = "GY3T3SL-3JOOX3I-2SE72PF-V6ZSTIE-QI4EIYK-OBL6IDV-4IWLDDG-VM2ATAG";
        phone = {
          id = "JYAIN4T-MXQYDAP-2M6CSKX-KKRYVJC-5GMSRYP-LSZRRRV-QSOWY7W-YNQGOAC";
          name = "SM-F946W";
          compression = "never";
        };
      };
      description = "Syncthing devices configuration";
    };

    folders = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {
        tokens = {
          id = "bv79n-fh4kx";
          label = "Tokens";
          path = "~/Tokens";
          devices = ["desktop" "laptop" "framework" "server" "phone"];
          versioning.type = "trashcan";
        };
        music = {
          id = "oty33-aq3dt";
          label = "Music";
          path = "~/Music";
          devices = ["desktop" "laptop" "server" "phone"];
          versioning.type = "trashcan";
        };
        dcim = {
          id = "ti9yk-zu3xs";
          label = "DCIM";
          path = "~/DCIM";
          devices = ["desktop" "laptop" "server" "phone"];
          versioning.type = "trashcan";
        };
        pictures = {
          id = "zbxzv-35v4e";
          label = "Pictures";
          path = "~/Pictures";
          devices = ["desktop" "laptop" "server" "phone"];
          versioning.type = "trashcan";
        };
      };
      description = "Syncthing folders configuration";
    };

    enabledFolders = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
      description = "Folder attribute names enabled on this host; null enables all folders";
    };

    # Derived (read-only) path to the generated seed config.xml the finit
    # service seeds into ~/.config/syncthing/config.xml when it's missing the
    # declared folders. Exposed here so host finit services can consume it.
    seedConfigFile = lib.mkOption {
      type = lib.types.path;
      readOnly = true;
      description = "Path to the generated declarative syncthing seed config.xml";
      internal = true;
    };
  };

  config = lib.mkIf config.user.services.syncthing.enable {
    user.services.syncthing.seedConfigFile = seedConfigXml;

    # NixOS-universe declaration (dropped by finix compat-import whitelist,
    # which only keeps user.*/environment/fonts/services.udev.packages). Kept
    # for documentation/parity with the historical NixOS bridge.
    services.syncthing = {
      enable = true;
      inherit (config.user.services.syncthing) user;
      dataDir = config.user.homeDirectory;
      configDir = "${config.user.homeDirectory}/.config/syncthing";
      settings = {
        gui.address = [
          "127.0.0.1:8384"
          "localhost:8384"
          "syncthing-desktop:8384"
          "syncthing-server:8384"
        ];
        inherit (config.user.services.syncthing) devices;
        folders =
          if config.user.services.syncthing.enabledFolders == null
          then config.user.services.syncthing.folders
          else lib.getAttrs config.user.services.syncthing.enabledFolders config.user.services.syncthing.folders;
      };
    };
  };
}
