# ecw-gdal-build

Builds ECW reading for GDAL on Linux: the ERDAS ECW/JPEG 2000 SDK 3.3 (2006), and GDAL's ECW driver as a plugin built
for an existing GDAL install. SurveyDeliver uses it to read aerial images delivered as ECW.

```sh
sudo GDAL_PREFIX=/path/to/env bash build-ecw.sh
```

- **SDK:** libecwj2 3.3 from [makinacorpus/libecw](https://github.com/makinacorpus/libecw) (the 2006-08-29 sources
  with autotools), pinned to commit `d5bef96`. It is built with `-std=gnu++98 -fpermissive` so modern GCC accepts it.
  It installs to `/opt/ecw` (or `ECW_PREFIX`).
- **Driver:** `frmts/ecw` from the GDAL source of the same version as the installed GDAL. It is built as a standalone
  plugin and installed in `$GDAL_PREFIX/lib/gdalplugins`. `/etc/ld.so.conf.d/ecw.conf` points the loader at the SDK.
- **Reads:** ECW version 2 files, which is the usual kind. ECW version 3 needs ERDAS SDK 5.
- **Checked on:** GDAL 3.13.3, GCC 15.2, Ubuntu 26.04.

## Licences

- This script: GNU General Public License v3 ([LICENSE](LICENSE)).
- The ECW SDK 3.3 is used under its *ECW JPEG 2000 SDK Public Use License Agreement*, for use with software that is
  open source and free to the public. Its restriction on server software was removed on 8 June 2005. The full text is
  in [ECW-SDK-3.3-LICENSE.txt](ECW-SDK-3.3-LICENSE.txt).
- GDAL is MIT licensed.

Nothing here is modified from its sources: the SDK and GDAL are downloaded and built as published.
