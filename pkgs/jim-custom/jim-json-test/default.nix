{stdenv, fetchurl, rubygem_json}:

stdenv.mkDerivation {
  name = "jim-json-test-0.1";
  builder = ./builder.sh;

  src = ./jim-json-test.rb;

  meta = {
    description = "Test Ruby GEM for JSON";
    longDescription = ''
      Test Ruby GEM for JSON
    '';
  };

  inherit rubygem_json;
}
