#!/usr/bin/env bash

set -eu

# -d extension=.build/debug/libSwiftPHPExtension.dylib -r "echo raylib\confirm_raylib_compiled();"

clear \
    && PHP_SRC_ROOT=/Users/josephmontanez/Documents/dev/SwiftPHP/PHP.xcframework/ios-arm64/Headers \
        swift build -vv \
            --configuration debug \
            -Xcc -DZEND_DEBUG \
            -Xcc -DZTS \
            -Xswiftc -DZTS \
            -Xcc -U__SSE2__ \
            -Xcc -I$PHP_SRC_ROOT \
            -Xcc -I$PHP_SRC_ROOT/main \
            -Xcc -I$PHP_SRC_ROOT/Zend \
            -Xcc -I$PHP_SRC_ROOT/TSRM \
    && build/php-src/sapi/cli/php -d extension=.build/arm64-apple-macosx/debug/libSwiftPHPExtension.dylib -r "echo confirm_raylib_compiled();"
    
#sudo /Volumes/External/downloads/Xcode.app/Contents/Developer/usr/bin/lldb build/php-src/sapi/cli/php