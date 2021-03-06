buildInputs="$jdk5"
source $stdenv/setup

export JDK_HOME=$jdk5
export JAVA_HOME=$jdk5

tar xfvz $src
cd jboss-*
cd build
sh build.sh
ensureDir $out
cp -av output/jboss-*/* $out

# Insert JAVA_HOME variable to make sure the latest JRE is used and not version 5
sed -i -e "/GREP/aJAVA_HOME=$jdk" $out/bin/run.sh
