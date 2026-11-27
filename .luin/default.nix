let
  luinPinManaged = true;
  inherit (builtins)
    attrNames
    elemAt
    fetchTree
    fetchurl
    foldl'
    fromJSON
    functionArgs
    head
    intersectAttrs
    isAttrs
    isFunction
    isList
    isString
    length
    listToAttrs
    mapAttrs
    pathExists
    readFile
    removeAttrs
    stringLength
    substring
    tail
    toString
    ;

  lock = fromJSON (readFile ./pins.lock.json);
  lockNodes = lock.nodes or {};

  formatEpoch = secs:
    let
      days = secs / 86400;
      daySecs = secs - days * 86400;
      shifted = days + 719468;
      era = shifted / 146097;
      dayOfEra = shifted - era * 146097;
      yearOfEra = (dayOfEra - dayOfEra / 1460 + dayOfEra / 36524 - dayOfEra / 146096) / 365;
      dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100);
      marchMonth = (5 * dayOfYear + 2) / 153;
      day = dayOfYear - (153 * marchMonth + 2) / 5 + 1;
      month = if marchMonth < 10 then marchMonth + 3 else marchMonth - 9;
      year = yearOfEra + era * 400 + (if month <= 2 then 1 else 0);
      pad = n: if n < 10 then "0${toString n}" else toString n;
    in
    "${toString year}${pad month}${pad day}${pad (daySecs / 3600)}${pad (daySecs / 60 - daySecs / 3600 * 60)}${pad (daySecs - daySecs / 60 * 60)}";

  fetchTreeKeys = {
    type = null;
    owner = null;
    repo = null;
    host = null;
    url = null;
    id = null;
    ref = null;
    rev = null;
    narHash = null;
    lastModified = null;
    revCount = null;
    submodules = null;
    shallow = null;
    allRefs = null;
    name = null;
    lfs = null;
    exportIgnore = null;
    unpack = null;
  };

  mkSrcInfo = locked: tree:
    let
      outPath = if isAttrs tree then tree.outPath else tree;
      rev = if isAttrs tree && tree ? rev then tree.rev else (locked.rev or null);
      lastModified =
        if isAttrs tree && tree ? lastModified then tree.lastModified
        else (locked.lastModified or null);
      narHash =
        if isAttrs tree && tree ? narHash then tree.narHash
        else (locked.narHash or null);
      revCount =
        if isAttrs tree && tree ? revCount then tree.revCount
        else (locked.revCount or null);
    in
    { inherit outPath; }
    // (if rev != null then {
      inherit rev;
      shortRev = if stringLength rev >= 7 then substring 0 7 rev else rev;
    } else {})
    // (if lastModified != null then {
      inherit lastModified;
      lastModifiedDate = formatEpoch lastModified;
    } else {})
    // (if narHash != null then { inherit narHash; } else {})
    // (if revCount != null then { inherit revCount; } else {});

  fetchLocked = baseDir: locked:
    let
      t = locked.type or "tarball";
      pinType = locked.pinType or "flake";
    in
    if t == "path" then
      let
        raw = locked.path;
        resolvedPath =
          if substring 0 1 raw == "/" then builtins.toPath raw
          else baseDir + "/${raw}";
      in
      mkSrcInfo locked { outPath = resolvedPath; }
    else if pinType == "fixed" && !(locked.unpack or true) then
      let
        f = fetchurl ({
          url = locked.url;
        } // (if locked ? narHash then { sha256 = locked.narHash; } else {}));
      in
      mkSrcInfo locked f
    else if pinType == "fixed" then
      let
        args = {
          type = "tarball";
          url = locked.url;
        } // (if locked ? narHash then { inherit (locked) narHash; } else {});
      in
      mkSrcInfo locked (fetchTree args)
    else
      let
        rawArgs = intersectAttrs fetchTreeKeys locked;
        args =
          if (t == "github" || t == "gitlab" || t == "sourcehut") && rawArgs ? rev then
            removeAttrs rawArgs [ "ref" ]
          else
            rawArgs;
      in
      mkSrcInfo locked (fetchTree args);

  evalTree = { srcInfo, dir ? null, overrides ? {} }:
    let
      flakeDir = if dir != null && dir != "" then srcInfo.outPath + "/${dir}" else srcInfo.outPath;
      hasLuin = pathExists (flakeDir + "/.luin/pins.lock.json") && pathExists (flakeDir + "/default.nix");
      hasFlake = pathExists (flakeDir + "/flake.nix");
    in
    if hasLuin then
      let
        childPins = (import (flakeDir + "/.luin")) { inherit overrides; };
        cleanPins = removeAttrs childPins [ "__functor" ];
        imported = import (flakeDir + "/default.nix");
        out =
          if isFunction imported then
            let
              fargs = functionArgs imported;
              passed = intersectAttrs fargs {
                pins = childPins;
                src = srcInfo;
              };
            in
            imported passed
          else
            imported;
        outPath = srcInfo.outPath;
      in
      out // srcInfo // {
        inherit outPath;
        inputs = cleanPins;
        sourceInfo = srcInfo;
      }
    else if hasFlake then
      let
        flake = import (flakeDir + "/flake.nix");
        lockPath = flakeDir + "/flake.lock";
        hasLock = pathExists lockPath;
        flock =
          if hasLock then fromJSON (readFile lockPath)
          else { root = "root"; nodes = { root = { inputs = {}; }; }; };
        fnodes = flock.nodes or {};
        rootKey = flock.root or "root";
        rootSpecs = (fnodes.${rootKey} or {}).inputs or {};

        walkVal = cur: steps:
          if steps == [] then cur
          else
            let
              k = head steps;
              next =
                if isAttrs cur && cur ? inputs && cur.inputs ? ${k} then cur.inputs.${k}
                else if isAttrs cur && cur ? ${k} then cur.${k}
                else throw "luin-pin: cannot resolve follow step '${k}'";
            in
            walkVal next (tail steps);

        followInLock = nodeKey: steps:
          if steps == [] then
            if nodeKey == rootKey then self
            else evalFlakeNode nodeKey
          else
            let
              k = head steps;
              rest = tail steps;
            in
            if nodeKey == rootKey && overrides ? ${k} then
              walkVal overrides.${k} rest
            else
              let
                nodeInputsSpec = (fnodes.${nodeKey} or {}).inputs or {};
                nextRef =
                  if nodeInputsSpec ? ${k} then nodeInputsSpec.${k}
                  else throw "luin-pin: missing follow '${k}' in node '${nodeKey}'";
              in
              if isString nextRef then
                followInLock nextRef rest
              else if isList nextRef then
                followPathFromRoot (nextRef ++ rest)
              else
                throw "luin-pin: invalid flake.lock ref";

        followPathFromRoot = steps: followInLock rootKey steps;

        resolveRef = ref:
          if isString ref then
            evalFlakeNode ref
          else if isList ref then
            followPathFromRoot ref
          else
            throw "luin-pin: invalid flake.lock ref";

        evalFlakeNode = nodeName:
          let
            node = fnodes.${nodeName} or (throw "luin-pin: missing flake.lock node '${nodeName}'");
            locked = node.locked or (throw "luin-pin: node '${nodeName}' has no locked attr");
            nodeDir = locked.dir or ((node.original or {}).dir or null);
            nodeSrc = fetchLocked flakeDir locked;
            isFlake = node.flake or true;
            nodeInputs = mapAttrs (_: resolveRef) (node.inputs or {});
          in
          if !isFlake then
            nodeSrc
          else
            let
              ndir = if nodeDir != null && nodeDir != "" then nodeSrc.outPath + "/${nodeDir}" else nodeSrc.outPath;
              nodeHasLuin = pathExists (ndir + "/.luin/pins.lock.json") && pathExists (ndir + "/default.nix");
              nodeHasFlake = pathExists (ndir + "/flake.nix");
            in
            if nodeHasLuin then
              evalTree {
                srcInfo = nodeSrc;
                dir = nodeDir;
                overrides = nodeInputs;
              }
            else if nodeHasFlake then
              let
                nf = import (ndir + "/flake.nix");
                nout = nf.outputs (nodeInputs // { self = nself; });
                nself = nout // nodeSrc // {
                  inherit (nodeSrc) outPath;
                  outputs = nout;
                  inputs = nodeInputs;
                  sourceInfo = nodeSrc;
                  _type = "flake";
                };
              in
              nself
            else
              nodeSrc;

        declaredInputs = if hasLock then rootSpecs else (flake.inputs or {});
        rootInputs = mapAttrs (name: ref:
          if overrides ? ${name} then overrides.${name}
          else if hasLock then resolveRef ref
          else throw "luin-pin: unlocked input '${name}' in flake without flake.lock"
        ) declaredInputs;

        out = flake.outputs (rootInputs // { inherit self; });
        self = out // srcInfo // {
          inherit (srcInfo) outPath;
          outputs = out;
          inputs = rootInputs;
          sourceInfo = srcInfo;
          _type = "flake";
        };
      in
      self
    else
      srcInfo;

  resolve = { overrides ? {} }:
    let
      walkResolved = steps:
        let
          first = head steps;
          start =
            if resolved ? ${first} then resolved.${first}
            else throw "luin-pin: unknown follow target '${first}'";
          step = cur: k:
            if isAttrs cur && cur ? inputs && cur.inputs ? ${k} then cur.inputs.${k}
            else if isAttrs cur && cur ? ${k} then cur.${k}
            else throw "luin-pin: cannot follow '${k}' in '${first}'";
        in
        foldl' step start (tail steps);

      evalPin = name: node:
        if overrides ? ${name} then
          overrides.${name}
        else if node ? followsOnly then
          walkResolved node.followsOnly
        else
          let
            pinType = node.pinType or "flake";
            srcInfo = fetchLocked ./.. node;
            dir = node.dir or null;
            pinOverrides = mapAttrs (_: walkResolved) (node.follows or {});
          in
          if pinType == "flake" then
            evalTree {
              inherit srcInfo dir;
              overrides = pinOverrides;
            }
          else
            srcInfo;

      resolved = mapAttrs evalPin lockNodes;
    in
    builtins.seq luinPinManaged (
      resolved // {
        __functor = _: args: resolve args;
      }
    );
in
resolve {}
