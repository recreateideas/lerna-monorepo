#!/usr/bin/env bash
# This script is called by the build pipeline. It runs the API tests against the deployed API stack.
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

echo "Requested to run API tests in '$ENVIRONMENT' ($AWS_ACCOUNT_ID), targeting '$branch'"

# Export the feature branch id and environment to run the tests against
export BRANCH_NAME="${branch#main}"
export API_ENV="$ENVIRONMENT"

# Only assume the role if we're not testing locally
if [ "$AWS_ACCOUNT_ID" != "local" ]; then
  stsAssumeRole "arn:aws:iam::${AWS_ACCOUNT_ID}:role/core-iam-cirole"
fi

# Now execute the API tests:
echo "About to run API tests against this branch: $ENVIRONMENT ${branch:+-> ${branch}}"
npm run test:api:scoped