{
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = {
      benchmark = pkgs.runCommand "nix-git-shallow-benchmark"
        {
          buildInputs = [
            pkgs.bash
            pkgs.coreutils
            pkgs.git
            # ssl certificates
            pkgs.cacert
          ];
          __impure = true;
        }
        ''
          export WORKDIR=$(realpath .)
          bash ${./test-providers-treeless.sh}
          mkdir $out
          mv result.csv $out/result.csv
        '';

      benchmark-fod = pkgs.runCommand "nix-git-shallow-benchmark"
        {
          buildInputs = [
            pkgs.bash
            pkgs.coreutils
            pkgs.git
            # ssl certificates
            pkgs.cacert
          ];
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
          outputHash = "sha256-d6xi4mKdjkX2JFicDIv5niSzpyI0m/Hnm8GGAIU04kY=";
        }
        ''
          export WORKDIR=$(realpath .)
          bash ${./test-providers-treeless.sh}
          cat result.csv
          touch $out
        '';
    };
  };
}
