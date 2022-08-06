#!/usr/bin/env bash

source build/bash/vars.sh
source build/bash/assume-role.sh
# shellcheck disable=SC2039
# shellcheck disable=SC2154
[[ "$branch" ]]

[[ "$ENVIRONMENT" ]]

[[ "$AWS_ACCOUNT_ID" ]]

## cdk will use the set of role that are created using the bootstrap. rolename: cdk-*
cd services/${BAAS_PACKAGE}
npx aws-cdk --require-approval never deploy --all -c branchName=$branch -c environment=$ENVIRONMENT
