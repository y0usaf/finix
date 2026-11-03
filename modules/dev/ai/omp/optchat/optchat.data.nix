{generators}: {
  "extension.ts" = generators.tsSource (import ./extension.data.nix);
  "service.ts" = generators.tsSource (import ./service.data.nix);
  "store.ts" = generators.tsSource (import ./store.data.nix);
  "tree.ts" = generators.tsSource (import ./tree.data.nix);
}
