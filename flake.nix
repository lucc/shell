{
  description = "Some shell scripts";

  outputs = { self, nixpkgs }:

  let
    system = "x86_64-linux";
    scripts = [
      "diff-wrapper.bash"
      "file+"
      "git/git-credential-pass"
      "git/git-is-dirty"
      "git/git-multi-rebase"
      "git/git-retry-rebase"
      "git/git-tag-stats"
      "git/git-wc-statistics"
      "linux/auto-xrandr"
      "linux/bluetooth-headset.sh"
      "term"
      "tmux-youtube-dl.sh"
    ];
    #inherit (nixpkgs.legacyPackages.x86_64-linux) resholve;
    pkgs = import nixpkgs { inherit system; };
  in

  {
    packages.${system}.default = pkgs.stdenv.mkDerivation {
      name = "luccs-scripts";
      src = self;
      installPhase = ''
        install -D -t $out/bin ${pkgs.lib.strings.concatStringsSep " " scripts}
      '';
      };
    defaultPackage.${system} = self.packages.${system}.default;
  };
}
