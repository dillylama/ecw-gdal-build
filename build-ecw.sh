#!/usr/bin/env bash
# Build ECW reading for GDAL on Linux: the ERDAS ECW/JPEG 2000 SDK 3.3 (2006) and GDAL's ECW driver as a plugin,
# built for the GDAL already installed under GDAL_PREFIX (for example a conda environment).
#
#   sudo GDAL_PREFIX=/path/to/env bash build-ecw.sh
#
# SDK 3.3 is used under its "ECW JPEG 2000 SDK Public Use License Agreement" (ECW-SDK-3.3-LICENSE.txt), for use with
# open-source software that is free to the public; its restriction on server software was removed on 8 June 2005.
# It reads ECW version 2 files (the usual kind); ECW version 3 needs ERDAS SDK 5.
#
# Installs:  $ECW_PREFIX (default /opt/ecw)              the SDK (headers + libNCSEcw*.so)
#            $GDAL_PREFIX/lib/gdalplugins/gdal_ECW_JP2ECW.so  GDAL's ECW driver
#            /etc/ld.so.conf.d/ecw.conf                 so the driver finds the SDK
# Safe to run again: everything is rebuilt in $ECW_BUILD and the installed parts are replaced.
set -euo pipefail
GDAL_PREFIX=${GDAL_PREFIX:-${CONDA_PREFIX:-}}
[ -n "$GDAL_PREFIX" ] && [ -x "$GDAL_PREFIX/bin/gdalinfo" ] || { echo "Set GDAL_PREFIX to the folder that holds bin/gdalinfo"; exit 1; }
PREFIX=${ECW_PREFIX:-/opt/ecw}
BUILD=${ECW_BUILD:-/opt/ecw-build}
LIBECW_REPO=https://github.com/makinacorpus/libecw.git   # libecwj2 3.3 sources (2006-08-29) with autotools for Linux
LIBECW_COMMIT=d5bef96
GDAL_VERSION=$("$GDAL_PREFIX/bin/gdal-config" --version 2>/dev/null || "$GDAL_PREFIX/bin/gdalinfo" --version | sed -E 's/GDAL ([0-9.]+).*/\1/')

mkdir -p "$BUILD" && cd "$BUILD"

# 1. The SDK. Old C++: built as gnu++98, permissive. "make install" expects the include folder to exist.
rm -rf libecw && git clone -q "$LIBECW_REPO" libecw && git -C libecw checkout -q "$LIBECW_COMMIT"
cd libecw
nice -n 15 ./configure CFLAGS="-O2 -w -fpermissive -fcommon" CXXFLAGS="-O2 -w -std=gnu++98 -fpermissive -fcommon" \
  --enable-shared --disable-static --prefix="$PREFIX" > ../configure.log 2>&1
nice -n 15 make -j"$(nproc)" > ../make.log 2>&1
mkdir -p "$PREFIX/include" && make install > ../install.log 2>&1
cd "$BUILD"

# 2. GDAL's ECW driver, from the source of the same GDAL version, as a standalone plugin.
rm -rf gdal-src build-plugin && mkdir gdal-src
curl -sfL -o gdal.tar.gz "https://github.com/OSGeo/gdal/releases/download/v$GDAL_VERSION/gdal-$GDAL_VERSION.tar.gz"
tar xzf gdal.tar.gz -C gdal-src --strip-components=1
ECW_ROOT="$PREFIX" nice -n 15 cmake -S gdal-src/frmts/ecw -B build-plugin -DCMAKE_PREFIX_PATH="$GDAL_PREFIX" -DECW_ROOT="$PREFIX" \
  -DCMAKE_INCLUDE_PATH="$PREFIX/include" -DCMAKE_LIBRARY_PATH="$PREFIX/lib" -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS="-fpermissive -w" > cmake.log 2>&1
nice -n 15 cmake --build build-plugin -j"$(nproc)" > build.log 2>&1
mkdir -p "$GDAL_PREFIX/lib/gdalplugins"
install -m 0755 build-plugin/gdal_ECW_JP2ECW.so "$GDAL_PREFIX/lib/gdalplugins/gdal_ECW_JP2ECW.so"
chmod -R a+rX "$PREFIX"
echo "$PREFIX/lib" > /etc/ld.so.conf.d/ecw.conf && ldconfig

# 3. Check: GDAL lists the ECW reader.
"$GDAL_PREFIX/bin/gdalinfo" --formats | grep -q "^  ECW -raster-" && echo "ECW reader installed (GDAL $GDAL_VERSION, SDK 3.3)" || { echo "ECW reader NOT found"; exit 1; }
