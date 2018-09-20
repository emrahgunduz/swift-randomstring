#!/bin/bash

if [ -z "$1" ]; then
  echo "Configuration is not defined, building debug (debug|release)"
  CONF=debug
else
  CONF=$1
fi

if [ $CONF == release ]; then
  swift build --configuration release -Xswiftc -O -Xswiftc -whole-module-optimization
  ## cp -rf ./.build/release/rstring /usr/local/bin/rstring
  exit
fi

swift build --configuration debug \
            -Xswiftc -whole-module-optimization \
            -Xswiftc -Onone \
            -Xswiftc -DDEBUG \
            -Xswiftc -Xfrontend -Xswiftc -warn-long-function-bodies=100 \
            -Xswiftc -Xfrontend -Xswiftc -warn-long-expression-type-checking=100
## cp -rf ./.build/debug/rstring /usr/local/bin/rstring
