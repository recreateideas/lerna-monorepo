#!/usr/bin/env bash

# Ensures script execution halts on first error
# shellcheck disable=SC2039
set -exo pipefail
source build/bash/assume-role.sh

# shellcheck disable=SC2039
# shellcheck disable=SC2154
[[ "$AWS_ACCOUNT_ID" ]]
# shellcheck disable=SC2039
[[ "$AWS_REGION" ]]

# Define some constants
readonly serviceName=$(node -pe "require('./services/${BAAS_PACKAGE}/cdk.json').context.projectName") 
readonly stackPrefix="dev-${serviceName}-feature-"

# Enforce cleanup to run for Dev Account only.
if [[ "${AWS_ACCOUNT_ID}" != "327922445464" ]]; then
    echo "Cleanup not required in this account (${AWS_ACCOUNT_ID}). Skipping cleanup."
    exit 0
fi

# Assume the role we need for cleanup:
stsAssumeRole "arn:aws:iam::${AWS_ACCOUNT_ID}:role/core-iam-curole"

readonly filter="                     \
{                                     \
    \"StackStatusFilter\": [          \
        \"CREATE_COMPLETE\",          \
        \"ROLLBACK_COMPLETE\",        \
        \"ROLLBACK_FAILED\",          \
        \"UPDATE_COMPLETE\",          \
        \"UPDATE_ROLLBACK_COMPLETE\", \
        \"UPDATE_ROLLBACK_FAILED\",   \
        \"DELETE_FAILED\"             \
   ]                                  \
}"
readonly query="StackSummaries[?contains(StackName,'$stackPrefix')].StackName"
readonly stacks=$(aws cloudformation list-stacks --cli-input-json "$filter" --query "$query" --output text --region "$AWS_REGION")

## --------------
#  Need to run git fetch , otherwise gitlab will only return the current branch ##
## --------------
git fetch origin

formattedGitBranches=""
gitBranchList=$(git branch -r)

# Loop through the open git branches
while read -r line; do
    ## if dependantabot branch, then use basename
    [[ ${line} =~ ^dependabot ]] && line="bot$(basename $line)"
    branchName=$(echo "$line" |
        sed 's#origin/##g' |
        sed 's/[^a-zA-Z0-9]//g')
    formattedGitBranches+=" ${branchName}"
done <<<"$gitBranchList"

echo "serviceName: ${serviceName}"
echo "stackPrefix: ${stackPrefix}"
echo "CloudFormation stacks:"
echo "$stacks"
echo "Remote Branches:"
echo "$formattedGitBranches"

getStackStatus() {
    # shellcheck disable=SC2086
    # shellcheck disable=SC2090
    # shellcheck disable=SC2206
    stackName=$1
    stackStatus=$(aws cloudformation list-stacks --region $AWS_REGION --query "StackSummaries[?StackName=='$stackName'].StackStatus" --output text)

    echo "CloudFormation stack $stackName, current status: $stackStatus (non-existent if blank)"
}

for stackName in $stacks; do
    branchName="${stackName#$stackPrefix}"

    # Test whether the branchName from this stack is in our list of git branches that still exist
    if [[ "$formattedGitBranches" = *"${branchName}"* ]]; then
        echo -e "\n-----Branch $branchName still exists in git. The stack will NOT be deleted."
    else
        # The git branch for this stack no longer exists, so we will clean up the stack.
        echo -e "\n-----Deleting stack: ${stackName}"
        aws cloudformation delete-stack --stack-name "${stackName}" --region "$AWS_REGION"

        ## --------------------------------------------------------
        ## temporary disabled as there is many stacks and codebuild is timing out after 18min
        ## with only 2 stacks deleted
        ## Future improvement: look into running the cleanup in batch of 5 cfn
        ## --------------------------------------------------------

        # Get the status of the CFN stack that will be deployed
        # getStackStatus $stackName

        # Wait until the stack status is no longer DELETE_IN_PROGRESS
        # while [[ "$stackStatus" == *"DELETE_IN_PROGRESS"* ]]
        # do
        # echo "Sleeping for $waitTime to allow the stack progress to complete."
        # sleep 10
        # getStackStatus $stackName
        # done
    fi
done
