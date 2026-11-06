{
  assign,
  blank,
  dq,
  dropLongestPrefix,
  dropSuffix,
  for,
  pipe,
  redir,
  required,
  rows,
  sq,
  sub,
  var,
  word,
  ...
}: ({
  v,
  tmp,
  f,
  h,
}: [
  (assign v (required 1 "usage: beat-saber-lock GAME_VERSION"))
  (assign tmp (sub [["mktemp" "-d"]]))
  ["trap" (sq "rm -rf \"$tmp\"") "EXIT"]
  blank
  ["curl" "-fsS" "-o" (dq [(var tmp) "/mods.json"]) (dq ["https://beatmods.com/api/mods?gameName=BeatSaber&gameVersion=" (var v) "&status=verified&platform=steampc"])]
  blank
  (pipe (rows [["jq" "-r" (sq ".mods[].latest.zipHash") (dq [(var tmp) "/mods.json"])] ["xargs" "-P" 8 "-I" (sq "{}") "sh" "-c" (sq "\n    set -e\n    curl -fsS -o \"$1/$2.zip\" \"https://beatmods.com/cdn/mod/$2.zip\"\n    echo \"$2  $1/$2.zip\" | md5sum -c --quiet\n    nix hash file --sri --type sha256 \"$1/$2.zip\" > \"$1/$2.sri\"\n  ") "_" (dq (var tmp)) (sq "{}")]]))
  blank
  (pipe [
    (for f [(word [(dq (var tmp)) "/*.sri"])] [
      (assign h (dropLongestPrefix f "*/"))
      ["jq" "-n" "--arg" "k" (dq (dropSuffix h ".sri")) "--rawfile" "v" (dq (var f)) (sq "{($k): ($v | rtrimstr(\"\\n\"))}")]
    ])
    ["jq" "-s" "add" (redir ">" (dq [(var tmp) "/sri.json"]))]
  ])
  blank
  ["jq" "-S" "--arg" "v" (dq (var v)) "--slurpfile" "sri" (dq [(var tmp) "/sri.json"]) (sq "\n  if (.mods | length) == 0 then error(\"BeatMods has no verified mods for \\($v)\") else . end\n  | (.mods | map({ key: (.latest.id | tostring), value: .mod.name }) | from_entries) as $names\n  | {\n      gameVersion: $v,\n      mods: (.mods | map({\n        key: .mod.name,\n        value: {\n          version: .latest.modVersion,\n          url: \"https://beatmods.com/cdn/mod/\\(.latest.zipHash).zip\",\n          hash: $sri[0][.latest.zipHash],\n          depends: [.latest.dependencies[] | $names[tostring] // error(\"\\(.) is not a verified \\($v) mod\")] | sort\n        }\n      }) | from_entries)\n    }\n") (dq [(var tmp) "/mods.json"]) (redir ">" (dq [(var tmp) "/beatmods.json"]))]
  blank
  (pipe [["nix" "eval" "--impure" "--expr" (dq ["builtins.fromJSON (builtins.readFile " (var tmp) "/beatmods.json)"])] ["alejandra" "--quiet"]])
])
