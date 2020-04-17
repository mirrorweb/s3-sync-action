#!/bin/bash

set -e

if [ -z "$AWS_S3_BUCKET" ]; then
  echo "AWS_S3_BUCKET is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "AWS_ACCESS_KEY_ID is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS_SECRET_ACCESS_KEY is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_REGION" ]; then
  echo "AWS_REGION is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_GHA_ROLE" ]; then
  echo "AWS_GHA_ROLE is not set. Quitting."
  exit 1
fi

if [ -z "$SOURCE_DIR" ] && [ -z "$SOURCE_ARRAY" ]; then
  echo "No Sources set please set SOURCE_DIR or SOURCE_ARRAY. Quitting"
  exit 1
fi

rm -rf ~/.aws/config
# Create a dedicated profile for this action to avoid
# conflicts with other actions.
# https://github.com/jakejarvis/s3-sync-action/issues/1
aws configure --profile s3-sync-action <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

mkdir -p ~/.aws
touch ~/.aws/config
echo "[profile internal]" >> ~/.aws/config
echo "region = eu-west-1" >> ~/.aws/config
echo "output = json" >> ~/.aws/config
echo "role_arn = ${AWS_GHA_ROLE}" >> ~/.aws/config
echo "source_profile = s3-sync-action" >> ~/.aws/config

if [ -z "$SOURCE_DIR" ]; then
  echo "No Sources set please set SOURCE_DIR or SOURCE_ARRAY. Skipping"
else
  # Use our dedicated profile and suppress verbose messages.
  # All other flags are optional via `args:` directive.
  sh -c "aws s3 sync ${SOURCE_DIR} s3://${AWS_S3_BUCKET} \
                --profile internal \
                --no-progress $*"
fi

if [ -z "$SOURCE_ARRAY" ]; then
  echo "No Sources set please set SOURCE_DIR or SOURCE_ARRAY. Quitting"
else
  arr=("$SOURCE_ARRAY")
  for element in "${arr[@]}";do
    # Use our dedicated profile and suppress verbose messages.
    # All other flags are optional via `args:` directive.
    sh -c "aws s3 cp ${element} s3://${AWS_S3_BUCKET} \
                  --profile internal \
                  --no-progress $*"
  done
fi
