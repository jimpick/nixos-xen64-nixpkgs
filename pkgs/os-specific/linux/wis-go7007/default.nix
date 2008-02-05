{stdenv, fetchurl, kernel, ncurses, fxload}:

stdenv.mkDerivation {
  name = "wis-go7007-0.9.8";

  src = fetchurl {
    url = http://gentoo.osuosl.org/distfiles/wis-go7007-linux-0.9.8.tar.bz2;
    sha256 = "06lvlz42c5msvwc081p8vjcbv8qq1j1g1myxhh27xi8zi06n1mzg";
  };

  patches = map fetchurl [
    { url = "http://sources.gentoo.org/viewcvs.py/*checkout*/gentoo-x86/media-tv/wis-go7007/files/wis-go7007-0.9.8-kernel-2.6.17.diff?rev=1.1";
      sha256 = "0cizbg82fdl5byhvpkdx64qa02xcahdyddi2l2jn95sxab28a5yg";
    }
    { url = "http://sources.gentoo.org/viewcvs.py/*checkout*/gentoo-x86/media-tv/wis-go7007/files/wis-go7007-0.9.8-fix-udev.diff?rev=1.2";
      sha256 = "1985lcb7gh5zsf3lm0b43zd6q0cb9q4z376n9q060bh99yw6m0w1";
    }
    { url = "http://sources.gentoo.org/viewcvs.py/*checkout*/gentoo-x86/media-tv/wis-go7007/files/snd.patch?rev=1.1";
      sha256 = "0a6dz1l16pz1fk77s3awxh635cacbivfcfnd1carbx5jp2gq3jna";
    }
  ];

  buildInputs = [ncurses];

  preBuild = ''
    # Urgh, we need the complete kernel sources for some header
    # files.  So unpack the original kernel source tarball and copy
    # the configured include directory etc. on top of it.
    kernelVersion=$(cd ${kernel}/lib/modules && ls)
    kernelBuild=$(echo ${kernel}/lib/modules/$kernelVersion/source)
    tar xvfj ${kernel.src}
    kernelSource=$(echo $(pwd)/linux-*)
    cp -prd $kernelBuild/* $kernelSource

    #includeDir=$out/lib/modules/$kernelVersion/source/include/linux
    includeDir=$TMPDIR/scratch
    substituteInPlace Makefile \
        --replace '$(DESTDIR)$(KSRC)/include/linux' $includeDir \
        --replace '$(DESTDIR)$(FIRMWARE_DIR)' '$(FIRMWARE_DIR)'
    ensureDir $includeDir
    ensureDir $out/etc/hotplug/usb
    ensureDir $out/etc/udev/rules.d
 
    makeFlagsArray=(KERNELSRC=$kernelSource \
        FIRMWARE_DIR=$out/firmware FXLOAD=${fxload}/sbin/fxload \
        DESTDIR=$out SKIP_DEPMOD=1 \
        USE_UDEV=y)
  ''; # */

  postInstall = ''
    ensureDir $out/bin
    cp apps/gorecord apps/modet $out/bin/
  '';

  meta = {
    description = "Kernel module for the Micronas GO7007, used in a number of USB TV devices";
    homepage = http://oss.wischip.com/;
  };
}