# npm config set user 0 # https://timjrobinson.com/fixing-node-gyp-permission-denied-when-running-as-root/
# npm config set unsafe-perm true

# git fetch --prune --tags
# git remote -v

# source build/bash/create-child-triggers.sh

# if [[ "${ENVIRONMENT}" != "prod" ]]; then
#     branch="${CI_COMMIT_REF_NAME}"
#     create_triggers generated-triggers.yml
#     # normalize id names from branch names: feat/BAAS-123 -> feat-baas-123
#     preid=$(git rev-parse --abbrev-ref HEAD | sed 's/\//-/g' | sed 's/[^0-9a-zA-Z\-]//g' | tr '[:upper:]' '[:lower:]')
#     # publish packages in prerelease for feature branches, develop, stage, release
#     npx lerna publish --conventional-prerelease --preid $preid --pre-dist-tag $CI_COMMIT_BRANCH --yes
# else
#     # npx lerna version --conventional-graduate --yes
#     # publish stable versions for prod
#     npx lerna publish --conventional-graduate --yes
# fi
file=~/Desktop/text

last_commit_sha=$(git log | grep commit -m 1 | awk '{ print $2 }');
echo LAST $last_commit_sha
branch_name="$(git symbolic-ref HEAD 2>/dev/null)"
branch_name=${branch_name##refs/heads/}

last_origin_sha=$(git show origin/"$branch_name" | grep commit -m 1 | awk '{ print $2 }')
echo ORIGIN $last_origin_sha

prefix="b/"
git diff $last_commit_sha $last_origin_sha | grep "+++" | grep -oE "b\/packages\/[^/]+" | sort -u | while read scoped_package; do
  package_location=${scoped_package#"$prefix"}
  name=$(node -pe "require('./${package_location}/package.json').name") 
  current_version=$(node -pe "require('./${package_location}/package.json').version") 
  echo $name "----->" $current_version
done
