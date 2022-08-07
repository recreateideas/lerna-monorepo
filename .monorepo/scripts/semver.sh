
branch_name="$(git symbolic-ref HEAD 2>/dev/null)"
branch_name=${branch_name##refs/heads/}
head_file=$(node -pe "require('./.monorepo/config.json')['head-file']")
# hash of the last origin commit
last_origin_sha=$(git show origin/"$branch_name" | grep commit -m 1 | awk '{ print $2 }')
echo ">>> ORIGIN:" $last_origin_sha
saved_last_origin=`cat $head_file`
echo ">>> LAST SAVED ORIGIN:" $saved_last_origin
# hash of the last local commit
last_commit_sha=$(git log | grep commit -m 1 | awk '{ print $2 }');
echo ">>> LAST COMMIT:" $last_commit_sha

##############
### PREPUSH ##
##############
save_remote_head_pre_push() {
    # if remote origin sha is the same as currently saved, skip saving to file
    if [[ $last_origin_sha != "$saved_last_origin"  ]]; then
      echo ">>> Saving new last origin to file.'"
      # write new hed to file
      echo "$last_origin_sha" > $head_file
      # Add head file to current commit (add + squash)
      git add $head_file
      git commit -m "fix(last-head): updated" --no-verify
      git reset HEAD~1 --soft
      git commit --amend --no-edit
    else
      echo ">>> Same last origin. Skip saving to HEAD file.'"
    fi
}
save_remote_head_pre_push

##############
# VERSIONING #
##############
get_changes () {
  # list of "packages" contained in the git diff between last commit and last saved origin.
  CHANGES=$(git diff $last_commit_sha $last_origin_sha | grep "\-\-\- " | grep -oE "a\/packages\/[^/]+|a\/services\/[^/]+" | sort -u)
  echo ">>> CHANGED PACKAGES:" $CHANGES
}
get_changes

get_semver_bump () {
  echo ">>> identifying semver package bump"
  git log "${last_commit_sha}..${last_origin_sha}" --oneline
}

get_semver_bump
echo " "
echo " "
for changed_package in $CHANGES; do
  prefix="a/"
  changed_package_location=${changed_package#a/}
  name=$(node -pe "require('./${changed_package_location}/package.json').name") 
  current_version=$(node -pe "require('./${changed_package_location}/package.json').version") 
  echo $name "----->" $changed_package_location "," $current_version
done