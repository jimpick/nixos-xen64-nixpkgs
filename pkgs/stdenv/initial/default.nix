# Here we construct an absolutely trivial `initial' standard
# environment.  It's not actually a functional stdenv, since there is
# not necessarily a working C compiler.  We need this to build
# gcc-wrapper et al. for the native stdenv.

{system, name}:

let {

  shell = "/bin/bash";

  body = 

    derivation {
      inherit system name;
      builder = shell;
      args = ["-e" ./builder.sh];
      stdenvScript = ../generic/setup.sh;
    }

    // {
      mkDerivation = attrs: derivation ((removeAttrs attrs ["meta"]) // {
        builder = shell;
        args = ["-e" attrs.builder];
        stdenv = body;
        system = body.system;
      });

      inherit shell;
    };

}
