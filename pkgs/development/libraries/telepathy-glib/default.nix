args: with args;
stdenv.mkDerivation rec {
	name = "telepathy-glib-0.7.0";

	src = fetchurl {
		url = "${meta.homepage}/releases/telepathy-glib/${name}.tar.gz";
		sha256 = "0hf1jrgisr7skrji7djh66q0ic351vlsm65xqy982p5d0axzxkz5";
	};

	propagatedBuildInputs = [dbus_glib glib python];
	buildInputs = [pkgconfig libxslt];
	configureFlags = "--enable-shared --disable-static";

	meta = {
		homepage = http://telepathy.freedesktop.org;
	};
}
