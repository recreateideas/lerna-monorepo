#!/usr/bin/env bash

git fetch --tags
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
echo $BASH_VERSION

get_origin_versions () {
  git checkout $saved_last_origin
  packages=$(find . -name '*package.json' -not -path "**/node_modules/*")
  for package in $packages; do
    name=$(node -pe "require('${package}').name") 
    version=$(node -pe "require('${package}').version")
    echo $name $version
    origin_versions+="${name}*${version}"
  done
  git checkout $branch_name
  echo "##############"
  echo $origin_versions
  echo "##############"
}
get_origin_versions

echo $origin_versions | tr ' ' '\n' | grep "@recreateideas/lerna-monorepo"

get_semver_bump_type () {
  echo ">>> identifying semver package bump"
  echo ">>> getting commits between last commit (${last_commit_sha}) AND last origin ($last_origin_sha)"
  COMMITS=$(git log "${last_origin_sha}..${last_commit_sha}")
  if [[ "$COMMITS" == *"BREAKING CHANGE"* ]]; then
    BUMP="major"
  elif [[ "$COMMITS" == *"feat("* ]]; then
    BUMP="minor"
  else
    BUMP="patch"
  fi
  echo " "
  echo ">>> BUMP TYPE:" $BUMP
}
get_semver_bump_type

get_changes () {
  # list of "packages" contained in the git diff between last commit and last saved origin.
  CHANGES=$(git diff $last_commit_sha $last_origin_sha | grep "\-\-\- " | grep -oE "a\/packages\/[^/]+|a\/services\/[^/]+" | sort -u)
}
get_changes
echo " "

split_version_entities () {
  regex="([0-9]+).([0-9]+).([0-9]+)-([a-z0-9A-Z]+).([0-9a-z])*"
  if [[ $1 =~ $regex ]]
    then
    major=${BASH_REMATCH[1]}
    minor=${BASH_REMATCH[2]}
    patch=${BASH_REMATCH[3]}
    preid=${BASH_REMATCH[4]}
    prever=${BASH_REMATCH[5]}
    echo $major $minor $patch ${preid} $prever
    else
        echo "$f doesn't match" >&2 # this could get noisy if there are a lot of non-matching files
    fi
}

echo "***************"
echo $branch_name
echo "***************"
# get remote branch
# if current branch === preid branch
#   -> increase prever
# if current branch < preid branch (e.b checkout new branch from develop)
#   -> update preid to current preid
#   -> 
# if remote branch > current branch


for changed_package in $CHANGES; do
  prefix="a/"
  changed_package_location=${changed_package#a/}
  name=$(node -pe "require('./${changed_package_location}/package.json').name") 
  current_version=$(node -pe "require('./${changed_package_location}/package.json').version")
  echo $name "----->" $changed_package_location, $current_version
  split_version_entities $current_version
done