set -euo pipefail

NIXL_SRC="${NIXL_SRC:-/tmp/nixl}"
NIXL_REQUIRE_ROCM="${NIXL_REQUIRE_ROCM:-1}"
UCX_PREFIX="${UCX_PREFIX:-/opt/rocnixl-ucx}"
ROCM_PATH="${ROCM_PATH:-/opt/rocm}"
AIS_PATH="${AIS_PATH:-${ROCM_PATH}}"
NIXL_INSTALL_PREFIX="${NIXL_INSTALL_PREFIX:-/opt/nixl}"

BUILD_JOBS="${BUILD_JOBS:-$(nproc)}"

mkdir -p /tmp/ucx-rocm
cd /tmp/ucx-rocm
if [[ ! -d ucx-src/.git ]]; then
	rm -rf ucx-src
	git clone --depth 1 https://github.com/ROCm/ucx.git -b v1.19.x ucx-src
fi
cd ucx-src
./autogen.sh
rm -rf build
mkdir build
cd build
# UCX configure flags.
UCX_CONFIGURE_FLAGS=(
	--prefix="${UCX_PREFIX}"
	--enable-shared
	--disable-static
	--disable-doxygen-doc
	--enable-devel-headers
	--with-rocm="${ROCM_PATH}"
	--with-verbs
	--with-dm
	--enable-mt
)
# Improve compile time for dist-build-fast target.
if [[ "${AIC_UCX_FAST:-0}" == "1" ]]; then
	UCX_CONFIGURE_FLAGS+=(
		--disable-logging
		--disable-debug
		--disable-assertions
		--disable-params-check
		--without-knem
		--without-xpmem
		--without-ugni
		--without-java
	)
else
	UCX_CONFIGURE_FLAGS+=(--enable-optimizations)
fi
../configure "${UCX_CONFIGURE_FLAGS[@]}"
make -j"${BUILD_JOBS}"
make install
ldconfig

