{ stdenv, fetchurl, libpcap, libX11, gtk, pkgconfig
, openssl, python, pygtk, makeWrapper, pygobject
, pycairo, pysqlite
}:
  
stdenv.mkDerivation (rec {
  name = "nmap-4.75";

  src = fetchurl {
    url = "http://nmap.org/dist/${name}.tar.bz2";
    sha256 = "0k4ylwlkn06zl6pfr2ig8340qrmfsbdh5rqqlnhpj55likbgrl37";
  };

  postInstall =''
    wrapProgram $out/bin/zenmap --prefix PYTHONPATH : "$(toPythonPath $out)" --prefix PYTHONPATH : "$PYTHONPATH" --prefix PYTHONPATH : $(toPythonPath ${pygtk})/gtk-2.0 --prefix PYTHONPATH : $(toPythonPath ${pygobject})/gtk-2.0 --prefix PYTHONPATH : $(toPythonPath ${pycairo})/gtk-2.0
  '';

  buildInputs = [
    libpcap libX11 gtk pkgconfig openssl python pygtk makeWrapper pysqlite
  ];
})
