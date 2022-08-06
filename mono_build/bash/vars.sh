#!/usr/bin/env bash
# This script is sourced by other shell scripts. It defines reusable variables across multiple steps of the pipeline.
# The variables defined by this script are:
#   branch: the abbreviated, formatted branch name based on the story number, e.g. "abc1234" or "main"
#   appName: the name of the npm package pulled from package.json
#   releaseVersion: the unique build version, including feature branch pre-release indicator, e.g. "0.1.123-abc456"
#   s3Folder: the path to be used in the S3 bucket for storing artifacts, recommended to be structured something like this:
#              ${appName}/${branch}/${releaseVersion}

# The following variable must be pre-defined by the build container:
#   ARTIFACTS_BUCKET: the name of the AWS S3 bucket to be used for storing build artifacts

product="baas-gateway"

######
# Dependentabot is causing cfn failure due to the function name exceeding 64 characters
# e.g: "'devdependabotnpmandyarntypesnode16111_minnie_TrxGetOfferCategories' at 'functionName'
#        failed to satisfy constraint: Member must have length less than or equal to 64"
# To resolve this, we shorten everything that contains 'dependabot' down to 'bot'
######
[[ ${CI_COMMIT_BRANCH} =~ ^dependabot ]] && CI_COMMIT_BRANCH="bot$(basename $CI_COMMIT_BRANCH)"
branch=$(echo ${CI_COMMIT_BRANCH} | sed 's/[^a-zA-Z0-9]//g')

# appName is extracted from the package.json file, or the build/output/app-name.txt file, which get created during the build step
if [ -z "$appName" ]; then
  if [ -e build/output/app-name.txt ]; then
    appName=$(cat build/output/app-name.txt) # app-name.txt was created by a previous build step
  else
    appName=$(node -pe "require('./services/${BAAS_PACKAGE}/cdk.json').context.projectName") 
  fi
fi

# releaseVersion gets computed and then saved to the build/output/release-version.txt file during the build step
if [ -z "$releaseVersion" ]; then
  if [ -e build/output/release-version.txt ]; then
    releaseVersion=$(cat build/output/release-version.txt) # release-version.txt was created by a previous build step
  else
    releaseVersion=$(./build/bash/get-release-version.sh "$branch")
  fi
fi

# shellcheck disable=SC2034
s3Folder="${appName}/${branch}/${releaseVersion}"
