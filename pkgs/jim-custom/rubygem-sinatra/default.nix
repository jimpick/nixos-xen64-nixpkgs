{stdenv, fetchurl, rubygems}:

stdenv.mkDerivation {
  name = "rubygem-sinatra-0.9.0.4";

  buildInputs = [rubygems];

  inherit rubygems;

  phases = "doInstall";

  doInstall = ''
    gem install -i $out $src --ignore-dependencies
  '';

  src = fetchurl {
    url = http://gems.rubyforge.org/gems/sinatra-0.9.0.4.gem;
    sha256 = "d9d94fcbc1a2fac4eab82bdac927368f924a9b4d3b171700cece66f766e6ec71";
  };
  
  meta = {
    description = "Classy web-development dressed in a DSL";
    longDescription = ''
      Classy web-development dressed in a DSL
    '';
    homepage = http://sinatra.rubyforge.org;
  };

}
