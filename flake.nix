{
  description = "Some shell scripts";

  outputs = { self, nixpkgs }:

  let
    system = "x86_64-linux";
    scripts = [
      "deutschlandticket.py"
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
    ];
    pkgs = import nixpkgs { inherit system; };
    concat = pkgs.lib.strings.concatMapStrings (s: " ${self}/${s}");

    #inherit (pkgs) resholve;
    #zsh = [ "git/git-multi-rebase" ];
    #scripts' = concat (pkgs.lib.lists.subtractLists zsh scripts);

    # it seems that youtube-dl in nixpkgs is not updated, use a replacement
    tmux-youtube-dl = pkgs.runCommandLocal "tmux-youtube-dl" {} ''
      install -D -t "$out/bin" ${self}/tmux-youtube-dl.sh
      substituteInPlace "$out/bin/tmux-youtube-dl.sh" \
        --replace "command youtube-dl" ${pkgs.yt-dlp}/bin/yt-dlp
      patchShebangs "$out/bin"
    '';

    simple-scripts = pkgs.runCommandLocal "simple-scripts" {} ''
      install -D -t "$out/bin" ${concat scripts}
      patchShebangs "$out/bin"
    '';
    in

    {
      packages.${system}.default = pkgs.buildEnv {
        name = "luccs-scripts";
        paths = [ simple-scripts tmux-youtube-dl ];
      };
    };
}
