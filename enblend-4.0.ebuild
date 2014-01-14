# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-gfx/enblend/enblend-4.0.ebuild,v 1.8 2010/11/08 22:05:28 maekke Exp $

EAPI=2

inherit eutils flag-o-matic

DESCRIPTION="Image Blending with Multiresolution Splines"
HOMEPAGE="http://enblend.sourceforge.net/"
SRC_URI="mirror://sourceforge/enblend/${PN}-enfuse-${PV/_rc/RC}.tar.gz"

LICENSE="GPL-2 VIGRA"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE="debug doc gpu +image-cache +openexr openmp"

RDEPEND="
	media-libs/glew
	=media-libs/lcms-1*
	>=media-libs/libpng-1.2.43
	media-libs/plotutils[X]
	media-libs/tiff
	virtual/jpeg
	gpu? ( media-libs/freeglut )
	openexr? ( >=media-libs/openexr-1.0 )"
DEPEND="${RDEPEND}
	>=dev-libs/boost-1.31.0
	dev-util/pkgconfig
	doc? (
		media-gfx/transfig
		|| ( sci-visualization/gnuplot[gd] >=sci-visualization/gnuplot-4.4[cairo] )
		media-fonts/freefont-ttf
		virtual/latex-base
	)"

S="${WORKDIR}/${PN}-enfuse-4.0-753b534c819d"

pkg_setup() {
	if use image-cache && use openmp; then
		ewarn "the openmp and image-cache USE-flags are mutually exclusive"
		ewarn "image-cache will be disabled in favour of openmp"
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-libpng15.patch
	epatch "${FILESDIR}"/${P}-doc-gnuplot-font.patch
}

src_configure() {
	# export LIBS=-lboost_system
	append-libs -lboost_system

	local myconf=""
	if use image-cache && use openmp; then
		myconf="--disable-image-cache --enable-openmp --without-boost-filesystem"
	else
		myconf="$(use_enable image-cache) $(use_enable openmp)"
	fi

	if use doc; then
		myconf="${myconf} --with-gnuplot=$(type -p gnuplot)"
		myconf="${myconf} --with-ttf-path=/usr/share/fonts/freefont-ttf"
	else
		myconf="${myconf} --with-gnuplot=false"
	fi

	econf \
		--with-x \
		$(use_enable debug) \
		$(use_enable gpu gpu-support) \
		$(use_with openexr) \
		${myconf}
}

src_compile() {
	# forcing -j1 as every parallel compilation process needs about 1 GB RAM.
	emake -j1 || die
	if use doc; then
		cd doc
		make enblend.pdf enfuse.pdf || die
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog NEWS README || die
	use doc && dodoc doc/en{blend,fuse}.pdf
}
