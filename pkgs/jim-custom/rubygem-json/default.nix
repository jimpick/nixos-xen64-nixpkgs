{stdenv, fetchurl, rubygems}:

stdenv.mkDerivation {
  name = "rubygem-json-1.1.3";
  builder = ./builder.sh;
  
  src = fetchurl {
    #url = mirror://gnu/hello/hello-2.3.tar.bz2;
    url = file:///Library/Ruby/Gems/1.8/cache/json-1.1.3.gem;
    sha256 = "379852d4a88e68b58605a3fbad5c6d7c329a4e7e91b221a3d4b077c63cdc64fe";
  };
  
  meta = {
    description = "A JSON implementation as a Ruby extension";
    longDescription = ''
      A JSON implementation as a Ruby extension
    '';
    homepage = http://json.rubyforge.org;
  };

  inherit rubygems;
}
