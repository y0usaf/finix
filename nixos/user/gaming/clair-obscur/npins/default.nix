let
  data = builtins.fromJSON (builtins.readFile ./sources.json);
  inherit (data) version;

  range = first: last:
    if first > last
    then []
    else builtins.genList (n: first + n) (last - first + 1);

  stringToCharacters = s: map (p: builtins.substring p 1 s) (range 0 (builtins.stringLength s - 1));

  stringAsChars = f: s: concatStrings (map f (stringToCharacters s));
  concatStrings = builtins.concatStringsSep "";

  mayOverride = name: path: let
    envVarName = "NPINS_OVERRIDE_${saneName}";
    saneName = stringAsChars (c:
      if (builtins.match "[a-zA-Z0-9]" c) == null
      then "_"
      else c)
    name;
    ersatz = builtins.getEnv envVarName;
  in
    if ersatz == ""
    then path
    else
      builtins.trace "Overriding path of \"${name}\" with \"${ersatz}\" due to set \"${envVarName}\"" (
        if builtins.substring 0 1 ersatz == "/"
        then /. + ersatz
        else /. + builtins.getEnv "PWD" + "/${ersatz}"
      );

  mkSource = name: spec:
    assert spec ? type; let
      path =
        if spec.type == "Git"
        then mkGitSource spec
        else if spec.type == "GitRelease"
        then mkGitSource spec
        else if spec.type == "PyPi"
        then mkPyPiSource spec
        else if spec.type == "Channel"
        then mkChannelSource spec
        else if spec.type == "Tarball"
        then mkTarballSource spec
        else builtins.throw "Unknown source type ${spec.type}";
    in
      spec // {outPath = mayOverride name path;};

  mkGitSource = {
    repository,
    revision,
    url ? null,
    submodules,
    hash,
    ...
  }:
    assert repository ? type;
      if url != null && !submodules
      then
        builtins.fetchTarball {
          inherit url;
          sha256 = hash;
        }
      else let
        url =
          if repository.type == "Git"
          then repository.url
          else if repository.type == "GitHub"
          then "https://github.com/${repository.owner}/${repository.repo}.git"
          else if repository.type == "GitLab"
          then "${repository.server}/${repository.repo_path}.git"
          else throw "Unrecognized repository type ${repository.type}";
        urlToName = url: rev: let
          matched = builtins.match "^.*/([^/]*)(\\.git)?$" url;

          short = builtins.substring 0 7 rev;

          appendShort =
            if (builtins.match "[a-f0-9]*" rev) != null
            then "-${short}"
            else "";
        in "${
          if matched == null
          then "source"
          else builtins.head matched
        }${appendShort}";
        name = urlToName url revision;
      in
        builtins.fetchGit {
          rev = revision;
          inherit name;
          inherit url submodules;
        };

  mkPyPiSource = {
    url,
    hash,
    ...
  }:
    builtins.fetchurl {
      inherit url;
      sha256 = hash;
    };

  mkChannelSource = {
    url,
    hash,
    ...
  }:
    builtins.fetchTarball {
      inherit url;
      sha256 = hash;
    };

  mkTarballSource = {
    url,
    locked_url ? url,
    hash,
    ...
  }:
    builtins.fetchTarball {
      url = locked_url;
      sha256 = hash;
    };
in
  if version == 5
  then builtins.mapAttrs mkSource data.pins
  else throw "Unsupported format version ${toString version} in sources.json. Try running `npins upgrade`"
