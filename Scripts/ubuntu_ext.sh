#!/usr/bin/env bash

set -eu

clear && PHP_SRC_ROOT=/usr/include/php/20230831 swift build \
    --configuration debug \
    -Xcc -D_GNU_SOURCE \
    -Xcc -U__SSE2__ \
    -Xcc -fno-builtin \
    -Xcc -I/usr/include/php/20230831 \
    -Xcc -I/usr/include/php/20230831/main \
    -Xcc -I/usr/include/php/20230831/Zend \
    -Xcc -I/usr/include/php/20230831/TSRM \
    -Xlinker -L/usr/include/php/20230831/libs \
    -Xlinker /usr/lib/libphp.so