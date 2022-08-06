#!/usr/bin/env bash
# This script is called by the build pipeline. It runs the postman tests against the deployed API stack.
# There are three parameters required for this script:
#   environment: the simple name of the environment to be tested; e.g. "dev" or "stage" or "prod" (referenced as $ENVIRONMENT)
#   accountNumber: the account number for the given account; used to assume a role in that account (referenced as $AWS_ACCOUNT_ID)
#   [optional] branch: the branch that we should be testing against (referenced as $branch)

# Ensures script execution halts on first error
set -exo pipefail
source build/bash/vars.sh
source build/bash/assume-role.sh

# Testing to confirm that these variables are set.
[[ "$ENVIRONMENT" ]]

[[ "$AWS_ACCOUNT_ID" ]]

[[ "$branch" ]]

echo "Requested to run postman tests in '$ENVIRONMENT' ($AWS_ACCOUNT_ID), targeting '$branch'"

# Export the feature branch id and environment to run the tests against
export BRANCH_NAME="${branch#main}"
export API_ENV="$ENVIRONMENT"
export ACCOUNT_NUMBER="$accountNumber"

# Only assume the role if we're not testing locally
if [ "$AWS_ACCOUNT_ID" != "local" ]; then
  stsAssumeRole "arn:aws:iam::${AWS_ACCOUNT_ID}:role/core-iam-cirole"
fi

# Make sure the configuration is correct for postman in the lower environments or any other feature branches
if [[ ("$ENVIRONMENT" != "prod" || $FEATURE_BRANCH) && -n "$branch" && "$branch" != "main" ]]; then
  BRANCH_NAME="baas-gateway-$branch"
  TIMEOUT=60000 # Development durations currently SUCK, and we need to allow it to run for up to a minute 😭
  # TODO: Tune the lower environments and ensure that they can return faster!
fi

# Make sure we're targeting the right domain:
case $API_ENV in
"dev") TESTING_URL="https://dev.api.platform.beemit.com.au/${BRANCH_NAME:-baas-gateway-develop}" ;;
"stage") TESTING_URL="https://stage.api.platform.beemit.com.au/${BRANCH_NAME:-baas-gateway-develop}" ;;
"release") TESTING_URL="https://stage.api.platform.beemit.com.au/${BRANCH_NAME:-baas-gateway-release}" ;;
*) TESTING_URL="https://api.platform.beemit.com.au" ;;
esac

[[ $TESTING_URL ]]

echo "About to validate our Postman collection against this branch: $ENVIRONMENT ${BRANCH_NAME:+-> ${BRANCH_NAME}} ('$TESTING_URL')"
npm run postman:scoped -- --env-var TESTING_URL=$TESTING_URL --env-var REQUEST_TIMEOUT=${TIMEOUT:-500} --verbose
