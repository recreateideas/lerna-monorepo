#!/usr/bin/env bash
# set -exo pipefail
## environment set by Gitlab
set -x
[[ "$GITLAB_TOKEN" ]]
[[ "$CI_COMMIT_REF_NAME" ]]
[[ "$CI_PROJECT_ID" ]]
[[ "$CI_PROJECT_URL" ]]
[[ "$JIRA_TOKEN" ]]

readonly jira_api="https://beemit.atlassian.net/rest/api/2/issue"
readonly gitlab_mr_api="https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/merge_requests"
readonly gitlab_group_api="https://gitlab.com/api/v4/groups/14683677/members/all"
target_branch='develop'

if [[ "$CI_COMMIT_REF_NAME" =~ ^dependabot.* ]]; then
    echo "skipped - dependabot branch are excluded."
    exit 0
fi

## extract issue_number and branch_type from branch name ie: fix/qrb-xxx
branch="${CI_COMMIT_REF_NAME}"
jira_issue=$(echo ${branch} | cut -d '/' -f 2 | tr '[:lower:]' '[:upper:]')
branch_type=$(echo ${branch} | cut -d '/' -f 1)

## get Jira Issue Tittle
jira_title=$()$(
    curl -s "${jira_api}/${jira_issue}?fields=summary" \
        -H "Authorization: Basic ${JIRA_TOKEN}" \
        -H "Content-Type: application/json" |
        jq ".fields.summary" | tr -d '"'
)$()

# reviewer_ids=$()$(
#     curl -s -H "PRIVATE-TOKEN:${GITLAB_TOKEN}" \
#         "${gitlab_group_api}" |
#         jq '.[].id'
# )$()

# Manaully hardcode reviewers for now (Service Account cannot query groups)
# Tedy - 9734404
# Noah - 9797119
# Brendon - 10051410
# David - 9776521
# Jian - 9766115
# Claudio - 10164006
# Pradeep - 1734700

reviewer_ids='[]'

existing_mr=$()$(
    curl -s -H "PRIVATE-TOKEN:${GITLAB_TOKEN}" \
        "${gitlab_mr_api}?source_branch=${branch}&target_branch=${target_branch}&state=opened" |
        jq '.[0].iid'
)$()

## create or update MR
if [ ! "${existing_mr}" == "null" ]; then
    body="{
        \"id\": ${CI_PROJECT_ID},
        \"source_branch\": \"${branch}\",
        \"target_branch\": \"${target_branch}\",
        \"remove_source_branch\": true,
        \"title\": \"Draft: ${branch_type}(${jira_issue}): ${jira_title} - ${GITLAB_USER_LOGIN}\",
        \"labels\":\"${branch_type}\",
        \"squash\":\"true\"
    }"
    status=$()$(
        curl --silent -X PUT "${gitlab_mr_api}/${existing_mr}" \
            -H "PRIVATE-TOKEN:${GITLAB_TOKEN}" \
            -H "Content-Type: application/json" \
            --data "${body}"
    )$()
else
    body="{
        \"id\": ${CI_PROJECT_ID},
        \"source_branch\": \"${branch}\",
        \"target_branch\": \"${target_branch}\",
        \"remove_source_branch\": true,
        \"title\": \"Draft: ${branch_type}(${jira_issue}): ${jira_title}\",
        \"assignee_id\":\"${GITLAB_USER_ID}\",
        \"labels\":\"${branch_type}\",
        \"squash\":\"true\",
        \"reviewer_ids\":${reviewer_ids}
    }"
    status=$()$(
        curl --silent -X POST "${gitlab_mr_api}" \
            -H "PRIVATE-TOKEN:${GITLAB_TOKEN}" \
            -H "Content-Type: application/json" \
            --data "${body}"
    )$()
fi

echo "Completed $status"
exit
