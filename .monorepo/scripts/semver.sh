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

get_changes () {
  branch_name="$(git symbolic-ref HEAD 2>/dev/null)"
  branch_name=${branch_name##refs/heads/}
  # hash of the last local commit
  last_commit_sha=$(git log | grep commit -m 1 | awk '{ print $2 }');
  echo LAST $last_commit_sha
  # hash of the last origin commit
  last_origin_sha=$(git show origin/"$branch_name" | grep commit -m 1 | awk '{ print $2 }')
  echo ORIGIN $last_origin_sha
  # list of "packages" contained in the git diff
  CHANGES=$(git diff $last_commit_sha $last_origin_sha | grep "+++" | grep -oE "b\/packages\/[^/]+|b\/services\/[^/]+" | sort -u)
  echo $CHANGES
}

get_changes 

for scoped_package in $CHANGES; do
  echo $scoped_package
  prefix="b/"
  package_location=${scoped_package#"$prefix"}
  name=$(node -pe "require('./${package_location}/package.json').name") 
  current_version=$(node -pe "require('./${package_location}/package.json').version") 
  echo $name "----->" $current_version
done