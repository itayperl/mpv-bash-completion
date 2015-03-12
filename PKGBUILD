# Maintainer: Jens John <dev@2ion.de>
pkgname=mpv-bash-completion-git
_completioncommand=mpv
pkgver=1
pkgrel=1
pkgdesc="Bash completion generator the mpv media player"
arch=('any')
url="https://github.com/2ion/mpv-bash-completion"
license=('GPL')
depends=('mpv' 'bash')
makedepends=('git' 'mpv' 'bash' 'coreutils')
provides=("${pkgname%-git}")
conflicts=("${pkgname%-git}")
source=('git+https://github.com/2ion/mpv-bash-completion.git#branch=arch')
noextract=()
md5sums=('SKIP')

pkgver() {
	cd "$srcdir/${pkgname%-git}"
  local _mpv_pkg_ver=$(package-query -Qf%v mpv)
  printf "%sr%s.%s" "${_mpv_pkg_ver%-*}" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

build() {
	cd "$srcdir/${pkgname%-git}"
  ./gen.sh > "$_completioncommand"
}

check() {
	cd "$srcdir/${pkgname%-git}"
  bash -n "$_completioncommand"
}

package() {
	cd "$srcdir/${pkgname%-git}"
  install -Dm644 "${_completioncommand}" "/etc/bash_completion.d/${_completioncommand}"
}
