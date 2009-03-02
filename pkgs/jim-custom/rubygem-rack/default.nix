{stdenv, fetchurl, rubygems, makeWrapper}:

stdenv.mkDerivation {
  name = "rubygem-rack-0.9.1";

  buildInputs = [rubygems makeWrapper];

  inherit rubygems;

  phases = "doInstall postInstall";

  doInstall = ''
    gem install -i $out $src
  '';

  postInstall = ''
    wrapProgram $out/bin/rackup --prefix RUBYLIB : $rubygems/lib --prefix GEM_PATH : $out
  '';

  src = fetchurl {
    url = http://gems.rubyforge.org/gems/rack-0.9.1.gem;
    sha256 = "0b10d9a9ae7dec712abb18a4e684a660e80c095ee03062dfa48a15f7a643720b";
  };
  
  meta = {
    description = "a modular Ruby webserver interface";
    longDescription = ''
      Rack provides minimal, modular and adaptable interface for developing
      web applications in Ruby.  By wrapping HTTP requests and responses in
      the simplest way possible, it unifies and distills the API for web
      servers, web frameworks, and software in between (the so-called
      middleware) into a single method call.

      Also see http://rack.rubyforge.org.
    '';
    homepage = http://rack.rubyforge.org;
  };

}
