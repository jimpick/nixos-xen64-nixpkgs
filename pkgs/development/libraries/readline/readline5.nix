args: with args;

stdenv.mkDerivation {
  name = "readline-5.2";
  src = fetchurl {
    url = mirror://gnu/readline/readline-5.2.tar.gz;
    sha256 = "0icz4hqqq8mlkwrpczyaha94kns0am9z0mh3a2913kg2msb8vs0j";
  };
  propagatedBuildInputs = [ncurses];
  configureFlags = "--enable-shared --disable-static";
  patches = stdenv.lib.optional stdenv.isDarwin ./shobj-darwin.patch;
}
