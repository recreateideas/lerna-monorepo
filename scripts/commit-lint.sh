#!/bin/bash
echo 'ciao'
echo $1
OUTPUT=$(commitlint -E HUSKY_GIT_PARAMS)
echo $OUTPUT