#!/bin/bash

set -e

function setup_env() {
    setup_deb_env $@
    builddir="pkg-build"
}

function place_files() {
    local pkgname="$1"
    local targdir="$2"
    local pkgtype="$3"

    if [ "$pkgname" == "json-configurator" ]; then
        mkdir -p "$targdir/usr/bin/"
        cp "src/jc" "$targdir/usr/bin/"
    fi
}

function build_package() {
    local pkgtype="$1"
    shift

    if [ "$pkgtype" == "deb" ]; then
        build_deb_package $@
    else
        >&2 echo
        >&2 echo "E: Don't know how to build packages of type '$pkgtype'"
        >&2 echo
        exit 11
    fi
}

. /usr/lib/ks-std-libs/libpkgbuilder.sh
build

