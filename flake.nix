{
  description = "Some shell scripts";

  outputs = {
    self,
    nixpkgs,
  }: let
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
    ];
    pkgs = import nixpkgs {inherit system;};
    concat = pkgs.lib.strings.concatMapStrings (s: " ${self}/${s}");
    build = name: buildInputs: command:
      pkgs.runCommandLocal name {inherit buildInputs;} ''
        ${command}
        patchShebangs "$out/bin"
      '';
    # TODO check out resholve
    ticket = build "ticket" [pkgs.python3] ''
      install -D ${self}/ticket.py "$out/bin/ticket"
      substituteInPlace "$out/bin/ticket" \
        --replace-fail '"ebook-convert"' '"${pkgs.calibre}/bin/ebook-convert"' \
        --replace-fail '"kitinerary-extractor"' '"${pkgs.kdePackages.kitinerary}/libexec/kf6/kitinerary-extractor"' \
        --replace-fail '"pdfcrop"' '"${pkgs.texlivePackages.pdfcrop}/bin/pdfcrop"' \
        --replace-fail '"pdfinfo"' '"${pkgs.poppler_utils}/bin/pdfinfo"' \
        --replace-fail '"pdftotext"' '"${pkgs.poppler_utils}/bin/pdftotext"'
    '';
    # it seems that youtube-dl in nixpkgs is not updated, use a replacement
    tmux-youtube-dl = build "tmux-youtube-dl" [] ''
      install -D -t "$out/bin" ${self}/tmux-youtube-dl.sh
      substituteInPlace "$out/bin/tmux-youtube-dl.sh" \
        --replace-fail "command youtube-dl" ${pkgs.lib.meta.getExe pkgs.yt-dlp}
    '';

    simple-scripts = build "simple-scripts" [pkgs.zsh] ''
      install -D -t "$out/bin" ${concat scripts}
    '';
  in {
    packages.${system} = {
      default = pkgs.buildEnv {
        name = "luccs-scripts";
        paths = [ticket tmux-youtube-dl simple-scripts];
      };
      inherit ticket tmux-youtube-dl simple-scripts;
    };
    checks.${system} = {inherit ticket tmux-youtube-dl simple-scripts;};
  };
}
