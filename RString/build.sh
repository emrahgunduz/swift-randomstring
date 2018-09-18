#!/bin/bash

if [ -z "$1" ]; then
  echo "Configuration is not defined, building debug (debug|release)"
  CONF=debug
else
  CONF=$1
fi

if [ $CONF == release ]; then
  swift build --configuration release -Xswiftc -O
  ## cp -rf ./.build/release/rstring /usr/local/bin/rstring
  exit
fi

swift build --configuration debug -Xswiftc -Onone -Xswiftc -DDEBUG
## cp -rf ./.build/debug/rstring /usr/local/bin/rstring