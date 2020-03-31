#!/bin/sh
sed -i '' 's/(add\ \-\-no-verify\ to\ bypass)//g' node_modules/husky/lib/runner/index.js