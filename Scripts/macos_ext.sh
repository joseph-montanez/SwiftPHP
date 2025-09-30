#!/usr/bin/env bash

set -eu

# -d extension=.build/debug/libSwiftPHPExtension.dylib -r "echo raylib\confirm_raylib_compiled();"

clear \
    && PHP_SRC_ROOT=build/php-src \
        /Volumes/External/downloads/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift build -vv \
            --configuration debug \
            -Xcc -DZEND_DEBUG \
            -Xcc -DZTS \
            -Xswiftc -DZTS \
            -Xcc -U__SSE2__ \
            -Xcc -Ibuild/php-src \
            -Xcc -Ibuild/php-src/main \
            -Xcc -Ibuild/php-src/Zend \
            -Xcc -Ibuild/php-src/TSRM \
    && build/php-src/sapi/cli/php -d extension=.build/debug/libSwiftPHPExtension.dylib -r "echo confirm_raylib_compiled();"
    
#sudo /Volumes/External/downloads/Xcode.app/Contents/Developer/usr/bin/lldb build/php-src/sapi/cli/php