#!/usr/bin/env bash

# This script defines the release version for the build

# The script extracts the version from the package.json file, with a unique build number
# The unique build number will be an increment from the latest git tag.
# For example, if the package.json file has version set to "0.1.0", and the latest git tag
# was "v0.1.15", then the app's releaseVersion will be set to "0.1.16"
# If this build is for a feature branch, then the branch name will be appended as a pre-release, such as "0.1.16-branchName"
# This creates a semver-compatible version number for each build produced by the pipeline.

set -exo pipefail

# shellcheck disable=SC2039
# shellcheck disable=SC1091
readonly branch_name="$1"

### Get the latest version tag and use semver standard to increment the patch version by 1.
### When you want to increment your Major or Minor version of the app, update the package.json file.

# Get Major/Minor version from the package.json file
packageVersion=$(node -pe "require('./services/${BAAS_PACKAGE}/package.json').version" | sed 's/\.0$//')

echo -e "\nPackage version from package.json is '$packageVersion'\n" 1>&2

versionPatch=

# Get highest tag number matching the packageVersion major and minor versions, and extract the patch number from that tag
set +e  # The next command will return an error if there aren't any tags that match this major.minor version
latestTag=$(git describe --abbrev=0 --tags --match "v${packageVersion}*" 2>/dev/null)
set -e

echo -e "\nLatest tag for $packageVersion is $latestTag.\n" 1>&2

if [ -z "$latestTag" ]; then
    versionPatch="0"
else
    # Get the patch number from the latest tag for this major.minor version
    # shellcheck disable=SC2206
    tagVersionSegments=(${latestTag//./ })
    # shellcheck disable=SC2206
    versionPatch=${tagVersionSegments[2]}
    # Increase the patch number by 1
    versionPatch=$((versionPatch+1))
fi

echo -e "\nVersion patch is $versionPatch.\n" 1>&2

if [[ "$branch" == 'main' ]]
    then
        readonly releaseVersion="v$packageVersion.$versionPatch"
    else
        readonly releaseVersion="v$packageVersion.$versionPatch-$branch"
fi

echo -e "\nThe release version is $releaseVersion\n" 1>&2

echo "$releaseVersion"
