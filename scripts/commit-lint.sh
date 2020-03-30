#!/bin/bash
echo 'ciao'
OUTPUT=$(commitlint -E HUSKY_GIT_PARAMS)
echo $OUTPUT