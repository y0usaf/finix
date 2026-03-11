let
  data = builtins.fromJSON (builtins.readFile ./sources.json);
  inherit (data) version;

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
      in
        builtins.fetchGit {
          rev = revision;
          name =
            (url: rev: let
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
            }${appendShort}")
            url
            revision;
          inherit url submodules;
        };
in
  if version == 5
  then
    builtins.mapAttrs (name: spec:
      assert spec ? type;
        spec
        // {
          outPath =
            (name: path: let
              envVarName = "NPINS_OVERRIDE_${saneName}";
              saneName = (f: s:
                (builtins.concatStringsSep "") (map f ((s:
                  map (p: builtins.substring p 1 s) ((first: last:
                    if first > last
                    then []
                    else builtins.genList (n: first + n) (last - first + 1))
                  0 (builtins.stringLength s - 1)))
                s))) (c:
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
                ))
            name (
              if spec.type == "Git"
              then mkGitSource spec
              else if spec.type == "GitRelease"
              then mkGitSource spec
              else if spec.type == "PyPi"
              then
                ({
                  url,
                  hash,
                  ...
                }:
                  builtins.fetchurl {
                    inherit url;
                    sha256 = hash;
                  })
                spec
              else if spec.type == "Channel"
              then
                ({
                  url,
                  hash,
                  ...
                }:
                  builtins.fetchTarball {
                    inherit url;
                    sha256 = hash;
                  })
                spec
              else if spec.type == "Tarball"
              then
                ({
                  url,
                  locked_url ? url,
                  hash,
                  ...
                }:
                  builtins.fetchTarball {
                    url = locked_url;
                    sha256 = hash;
                  })
                spec
              else builtins.throw "Unknown source type ${spec.type}"
            );
        })
    data.pins
  else throw "Unsupported format version ${toString version} in sources.json. Try running `npins upgrade`"
