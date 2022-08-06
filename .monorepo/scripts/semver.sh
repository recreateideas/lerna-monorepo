  
head_file=$(node -pe "require('./.monorepo/config.json')['head-file']")
last_commit_sha=$(git log | grep commit -m 1 | awk '{ print $2 }');
echo LAST $last_commit_sha
branch_name="$(git symbolic-ref HEAD 2>/dev/null)"
branch_name=${branch_name##refs/heads/}
last_head_sha=`cat $head_file`
echo ORIGIN $last_head_sha


# list unique packages names that contain changes between current commit and origin
  changes=$(git diff $last_commit_sha $last_head_sha | grep "+++" | grep -oE "b\/packages\/[^/]+" | sort -u)

echo $changes