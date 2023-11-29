{
  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.benchmark = pkgs.runCommand "nix-git-shallow-benchmark"
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
        ${./test-providers-treeless.sh}
        mkdir $out
        mv result.csv $out/result.csv
      '';
  };
}
