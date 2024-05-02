# This is a fetcher made specifically for fetching models to be used by
# ComfyUI.
{ lib, pkgs }:
{ url
, format ? null
, bearer ? null
, bearerFile ? null
,  ...
}@args: let
  name = lib.replaceStrings
    ["?" "&" ":" "/"]
    ["__questionmark__" "__ampersand__" "__colon__" "__slash__"]
    url
  ;
in {
  inherit name format;
  # I think builtins.fetchurl _can_ show progress but needs --verbose to do so.
  # Need to confirm if this is any better than alternatives (like
  # nixpkgs.fetchurl).
  # path = (builtins.fetchurl ({
  path = (pkgs.fetchurl (
    (lib.traceVal (lib.filterAttrs
      # The @args syntax gathers all arguments, not just the extra ones.
      # fetchurl doesn't like extra arguments it doesn't know about, so we need
      # to remove them here.
      (key: _:
        (lib.any (x: x == key)
          ["bearer" "bearerFile" "format"]
        )
      )
      args
    )) // (lib.optionalAttrs (bearer != null) {
      # The closest thing to documentation for curlOptsList that I've found:
      # https://github.com/NixOS/nixpkgs/issues/41820#issuecomment-396120262
      curlOptsList = [
        "--header" "Authorization: Bearer ${bearer}"
        "--location"
      ];
    })
    // (lib.optionalAttrs (bearerFile != null) {
      # The closest thing to documentation for curlOptsList that I've found:
      # https://github.com/NixOS/nixpkgs/issues/41820#issuecomment-396120262
      # This seemed to work at some point but curl can no longer read the file
      # (but no reason is given).  This is when given world readable
      # permissions too.
      curlOptsList = [
        "--header" "@${bearerFile}"
        "--location"
      ];
    })
  ))
    # Normally a derivation is coerced to a string when interpolated where it is
    # used.  That is not observed here (for reasons not well understood).
    # Derivations have an outPath which contains what we actually want, so just
    # grab it.  Note that this only happens with pkgs.fetchurl, and
    # builtings.fetchurl does not suffer this issue.
    .outPath;
}
