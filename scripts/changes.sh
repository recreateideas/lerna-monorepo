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
rm -f $file
last_2_commits=$(git log | grep commit -m 2 | awk '{ print $2 }');
echo $last_2_commits
git diff ${last_2_commits} | grep "+++" | grep packages
# git diff ${last_2_commits} | grep "+++" | while read scoped_package; do
#       package_name=${scoped_package#"$prefix"}
#       #  if this is not a common package, and common package has changes, make this trigger depend on common package trigger
#       if [[ $scoped_package != "$common_package" && $has_common_trigger_changes ]]; then  
#         needs="needs: [\"trigger:$common_package_name\"]"
#       else
#         needs=""
#       fi
#       echo "
# trigger:$package_name:
#   stage: triggers
#   trigger:
#     include: packages/$package_name/.gitlab-ci.yml
#     strategy: depend
#   variables:
#     BAAS_PACKAGE: $package_name
#   $needs
#   when: on_success
#   rules:
#     - if: '\$GITLAB_USER_LOGIN != \"engineering-sa\" && \$CI_COMMIT_MESSAGE =~ /[^chore\(release\)].*/'
#     " >> $file
#   done

#  echo " 
# ********* dynamic child pipeline content ***********
#  "
#   cat $file
#   echo " 
# ********* ------------------------------ ***********
#  "
