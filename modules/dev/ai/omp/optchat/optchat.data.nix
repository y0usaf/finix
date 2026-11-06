{generators}: {
  "extension.ts" = generators.ts.render (import ./extension.data.nix generators.ts);
  "service.ts" = generators.ts.render (import ./service.data.nix generators.ts);
  "store.ts" = generators.ts.render (import ./store.data.nix generators.ts);
  "tree.ts" = generators.ts.render (import ./tree.data.nix generators.ts);
}
