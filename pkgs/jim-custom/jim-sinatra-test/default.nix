{stdenv, fetchurl, rubygems, rubygem_rack, rubygem_sinatra, makeWrapper}:

stdenv.mkDerivation {
  name = "jim-sinatra-test-0.1";

  buildInputs = [makeWrapper];

  inherit rubygems rubygem_rack rubygem_sinatra;

  src = ./jim-sinatra-test.rb;

  phases = "installPhase fixupPhase";

  installCommand = ''
    mkdir -p $out/bin
    cp $src $out/bin/jim-sinatra-test.rb
    chmod u+w $out/bin/jim-sinatra-test.rb
  '';

  postInstall = ''
      wrapProgram $out/bin/jim-sinatra-test.rb --prefix RUBYLIB : $rubygems/lib \
	--prefix GEM_PATH : $rubygem_sinatra:$rubygem_rack
  '';

  meta = {
    description = "Test Sinatra";
    longDescription = ''
      Test Sinatra
    '';
  };

}
