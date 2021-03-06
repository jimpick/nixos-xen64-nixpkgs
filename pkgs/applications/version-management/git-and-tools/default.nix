/* moving all git tools into one attribute set because git is unlikely to be
 * referenced by other packages and you can get a fast overview.
*/
args: with args; with pkgs;
let
  inherit (pkgs) stdenv fetchurl getConfig;
  inherit (pkgs.bleedingEdgeRepos) sourceByName;
in
rec {

  git = import ./git {
    inherit fetchurl stdenv curl openssl zlib expat perl gettext
      asciidoc texinfo xmlto docbook2x
      docbook_xsl docbook_xml_dtd_42 libxslt
      cpio tcl tk makeWrapper subversion;
    svnSupport = getConfig ["git" "svnSupport"] false; # for git-svn support
    guiSupport = getConfig ["git" "guiSupport"] false;
    perlLibs = [perlLWP perlURI perlTermReadKey subversion];
  };

  gitGit = import ./git/git-git.nix {
    inherit fetchurl stdenv curl openssl zlib expat perl gettext
      asciidoc texinfo xmlto docbook2x
      docbook_xsl docbook_xml_dtd_42 libxslt
      cpio tcl tk makeWrapper subversion autoconf;
    inherit (bleedingEdgeRepos) sourceByName;
    svnSupport = getConfig ["git" "svnSupport"] false; # for git-svn support
    guiSupport = getConfig ["git" "guiSupport"] false;
    perlLibs = [perlLWP perlURI perlTermReadKey subversion];
  };

  qgit = import ./qgit {
    inherit fetchurl stdenv;
    inherit (xlibs) libXext libX11;
    qt = qt3;
  };

  qgitGit = import ./qgit/qgit-git.nix {
    inherit fetchurl stdenv;
    inherit (xlibs) libXext libX11;
    inherit (bleedingEdgeRepos) sourceByName;
    qt = qt4;
  };


  stgit = import ./stgit {
        inherit fetchurl stdenv python git;
  };

  topGit = stdenv.mkDerivation {
      name = "TopGit-git-patched";
      src = sourceByName "topGit"; # destination directory is patched
      installPhase = ''
        mkdir -p $out/etc/bash_completion.d
        make install
        mv contrib/tg-completion.bash $out/etc/bash_completion.d
      '';
      dontPatchELF = 1;
      meta = {
        description = "TopGit aims to make handling of large amount of interdependent topic branches easier";
        homepage = http://repo.or.cz/w/topgit.git; # maybe there is also another one, I haven't checked
        license = "GPLv2";
    };
  };

  tig = stdenv.mkDerivation {
    name = "tig-0.14.1";
    src = fetchurl {
      url = "http://jonas.nitro.dk/tig/releases/tig-0.14.1.tar.gz";
      sha256 = "1a8mi1pv36v67n31vs95gcibkifnqq5s1x69lz1cz0218yv9s73r";
    };
    buildInputs = [ncurses asciidoc xmlto docbook_xsl];
    installPhase = ''
      make install
      make install-doc
    '';
    meta = {
      description = "console git repository browser that additionally can act as a pager for output from various git commands";
      homepage = http://jonas.nitro.dk/tig/;
      license = "GPLv2";
    };
  };

  hg2git = import ./hg2git {
    inherit fetchurl stdenv mercurial coreutils git makeWrapper;
    inherit (bleedingEdgeRepos) sourceByName;
  };

}
