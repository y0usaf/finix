{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.services.syncthing;
  userName = config.user.name;
  inherit (config.users.users.${userName}) home;

  devices = {
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

  folders = {
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

  renderFolder = name: ''
    <folder id="${folders.${name}.id}" label="${folders.${name}.label}" path="${folders.${name}.path}" type="sendreceive" rescanIntervalS="3600" fsWatcherEnabled="true" fsWatcherDelayS="10" fsWatcherTimeoutS="0" ignorePerms="false" autoNormalize="true">
        <filesystemType>basic</filesystemType>
        ${lib.concatMapStringsSep "\n" (id: ''      <device id="${id}" introducedBy="">
          <encryptionPassword></encryptionPassword>
      </device>'') (map (d: devices.${d}.id) folders.${name}.devices)}
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

  renderDevice = name: let
    dev = devices.${name};
    compression =
      dev.compression or "metadata";
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

  enabledFolderNames =
    if cfg.enabledFolders == null
    then builtins.attrNames folders
    else cfg.enabledFolders;

  folderXml = lib.concatMapStringsSep "\n" renderFolder enabledFolderNames;
  deviceXml = lib.concatMapStringsSep "\n" renderDevice (builtins.attrNames devices);

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

    enabledFolders = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
      description = "Folder attribute names enabled on this host; null enables all folders";
    };
  };

  config = lib.mkIf config.user.services.syncthing.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".config/syncthing"
      ".local/share/syncthing"
      ".local/state/syncthing"
    ];
    finit.services.syncthing = {
      description = "syncthing file sync (${userName})";
      user = userName;
      environment.HOME = home;
      path = [pkgs.coreutils pkgs.gnugrep];
      command = let
        cfgDir = "${home}/.config/syncthing";
      in "${pkgs.writeShellScript "syncthing-seed" ''
        set -e
        CFG=${cfgDir}/config.xml
        if [ ! -f "$CFG" ] || ! grep -q '<folder id=' "$CFG"; then
          install -m 600 -o ${userName} -g users ${seedConfigXml} "$CFG"
        fi
        exec ${pkgs.syncthing}/bin/syncthing --config=${cfgDir} --data=${cfgDir} --gui-address=127.0.0.1:8384 --no-browser
      ''}";
      conditions = ["net/lo/up"];
      log = true;
    };
  };
}
