#!/usr/bin/env bash
# This script is called by the build pipeline. It builds the app and runs unit tests
# There is one parameter required for this script:
#   release_version: This is the version of the build to be output to the version.js file

# The output of this build script will produce a file named "version.js" in the src directory
# The version.js file can be imported by app files to pull in the appLastUpdated (build date) and version

# Ensures script execution halts on first error
set -exo pipefail

# Build and Package
if [[ ${FEATURE_BRANCH} ]]; then 
  # https://esbuild.github.io/faq/#production-readiness
  # Use esbuild on feature branch for performance benefits
  npm run esbuild:scoped
else
  npm run build:scoped
fi



# Save the app name and release version as part of the build output
mkdir -p build/output
node -pe "require('./services/${BAAS_PACKAGE}/cdk.json').context.projectName" > build/output/app-name.txt
node -pe "require('./services/${BAAS_PACKAGE}/package.json').version" > build/output/release-version.txt
