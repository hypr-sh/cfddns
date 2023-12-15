{
  description = "cloudflare ddns script";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
        cname = "cfddns";
        cbuildInputs = with pkgs; [curl jq];
        cfddns = (pkgs.writeScriptBin cname (builtins.readFile ./src/cfddns.sh)).overrideAttrs (old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });
      in rec {
        defaultPackage = packages.cfddns;
        packages.cfddns = pkgs.symlinkJoin {
          name = cname;
          paths = [cfddns] ++ cbuildInputs;
          buildInputs = [pkgs.makeWrapper];
          postBuild = "wrapProgram $out/bin/${cname} --prefix PATH : $out/bin";
        };
      }
    );
}
