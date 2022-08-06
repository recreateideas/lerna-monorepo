#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# Save the remote origin head hash to file.
# (The sha saved to the file will be used to run a git compare)
save_remote_head() {
    head_file=$(node -pe "require('./.monorepo/config.json')['head-file']")
    repo_url=$(node -pe "require('./package.json').repository.url") 
    branch_name="$(git symbolic-ref HEAD 2>/dev/null)"
    branch_name=${branch_name##refs/heads/}
    current_head_sha=$(git ls-remote "${repo_url}" | grep "refs/heads/develop" | awk '{ print $1 }' )
    saved_head=`cat $head_file`

    echo CURRENT ORIGIN $current_head_sha
    echo SAVED ORIGIN $saved_head

    if [[ $current_head_sha == "$saved_head"  ]]; then
        echo "> Same head."
        exit 0
    fi

    echo "$current_head_sha" > $head_file

    git add $head_file
    git commit -m "fix(last-head): updated" --no-verify
    git reset HEAD~1 --soft
    git commit --amend --no-edit
}