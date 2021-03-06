args: with args; with stringsWithDeps; with lib;
(rec
{
        inherit writeScript; 

        src = getAttr ["src"] "" args;

        addSbinPath = getAttr ["addSbinPath"] false args;

        forceShare = if args ? forceShare then args.forceShare else ["man" "doc" "info"];
        forceCopy = ["COPYING" "LICENSE" "DISTRIBUTION" "LEGAL" 
          "README" "AUTHORS" "ChangeLog" "CHANGES" "LICENCE" "COPYRIGHT"] ++ 
          (optional (getAttr ["forceCopyDoc"] true args) "doc"); 

        hasSuffixHack = a: b: hasSuffix (a+(substring 0 0 b)) ((substring 0 0 a)+b);
        
        archiveType = s: 
                (if hasSuffixHack ".tar" s then "tar"
                else if (hasSuffixHack ".tar.gz" s) || (hasSuffixHack ".tgz" s) then "tgz" 
                else if (hasSuffixHack ".tar.bz2" s) || (hasSuffixHack ".tbz2" s) then "tbz2"
                else if (hasSuffixHack ".tar.lzma" s) then "tar.lzma"
                else if (hasSuffixHack ".zip" s) || (hasSuffixHack ".ZIP" s) then "zip"
                else if (hasSuffixHack "-cvs-export" s) then "cvs-dir"
                else if (hasSuffixHack ".nar.bz2" s) then "narbz2"

                # Mostly for manually specified directories..
                else if (hasSuffixHack "/" s) then "dir"

                # Last block - for single files!! It should be always after .tar.*
                else if (hasSuffixHack ".bz2" s) then "plain-bz2"

                else (abort "unknown archive type : ${s}"));

        defAddToSearchPath = FullDepEntry ("
                addToSearchPathWithCustomDelimiter() {
                        local delimiter=\$1
                        local varName=\$2
                        local needDir=\$3
                        local addDir=\${4:-\$needDir}
                        local prefix=\$5
                        if [ -d \$prefix\$needDir ]; then
                                if [ -z \${!varName} ]; then
                                        eval export \${varName}=\${prefix}\$addDir
                                else
                                        eval export \${varName}=\${!varName}\${delimiter}\${prefix}\$addDir
                                fi
                        fi
                }

                addToSearchPath()
                {
                        addToSearchPathWithCustomDelimiter \"\${PATH_DELIMITER}\" \"\$@\"
                }
        ") ["defNest"];

        defNest = noDepEntry ("
                nestingLevel=0

                startNest() {
                        nestingLevel=\$((\$nestingLevel + 1))
                                echo -en \"\\e[\$1p\"
                }

                stopNest() {
                        nestingLevel=\$((\$nestingLevel - 1))
                                echo -en \"\\e[q\"
                }

                header() {
                        startNest \"\$2\"
                                echo \"\$1\"
                }

                # Make sure that even when we exit abnormally, the original nesting
                # level is properly restored.
                closeNest() {
                        while test \$nestingLevel -gt 0; do
                                stopNest
                                        done
                }

                trap \"closeNest\" EXIT
        ");

        minInit = FullDepEntry ("
                set -e
                NIX_GCC=${stdenv.gcc}
                export SHELL=${stdenv.shell}
                PATH_DELIMITER=':'
        " + (if ((stdenv ? preHook) && (stdenv.preHook != null) && 
                        ((toString stdenv.preHook) != "")) then 
                "
                param1=${stdenv.param1}
                param2=${stdenv.param2}
                param3=${stdenv.param3}
                param4=${stdenv.param4}
                param5=${stdenv.param5}
                source ${stdenv.preHook}
        " +         
                "
                # Set up the initial path.
                PATH=
                for i in \$NIX_GCC ${toString stdenv.initialPath}; do
                    PATH=\$PATH\${PATH:+\"\${PATH_DELIMITER}\"}\$i/bin
                done

                export TZ=UTC

                prefix=${if args ? prefix then (toString args.prefix) else "\$out"}

                "
        else "")) ["defNest" "defAddToSearchPath"];
                
        addInputs = FullDepEntry ("
                # Recursively find all build inputs.
                findInputs()
                {
                    local pkg=\$1

                    case \$pkgs in
                        *\\ \$pkg\\ *)
                            return 0
                            ;;
                    esac
                    
                    pkgs=\"\$pkgs \$pkg \"

                        echo \$pkg
                    if test -f \$pkg/nix-support/setup-hook; then
                        source \$pkg/nix-support/setup-hook
                    fi
                }

                pkgs=\"\"
                for i in \$NIX_GCC ${toString realBuildInputs}; do
                    findInputs \$i
                done


                # Set the relevant environment variables to point to the build inputs
                # found above.
                addToEnv()
                {
                    local pkg=\$1
                "+
                (if !((args ? ignoreFailedInputs) && (args.ignoreFailedInputs == 1)) then "
                    if [ -e \$1/nix-support/failed ]; then
                        echo \"failed input \$1\" >&2
                        fail
                    fi
                " else "")
                +(if addSbinPath then "
                    if test -d \$1/sbin; then
                        export _PATH=\$_PATH\${_PATH:+\"\${PATH_DELIMITER}\"}\$1/sbin
                    fi
                " else "")
                +"
                    if test -d \$1/bin; then
                        export _PATH=\$_PATH\${_PATH:+\"\${PATH_DELIMITER}\"}\$1/bin
                    fi

                    for i in \"\${envHooks[@]}\"; do
                        \$i \$pkg
                    done
                }

                for i in \$pkgs; do
                    addToEnv \$i
                done


                # Add the output as an rpath.
                if test \"\$NIX_NO_SELF_RPATH\" != \"1\"; then
                    export NIX_LDFLAGS=\"-rpath \$out/lib \$NIX_LDFLAGS\"
                fi

                PATH=\$_PATH\${_PATH:+\"\${PATH_DELIMITER}\"}\$PATH
        ") ["minInit"];
        
        defEnsureDir = FullDepEntry ("
                # Ensure that the given directories exists.
                ensureDir() {
                    local dir
                    for dir in \"\$@\"; do
                        if ! test -x \"\$dir\"; then mkdir -p \"\$dir\"; fi
                    done
                }
        ") ["minInit"];

        toSrcDir = s : FullDepEntry ((if (archiveType s) == "tar" then "
                tar xvf '${s}'
                cd \"\$(tar tf '${s}' | head -1 | sed -e 's@/.*@@' )\"
        " else if (archiveType s) == "tgz" then "
                tar xvzf '${s}'
                cd \"\$(tar tzf '${s}' | head -1 | sed -e 's@/.*@@' )\"
        " else if (archiveType s) == "tbz2" then "
                tar xvjf '${s}'
                cd \"\$(tar tjf '${s}' | head -1 | sed -e 's@/.*@@' )\"
        " else if (archiveType s) == "tar.lzma" then "
                unlzma -d -c <'${s}' | tar xv
                cd \"\$(unlzma -d -c <'${s}' | tar t | head -1 | sed -e 's@/.*@@' )\"
        " else if (archiveType s) == "zip" then "
                unzip '${s}'
                cd \"$( unzip -lqq '${s}' | tail -1 | 
                        sed -e 's@^\\(\\s\\+[-0-9:]\\+\\)\\{3,3\\}\\s\\+\\([^/]\\+\\)/.*@\\2@' )\"
        " else if (archiveType s) == "cvs-dir" then "
                cp -r '${s}' .
                cd \$(basename ${s})
                chmod u+rwX -R .
        " else if (archiveType s) == "dir" then "
                cp -r '${s}' .
                cd \$(basename ${s})
                chmod u+rwX -R .
        " else if (archiveType s) == "narbz2" then "
                bzip2 <${s} | nix-store --restore \$PWD/\$(basename ${s} .nar.bz2)
                cd \$(basename ${s} .nar.bz2)
        " else if (archiveType s) == "plain-bz2" then "
                mkdir \$PWD/\$(basename ${s} .bz2)
                NAME=\$(basename ${s} .bz2)
                bzip2 -d <${s} > \$PWD/\$(basename ${s} .bz2)/\${NAME#*-}
                cd \$(basename ${s} .bz2)
        " else (abort "unknown archive type : ${s}"))+
                # goSrcDir is typically something like "cd mysubdir" .. but can be anything else 
                (if args ? goSrcDir then args.goSrcDir else "")
        ) ["minInit"];

        configureCommand = getAttr ["configureCommand"] "./configure" args;

        doConfigure = FullDepEntry ("
                ${configureCommand} --prefix=\"\$prefix\" ${toString configureFlags}
        ") ["minInit" "addInputs" "doUnpack"];

	doIntltool = FullDepEntry ("
		mkdir -p config
		intltoolize --copy --force
	") ["minInit" "addInputs" "doUnpack"];

        doAutotools = FullDepEntry ("
                mkdir -p config
                libtoolize --copy --force
                aclocal --force
                #Some packages do not need this
                autoheader || true; 
                automake --add-missing --copy
                autoconf
        ")["minInit" "addInputs" "doUnpack"];

        doMake = FullDepEntry ("        
                make ${toString makeFlags}
        ") ["minInit" "addInputs" "doUnpack"];

        doUnpack = toSrcDir (toString src);

        installPythonPackage = FullDepEntry ("
                python setup.py install --prefix=\"\$prefix\" 
                ") ["minInit" "addInputs" "doUnpack"];

        doPythonConfigure = FullDepEntry ('' 
          pythonVersion=$(toPythonPath "$prefix")
          pythonVersion=''${pythonVersion#*/lib/python}
          pythonVersion=''${pythonVersion%%/site-packages}
          ${if args ? extraPythonConfigureCommand then 
            args.extraPythonConfigureCommand 
          else ""}
          python configure.py -b "$prefix/bin" -d "$(toPythonPath "$prefix")" -v "$prefix/share/sip" ${toString configureFlags}
        '') ["minInit" "addInputs" "doUnpack"]; 

        doMakeInstall = FullDepEntry ("
                make ${toString (getAttr ["makeFlags"] "" args)} "+
                        "${toString (getAttr ["installFlags"] "" args)} install") ["doMake"];

        doForceShare = FullDepEntry (" 
                ensureDir \"\$prefix/share\"
                for d in ${toString forceShare}; do
                        if [ -d \"\$prefix/\$d\" -a ! -d \"\$prefix/share/\$d\" ]; then
                                mv -v \"\$prefix/\$d\" \"\$prefix/share\"
                                ln -sv share/\$d \"\$prefix\"
                        fi;
                done;
        ") ["minInit" "defEnsureDir"];

        doForceCopy = FullDepEntry (''
                name="$(basename $out)"
                name="''${name#*-}"
                ensureDir "$prefix/share/$name"
                for f in ${toString forceCopy}; do
                        cp -r "$f" "$prefix/share/$name/$f" || true
                done;
        '') ["minInit" "defEnsureDir"];

        doDump = n: noDepEntry "echo Dump number ${n}; set";

        patchFlags = if args ? patchFlags then args.patchFlags else "-p1";

        patches = getAttr ["patches"] [] args;

        toPatchCommand = s: "cat ${s} | patch ${toString patchFlags}";

        doPatch = FullDepEntry (concatStringsSep ";"
                (map toPatchCommand patches)
        ) ["minInit" "doUnpack"];

        envAdderInner = s: x: if x==null then s else y: 
                a: envAdderInner (s+"echo export ${x}='\"'\"\$${x}:${y}\";'\"'\n") a;

        envAdder = envAdderInner "";

        envAdderList = l:  if l==[] then "" else 
        "echo export ${__head l}='\"'\"\\\$${__head l}:${__head (__tail l)}\"'\"';\n" +
                envAdderList (__tail (__tail l));

        wrapEnv = cmd: env: "
                mv \"${cmd}\" \"${cmd}-orig\";
                touch \"${cmd}\";
                chmod a+rx \"${cmd}\";
                (${envAdderList env}
                echo '\"'\"${cmd}-orig\"'\"' '\"'\\\$@'\"' \n)  > \"${cmd}\"";

        doWrap = cmd: FullDepEntry (wrapEnv cmd (getAttr ["wrappedEnv"] [] args)) ["minInit"];

        makeManyWrappers = wildcard : wrapperFlags : FullDepEntry (''
          for i in ${wildcard}; do
            wrapProgram "$i" ${wrapperFlags}
          done
        '') ["minInit" "addInputs" "defEnsureDir"];

        wrapBinContentsPython = (makeManyWrappers 
          ''$out/bin/*'' 
          pythonWrapperArguments
        );

        pythonWrapperArguments = 
          (''--prefix PYTHONPATH : $(toPythonPath $out)'' +
          ''''${PYTHONPATH:+ --prefix PYTHONPATH : $PYTHONPATH}'');

        preservePathWrapperArguments = ''''${PATH:+ --prefix PATH : $PATH }'';

        doPropagate = FullDepEntry ("
                ensureDir \$out/nix-support
                echo '${toString (getAttr ["propagatedBuildInputs"] [] args)}' >\$out/nix-support/propagated-build-inputs
        ") ["minInit" "defEnsureDir"];

        /*debug = x:(__trace x x);
        debugX = x:(__trace (__toXML x) x);*/

        replaceScriptVar = file: name: value: ("sed -e 's`^${name}=.*`${name}='\\''${value}'\\''`' -i ${file}");
        replaceInScript = file: l: (concatStringsSep "\n" ((pairMap (replaceScriptVar file) l)));
        replaceScripts = l:(concatStringsSep "\n" (pairMap replaceInScript l));
        doReplaceScripts = FullDepEntry (replaceScripts (getAttr ["shellReplacements"] [] args)) [minInit];
        makeNest = x:(if x==defNest.text then x else "startNest\n" + x + "\nstopNest\n");
        textClosure = a : steps : textClosureMapOveridable makeNest a (["defNest"] ++ steps);

        inherit noDepEntry FullDepEntry PackEntry;

        defList = (getAttr ["defList"] [] args);
        getVal = getValue args defList;
        check = checkFlag args;
        reqsList = getAttr ["reqsList"] [] args;
        buildInputsNames = filter (x: (null != getVal x))
                (uniqList {inputList = 
                (concatLists (map 
                (x:(if (x==[]) then [] else builtins.tail x)) 
                reqsList));});
        configFlags = getAttr ["configFlags"] [] args;
        buildFlags = getAttr ["buildFlags"] [] args;
        nameSuffixes = getAttr ["nameSuffixes"] [] args;
        autoBuildInputs = assert (checkReqs args defList reqsList);
                filter (x: x!=null) (map getVal buildInputsNames);
        autoConfigureFlags = condConcat "" configFlags check;
        autoMakeFlags = condConcat "" buildFlags check;
        useConfig = getAttr ["useConfig"] false args;
        realBuildInputs = 
                lib.closePropagation ((if useConfig then 
                        autoBuildInputs else 
                        getAttr ["buildInputs"] [] args)++
                        (getAttr ["propagatedBuildInputs"] [] args));
        configureFlags = if useConfig then autoConfigureFlags else 
            getAttr ["configureFlags"] "" args;
        makeFlags = if useConfig then autoMakeFlags else getAttr ["makeFlags"] "" args;

        inherit lib;

        surroundWithCommands = x : before : after : {deps=x.deps; text = before + "\n" +
                x.text + "\n" + after ;};

	createDirs = FullDepEntry (concatStringsSep ";"
		(map (x: "ensureDir ${x}") (getAttr ["neededDirs"] [] args))
	) ["minInit" "defEnsureDir"];

	copyExtraDoc = FullDepEntry (''
          name="$(basename $out)"
          name="''${name#*-}"
          ensureDir "$out/share/doc/$name"
	'' + (concatStringsSep ";"
               (map 
	         (x: ''cp "${x}" "$out/share/doc/$name" || true;'') 
		 (getAttr ["extraDoc"] [] args)))) ["minInit" "defEnsureDir" "doUnpack"];

        realPhaseNames = 
	  (optional ([] != getAttr ["neededDirs"] [] args) "createDirs")
	  ++
	  args.phaseNames 
	  ++ 
          ["doForceShare" "doPropagate" "doForceCopy"]
	  ++
	  (optional ([] != getAttr ["extraDoc"] [] args) "copyExtraDoc")
          ++
          (optional (getAttr ["doCheck"] false args) "doMakeCheck")
          ++
          (optional (getAttr ["alwaysFail"] false args) "doFail")
          ;

        doFail = noDepEntry "
          echo 'Failing to keep builddir (and to invalidate result).'
          a() { return 127; } ; a ;
        ";

        doMakeCheck = FullDepEntry (''
          make check
        '') ["minInit"];

        extraDerivationAttrs = lib.getAttr ["extraDerivationAttrs"] {} args;

        # for overrides..
	builderDefsArgs = args;

        innerBuilderDefsPackage = bd: args: (
        let localDefs = bd.passthru.function args; in

        stdenv.mkDerivation ((rec {
          inherit (localDefs) name;
          builder = writeScript (name + "-builder")
            (textClosure localDefs localDefs.realPhaseNames);
          meta = localDefs.meta;
	  passthru = localDefs.passthru // {inherit (localDefs) src; };
        }) // (if localDefs ? propagatedBuildInputs then {
          inherit (localDefs) propagatedBuildInputs;
        } else {}) // extraDerivationAttrs)
        );

	builderDefsPackage = bd: func:
	  foldArgs 
	    (x: y: ((func (bd // x // y)) // y))
            (innerBuilderDefsPackage bd)
	    {};

   generateFontsFromSFD = FullDepEntry (''
           for i in *.sfd; do
                fontforge -c \
                        'Open($1);
                        ${optionalString (args ? extraFontForgeCommands) args.extraFontForgeCommands
                        }Reencode("unicode");
                         ${optionalString (getAttr ["createTTF"] true args) ''Generate($1:r + ".ttf");''}
                         ${optionalString (getAttr ["createOTF"] true args) ''Generate($1:r + ".otf");''}
                         Reencode("TeX-Base-Encoding");
                         ${optionalString (getAttr ["createAFM"] true args) ''Generate($1:r + ".afm");''}
                         ${optionalString (getAttr ["createPFM"] true args) ''Generate($1:r + ".pfm");''}
                         ${optionalString (getAttr ["createPFB"] true args) ''Generate($1:r + ".pfb");''}
                         ${optionalString (getAttr ["createMAP"] true args) ''Generate($1:r + ".map");''}
                         ${optionalString (getAttr ["createENC"] true args) ''Generate($1:r + ".enc");''}
                        ' $i; 
        done
   '') ["minInit" "addInputs" "doUnpack"];

   installFonts = FullDepEntry (''
           ensureDir $out/share/fonts/truetype/public/${args.name}
           ensureDir $out/share/fonts/opentype/public/${args.name}
           ensureDir $out/share/fonts/type1/public/${args.name}
           ensureDir $out/share/texmf/fonts/enc/${args.name}
           ensureDir $out/share/texmf/fonts/map/${args.name}

        cp *.ttf $out/share/fonts/truetype/public/${args.name} || echo No TrueType fonts
        cp *.otf $out/share/fonts/opentype/public/${args.name} || echo No OpenType fonts
           cp *.{pfm,afm,pfb} $out/share/fonts/type1/public/${args.name} || echo No Type1 Fonts
           cp *.enc $out/share/texmf/fonts/enc/${args.name} || echo No fontenc data
           cp *.map $out/share/texmf/fonts/map/${args.name} || echo No fontmap data
   '') ["minInit" "defEnsureDir"];

   simplyShare = shareName: FullDepEntry (''
     ensureDir $out/share
     cp -r . $out/share/${shareName}
   '') ["doUnpack" "defEnsureDir"];

   doPatchShebangs = dir: FullDepEntry (''
     patchShebangFun() {
     # Rewrite all script interpreter file names (`#! /path') under the
     # specified  directory tree to paths found in $PATH.  E.g.,
     # /bin/sh will be rewritten to /nix/store/<hash>-some-bash/bin/sh.
     # Interpreters that are already in the store are left untouched.
         echo "patching script interpreter paths"
         local f
         for f in $(find "${dir}" -type f -perm +0100); do
             local oldPath=$(sed -ne '1 s,^#![ ]*\([^ ]*\).*$,\1,p' "$f")
             if test -n "$oldPath" -a "''${oldPath:0:''${#NIX_STORE}}" != "$NIX_STORE"; then
                 local newPath=$(type -P $(basename $oldPath) || true)
                 if test -n "$newPath" -a "$newPath" != "$oldPath"; then
                     echo "$f: interpreter changed from $oldPath to $newPath"
                     sed -i "1 s,$oldPath,$newPath," "$f"
                 fi
             fi
         done
     }
     patchShebangFun;
   '') ["minInit"];

   createPythonInstallationTarget = FullDepEntry (''
     ensureDir $(toPythonPath $out)
     export PYTHONPATH=$PYTHONPATH''${PYTHONPATH:+:}$(toPythonPath $out)
   '') ["minInit" "addInputs" "defEnsureDir"];
}) // args
