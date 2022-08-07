npm config set user 0 # https://timjrobinson.com/fixing-node-gyp-permission-denied-when-running-as-root/
npm config set unsafe-perm true

git fetch --prune --tags
git remote -v

# This is to create a custom ci configuration based on which package contains code changes
# The output of this file will be something like:
 
#     stages:
#       - triggers
#      
#     trigger:baas-common:
#       stage: triggers
#       trigger:
#         include: packages/baas-common/.gitlab-ci.yml
#         strategy: depend
#       variables:
#         BAAS_PACKAGE: baas-common
#       when: on_success
#       rules:
#         - if: '$GITLAB_USER_LOGIN != "engineering-sa" && $CI_COMMIT_MESSAGE =~ /[^chore\(release\)].*/'
#        
#     trigger:baas-identity:
#       stage: triggers
#       trigger:
#         include: packages/baas-identity/.gitlab-ci.yml
#         strategy: depend
#       variables:
#         BAAS_PACKAGE: baas-identity
#       needs: ["trigger:baas-common"]
#       when: on_success
#       rules:
#         - if: '$GITLAB_USER_LOGIN != "engineering-sa" && $CI_COMMIT_MESSAGE =~ /[^chore\(release\)].*/'

# This config should then be exported as artifact and run as ci yml configuration by the next stage

create_triggers() {
  rm -f $1
  echo "
stages:
  - triggers
  " >> $1
  head_file=$(node -pe "require('./.monorepo/config.json')['head-file']")
  common_package=$(node -pe "require('./.monorepo/config.json')['common-package']")
  last_commit_sha=$(git log | grep commit -m 1 | awk '{ print $2 }');
  echo LAST $last_commit_sha
  branch_name="$(git symbolic-ref HEAD 2>/dev/null)"
  branch_name=${branch_name##refs/heads/}
  last_head_sha=`cat $head_file`
  echo ORIGIN $last_head_sha

  # list unique packages names that contain changes between current commit and origin
  changes=$(git diff $last_commit_sha $last_head_sha | grep "+++" | grep -oE "b\/packages\/[^/]+" | sort -u)
  if [ -z "$changes" ]; then
    # skip
    echo "
trigger:skip:
  stage: triggers
  when: on_success
  script: echo 'skipping'" >> $1
  else
  if [[ "$changes" == *"$common_package"* ]]; then
    has_common_trigger_changes=true
  fi
    # loop through the list of packages
    git diff $last_commit_sha $last_head_sha | grep "+++" | grep -oE "b\/packages\/[^/]+" | sort -u | while read name_from_git; do
      package_name=${name_from_git#"b/packages/"}
      #  if this is not a common package, and common package has changes, make this trigger depend on common package trigger
      if [[ $package_name != "$common_package" && $has_common_trigger_changes ]]; then  
        needs="
  needs: [\"trigger:$common_package\"]"
      else
        needs=""
      fi
      # generate custom trigger job to trigger child pipeline for this package
      echo "
trigger:$package_name:
  stage: triggers
  trigger:
    include: packages/$package_name/.gitlab-ci.yml
    strategy: depend
  variables:
    BAAS_PACKAGE: $package_name $needs
  when: on_success
  rules:
    - if: '\$GITLAB_USER_LOGIN != \"engineering-sa\" && \$CI_COMMIT_MESSAGE =~ /[^chore\(release\)].*/'
    " >> $1
      done
  fi
    echo " 
********* dynamic child pipeline content ***********"
  cat $1
  echo " 
********* ------------------------------ ***********
 "
}

create_triggers generated-triggers.yml