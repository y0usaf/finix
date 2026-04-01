_: {
  user.paths = {
    flake.path = "/home/y0usaf/nixos";
    music.path = "/home/y0usaf/Music";
    dcim.path = "/home/y0usaf/DCIM";
    steam = {
      path = "/home/y0usaf/.local/share/Steam";
      create = false;
    };
    wallpapers = {
      static.path = "/home/y0usaf/DCIM/Wallpapers";
      video.path = "/home/y0usaf/DCIM/Wallpapers_Video";
    };
    bookmarks = [
      "file:///home/y0usaf/Downloads Downloads"
      "file:///home/y0usaf/Documents Documents"
      "file:///home/y0usaf/Dev Dev"
      "file:///home/y0usaf/nixos NixOS"
      "file:///tmp tmp"
    ];
  };
}
