{pkgs, ...}: let
  inherit (pkgs) lib;
  libwpe = pkgs.libwpe.overrideAttrs (o: {
    postFixup =
      (o.postFixup or "")
      + ''
        patchelf --add-rpath ${pkgs.libwpe-fdo}/lib $out/lib/libwpe-1.0.so.1
      '';
  });
  base = pkgs.callPackage "${pkgs.path}/pkgs/by-name/we/webkitgtk_6_0/package.nix" {};
in
  base.overrideAttrs (_: {
    pname = "wpewebkit";
    name = "wpewebkit-${base.version}";
    outputs = ["out"];
    separateDebugInfo = false;
    src = pkgs.fetchurl {
      url = "https://wpewebkit.org/releases/wpewebkit-${base.version}.tar.xz";
      hash = "sha256-Dei9+6AR+c1jupqRcfpgON0sCCN4lPQIKru4IfKdP+k=";
    };
    cmakeFlags = [
      "-DPORT=WPE"
      "-DENABLE_INTROSPECTION=OFF"
      "-DUSE_LIBSECRET=OFF"
      "-DENABLE_EXPERIMENTAL_FEATURES=OFF"
      "-DUSE_GTK4=OFF"
      "-DENABLE_MINIBROWSER=OFF"
      "-DENABLE_GAMEPAD=OFF"
      "-DUSE_WPE_RENDERER=ON"
      "-DENABLE_DEBUG_FISSION=OFF"
      "-DBWRAP_EXECUTABLE=${lib.getExe pkgs.bubblewrap}"
      "-DDBUS_PROXY_EXECUTABLE=${lib.getExe pkgs.xdg-dbus-proxy}"
    ];
    buildInputs =
      (base.buildInputs or [])
      ++ [
        libwpe
        pkgs.libwpe-fdo
        pkgs.wayland-protocols
        pkgs.libglvnd
        pkgs.mesa
        pkgs.libjpeg
        pkgs.libpng
        pkgs.libinput
        pkgs.udev
        pkgs.zlib
        pkgs.fontconfig
        pkgs.freetype
      ];
    propagatedBuildInputs = [pkgs.libsoup_3 libwpe];
  })
