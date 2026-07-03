{
  description = "BambuStudio AppImage flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system} = {
        bambustudio = pkgs.callPackage ./pkgs/bambu { };

        default = self.packages.${system}.bambustudio;
      };

      apps.${system}.default = {
        type = "app";
        program = "${self.packages.${system}.bambustudio}/bin/bambustudio";
      };
    };
}
