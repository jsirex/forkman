# shellcheck shell=bash

pkg_origin=ya
pkg_name=forkman
pkg_version="0.1.0"

pkg_description="Repository Fork Manager"
pkg_maintainer="Yauhen Artsiukhou <jsirex@gmail.com>"
pkg_license=("MIT")

pkg_deps=(
    core/file
    core/ruby
)

pkg_build_deps=(
    core/gcc
    core/make
)

pkg_bin_dirs=(bin)

do_prepare() {
    bundle config build.ruby-filemagic --with-magic-dir="$(pkg_path_for core/file)"

    # shellcheck disable=SC2154
    cp -v Gemfile "$CACHE_PATH/Gemfile.biome"
}

do_build() {
    return 0
}

do_install() {
    # shellcheck disable=SC2154
    bundle install --gemfile "$CACHE_PATH/Gemfile.biome" --path "$pkg_prefix/rubygems"

    mkdir -p "${pkg_prefix}/lib"
    cp forkman.rb "${pkg_prefix}/lib"

    ruby_wrapper
}

# Wraps regular ruby script according to current GEM_HOME with appropriate LOAD_PATH
ruby_wrapper() {
    # shellcheck disable=SC2155
    local ruby_path="$(pkg_path_for core/ruby)/bin/ruby"
    local gem_path="$pkg_prefix/rubygems/ruby/2.5.0"
    local cli_path="$pkg_prefix/lib/forkman.rb"
    local cli_name="forkman"

    cat <<EOF > "$pkg_prefix/bin/$cli_name"
#!$ruby_path

# This is automatically generate wrapper for $pkg_name $pkg_version

# Make sure absolute path
LIBDIRS = File.join('$gem_path', 'gems', '*','lib')

Dir.glob(LIBDIRS).each do |libdir|
  \$LOAD_PATH.unshift(libdir) unless \$LOAD_PATH.include?(libdir)
end

load "$cli_path"
EOF
    chmod +x "$pkg_prefix/bin/$cli_name"
}
