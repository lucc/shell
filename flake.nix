{
  description = "Some shell scripts";

  outputs = { self, nixpkgs }:

  let
    system = "x86_64-linux";
    scripts = [
      "diff-wrapper.bash"
      "file+"
      "git/git-credential-pass"
      "git/git-imgdiff"
      "git/git-is-clean"
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
    zsh = [ "git/git-multi-rebase" ];
    #inherit (nixpkgs.legacyPackages.x86_64-linux) resholve;
    pkgs = import nixpkgs { inherit system; };
    concat = pkgs.lib.strings.concatStringsSep " ";
    inherit (pkgs.lib.lists) subtractLists;
    scripts' = concat (subtractLists zsh scripts);
  in

  {
    packages.${system}.default = pkgs.stdenv.mkDerivation {
      name = "luccs-scripts";
      src = self;
      dontBuild = true;
      doCheck = true;
      checkPhase = ''
        ${pkgs.shellcheck}/bin/shellcheck ${scripts'}
      '';
      installPhase = ''
        install -D -t $out/bin ${concat scripts}
      '';

      };
  };
}
