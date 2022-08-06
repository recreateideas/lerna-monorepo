#!/usr/bin/env bash
# This script is called by the build pipeline. It packages the app and archives the build artifacts to S3
# There is one parameter required for this script:
#   region: the target AWS region where this app is meant to be deployed; e.g. "us-east-1" or "ap-southeast-2"
# The following environment variables will be used from the vars.sh script:
#   appName: the name of the npm package pulled from package.json
#   branch: the abbreviated, formatted branch name based on the story number, e.g. "abc1234" or "main"
#   s3Folder: the path to be used in the S3 bucket for storing artifacts
#              This is recommended to be structured something like this:
#                  ${appName}/${branch}/${releaseVersion}

# The following variable must be pre-defined by the build container:
#   ARTIFACTS_BUCKET: the name of the AWS S3 bucket to be used for storing build artifacts

# Ensures script execution halts on first error

# shellcheck disable=SC2039
set -exo pipefail

readonly region="$AWS_REGION"

# shellcheck disable=SC1091
# shellcheck disable=SC2039
source build/bash/vars.sh

# Testing to confirm that these variables are set.
# shellcheck disable=SC2039
[[ "$region" ]]
# shellcheck disable=SC2039
# shellcheck disable=SC2154
[[ "$appName" ]]
# shellcheck disable=SC2039
# shellcheck disable=SC2154
[[ "$branch" ]]
# shellcheck disable=SC2039
# shellcheck disable=SC2154
[[ "$s3Folder" ]]
# shellcheck disable=SC2039
[[ "$ARTIFACTS_BUCKET" ]]

mkdir -p build/output

# Assuming cfn-lint is available in the base-image, lint the infra definitions
cfn-lint --template microservice.sam.yml --regions ${region}

# Create the package file and lambda zips
sam package --template-file microservice.sam.yml --s3-bucket "${ARTIFACTS_BUCKET}" --s3-prefix "${s3Folder}/lambda" --output-template-file "build/output/package-${region}.yml"

# Archive the artifacts
aws s3 cp lambda-tests "s3://${ARTIFACTS_BUCKET}/${s3Folder}/tests" --no-progress --recursive
aws s3 cp "build/output/package-${region}.yml" "s3://${ARTIFACTS_BUCKET}/${s3Folder}/cfn/package-${region}.yml" --no-progress
aws s3 cp "microservice.sam.monitoring.yml" "s3://${ARTIFACTS_BUCKET}/${s3Folder}/cfn/microservice.sam.monitoring.yml" --no-progress

## Temporarily commented out - until github deploy keys are created.
# shellcheck disable=SC2039
#if [[ "${branch}" == "main" ]]; then
# main branch artifacts get synced to the "latest" artifact location

# aws s3 sync "s3://${ARTIFACTS_BUCKET}/${s3Folder}" "s3://${ARTIFACTS_BUCKET}/${appName}/${branch}/latest" --no-progress --delete
#fi
