{stdenv, fetchurl, j2sdk}:

stdenv.mkDerivation {
  name = "jjtraveler-0.4.3.tar.gz";
  src = fetchurl {
    url = http://www.cwi.nl/projects/MetaEnv/jjtraveler/JJTraveler-0.4.3.tar.gz;
    md5 = "35bf801ee61f042513ae88247fe1bf1d";
  };
  buildInputs = [stdenv j2sdk];
}
