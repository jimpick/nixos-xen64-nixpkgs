set -e

source $stdenv/setup

mkdir -p $out
$rubygems/bin/gem install -i $out $src

