#!/bin/bash

# Create Gitlab runner config and register runner in GitLab project or group.

set -e # fail and abort script if one command fails
set -o pipefail

default_description="Runner Docker @ $(hostname)"
default_url="https://gitlab.com/"

# Read user input -----------------------------------------

read -r -p "Enter URL [$default_url]: " url
url=${url:-$default_url}
echo "$url"

read -r -p "Enter registration token: " token
echo "$token"

read -r -p "Enter description [$default_description]: " description
description=${description:-$default_description}
echo "$description"

read -rsn1 -p "Next step will create runner config and register runner in GitLab. Press any key to continue... "
echo

# Register runner -----------------------------------------

# docker-image is the default image if no image is specified in projects .gitlab-ci.yaml
docker run --rm -v "$PWD/config:/etc/gitlab-runner" gitlab/gitlab-runner register \
  --non-interactive \
  --url "$url" \
  --registration-token "$token" \
  --executor docker \
  --description "$description" \
  --docker-image "ubuntu:22.04" \
  --docker-privileged \
  --docker-volumes "/certs/client"
