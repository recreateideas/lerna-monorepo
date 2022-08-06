#!/usr/bin/env bash
# This script is sourced by the build pipeline. It provides a single function named stsAssumeRole().
#


############################################################################
###
### Description:
###   It uses AWS STS AssumeRole to get credentials for an IAM Role, and the credentials are then set in
###   the AWS Environment Variables. This will cause all subsequent aws cli commands to use the assumed role.
### Params:
###   $1 -> roleArn: the full ARN of the IAM Role to be assumed
###
###########################################################################
stsAssumeRole(){
  # shellcheck disable=SC2039
  local roleArn="$1"

  echo "Assuming Role as $roleArn"
  set +x # Turn off the debug setting -- Don't output secrets in the console
  aws sts assume-role --role-arn "$roleArn" --role-session-name bass-ci --output text > /tmp/credentials.txt

  # shellcheck disable=SC2039
  AWS_ACCESS_KEY_ID=$(grep CREDENTIALS /tmp/credentials.txt | cut -d$'\t' -f2)
  export AWS_ACCESS_KEY_ID

  # shellcheck disable=SC2039
  AWS_SECRET_ACCESS_KEY=$(grep CREDENTIALS /tmp/credentials.txt | cut -d$'\t' -f4)
  export AWS_SECRET_ACCESS_KEY

  # shellcheck disable=SC2039
  AWS_SESSION_TOKEN=$(grep CREDENTIALS /tmp/credentials.txt | cut -d$'\t' -f5)
  export AWS_SESSION_TOKEN

  set -x # Turn debug output back on
}
