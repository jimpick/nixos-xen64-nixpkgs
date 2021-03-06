args: with args;
stdenv.mkDerivation rec {
	name = "bsd-fingerd-0.17";

	src = fetchurl {
		url = "ftp://ftp.metalab.unc.edu/pub/linux/system/network/finger/bsd-finger-0.17.tar.gz";
		sha256 = "1yhkiv0in588il7f84k2xiy78g9lv12ll0y7047gazhiimk5v244";
	};

	NIX_CFLAGS_COMPILE="-D_GNU_SOURCE";

	patches = [./ubuntu-0.17-9.patch];

	preBuild = "cd fingerd";

	preInstall = '' ensureDir $out/man/man8 $out/sbin '';
}
