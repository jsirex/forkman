pkg_name=forkman
pkg_origin=biome
pkg_version="0.1.0"
pkg_maintainer="The Biome Maintainers <humans@biome.sh>"
pkg_license=("Apache-2.0")
pkg_deps=(
  core/file
  core/bundler
  core/ruby
  core/tar
  core/busybox-static
  core/rq
  core/gcc
  core/make
  core/pkg-config
  core/git
  core/openssh
)
# pkg_build_deps=(
#   core/make
#   core/gcc
# )
pkg_bin_dirs=(bin)

do_prepare() {
  GEM_HOME="$(pkg_path_for bundler)"
  build_line "Setting GEM_HOME=${GEM_HOME}"
  GEM_PATH="${GEM_HOME}"
  build_line "Setting GEM_PATH=${GEM_PATH}"
  export GEM_HOME GEM_PATH
  bundle config build.ruby-filemagic --with-magic-dir="$(hab pkg path core/file)"
}

do_build() {
  return 0
}

do_install() {
  bundle install
  cp patch-project.sh "${pkg_prefix}/bin/"
  cp forkman.rb "${pkg_prefix}/bin/"
  return 0
}
