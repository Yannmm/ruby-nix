{
  description = "A simple ruby app demo";
  inputs = {
    nixpkgs.url = "nixpkgs";
    ruby-nix.url = "github:sagittaros/ruby-nix";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, ruby-nix, flake-utils }:
    flake-utils.lib.eachSystem [
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
    ]
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
          rubyNix = ruby-nix.lib pkgs;

          inherit (rubyNix {
            name = "simple-ruby-app";
            gemset = ./gemset.nix;
            gemPlatforms = [ "ruby" "arm64-darwin-20" "x86_64-linux" ];
          }) env envMinimal;
        in
        {
          devShells = rec {
            default = dev;
            dev = pkgs.mkShell {
              buildInputs = [ env ];
            };
          };
        });
}
