args: with args;

stdenv.mkDerivation {
  name = "atlas-3.8.2";
  src = fetchurl {
    url = http://kent.dl.sourceforge.net/sourceforge/math-atlas/atlas3.8.2.tar.bz2;
    sha256 = "1avbfppzgiws3nvqr7isr5a5pfbk3g4gfgd89xhyiywixjj3f7c6";
  };

  # configure outside of the source directory
  preConfigure = '' mkdir build; cd build; configureScript=../configure; '';

  NIX_CFLAGS_COMPILE = if stdenv.system == "x86_64-linux" then "-fPIC" else "";

  buildInputs = [gfortran];

  meta = {
    description     = "Atlas library";
    license     = "GPL";
    homepage    = http://math-atlas.sourceforge.net/;
  };
}
