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
preid=$(git rev-parse --abbrev-ref HEAD | sed 's/\//-/g' | sed 's/[^0-9a-zA-Z\-]//g' | tr '[:upper:]' '[:lower:]')
changed=$(npx lerna changed --json)
val=$(node scripts/find_preid.js $preid "${changed}" "$(git tag --sort=committerdate)")
echo $val
# publish packages in prerelease for feature branches, develop, stage, release
# npx lerna publish --conventional-prerelease --preid $preid