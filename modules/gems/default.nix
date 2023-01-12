{ lib, ruby, gemset, buildRubyGem, ... }@args:

let
  inherit (lib) pipe mapAttrs;

  gemsetVersions = let
    inherit (import ./filters.nix args) filterGemset;
    inherit (import ./expand.nix args) mapGemsetVersions;
  in pipe gemset [ filterGemset mapGemsetVersions ];

  # make this a fixpoint function?
  gems = let
    buildGem = name: attrs: buildRubyGem (finalGemSpec gems name attrs);
    finalGemSpec = gems: name: attrs:
      let
        matchingSource = lib.findFirst (p:
          let sys = ruby.stdenv.hostPlatform.system;
          in (
            # XXX this is not exhaustive
            if lib.hasPrefix "arm64-darwin" p.platform then
              sys == "aarch64-darwin"
            else if lib.hasPrefix "x86_64-darwin" p.platform then
              sys == "x86_64-darwin"
            else if p.platform == "x86_64-linux" then
              sys == "x86_64-linux"
            else
              false)) attrs.source # falls back to source compilation otherwise
          (attrs.nativeSources or [ ]);
      in ((removeAttrs attrs [ "platforms" "nativeSources" ]) // {
        inherit ruby;
        inherit (matchingSource) type;
        source = removeAttrs matchingSource [ "type" "platform" ];
        gemName = name;
        gemPath = map (gemName: gems.${gemName}) (attrs.dependencies or [ ]);
        version = if (matchingSource.platform or "ruby") == "ruby" then
          attrs.version
        else
          "${attrs.version}-${matchingSource.platform}";
      });
  in mapAttrs buildGem gemsetVersions;

in gemsetVersions
