{s}: rec
{
  ghcidScript = s "dev" "ghcid --command 'cabal new-repl lib:hsplayground' --allow-eval --warnings";
  allScripts = [ghcidScript];
}
