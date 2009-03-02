{stdenv, fetchurl, rubygems, rubygem_json, makeWrapper}:

stdenv.mkDerivation {
  name = "jim-json-test-0.1";

  buildInputs = [makeWrapper];

  inherit rubygems rubygem_json;

  src = ./jim-json-test.rb;

  phases = "installPhase fixupPhase";

  installCommand = ''
    mkdir -p $out/bin
    cp $src $out/bin/jim-json-test.rb
    chmod u+w $out/bin/jim-json-test.rb
  '';

  postInstall = ''
      wrapProgram $out/bin/jim-json-test.rb --prefix RUBYLIB : $rubygems/lib \
	--prefix GEM_PATH : $rubygem_json
  '';

  meta = {
    description = "Test Ruby GEM for JSON";
    longDescription = ''
      Test Ruby GEM for JSON
    '';
  };

}
