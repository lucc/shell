{
  description = "Some shell scripts";

  outputs = { self, nixpkgs }: {

    defaultPackage.x86_64-linux =
      let
        #inherit (nixpkgs.legacyPackages.x86_64-linux) resholve;
        pkgs = import nixpkgs { system = "x86_64-linux"; };
      in pkgs.stdenv.mkDerivation {
        name = "luccs-scripts";
        src = self;
        installPhase = ''
          install -D -t $out/bin \
            diff-wrapper.bash \
            file+ \
            git/git-credential-pass \
            git/git-is-dirty \
            git/git-multi-rebase \
            git/git-retry-rebase \
            git/git-tag-stats \
            git/git-wc-statistics \
            linux/auto-xrandr \
            linux/bluetooth-headset.sh \
            tmux-youtube-dl.sh \

          '';
      };
  };
}
