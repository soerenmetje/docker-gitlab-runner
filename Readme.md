# Gitlab Runner in Docker

Run a Gitlab runner inside a Docker container. 
This is especially beneficial to set up specific runners for a single GitLab project or group.

The runner uses the Docker executor and also has privileged access to Docker on the host.
This enables the runner to be used for [building and pushing docker images](#bonus-build-and-push-docker-images-in-gitlab-cicd).

## Setup 

Create Gitlab runner config and register runner in GitLab project or group:
```shell
/bin/bash setup.sh
```

Start GitLab runner container:
```shell
docker compose up -d
```

## Know Issues

### TLS Handshake Error
You may observe *tls handshake error* in your jobs. 
To fix this, you need to set a lower MTU for docker daemon.
The exact MTU depends on your network configuration.
On my Openstack VM, 1450 worked fine.

Set mtu in `/etc/docker/daemon.json`:
```json
{
  "mtu": 1450
}
```
```shell
systemctl restart docker 
```

## Bonus: Build and Push Docker Images in GitLab CI/CD

```yaml
# .gitlab-ci.yml
stages:
  - build-img

# Hidden job - use as job template
# Needs a token. This can be generated in Gitlab-Project > Settings > Repository > Deploy tokens | At least scope write_registry is needed)
.docker-build:
  image: docker:23.0
  variables:
    DOCKER_IMG_NAME: ""    # NEEDED. Example: 'frontend'
    DOCKER_ADDITIONAL_IMG_TAG: ""  # OPTIONAL
    DOCKER_BUILD_DIR: "."  # OPTIONAL
    DOCKER_DOCKERFILE: ""  # OPTIONAL
  services:
    - docker:20.10-dind
  before_script:
    - docker info
    - echo logging in gitlab-ci-token to $CI_REGISTRY
    - docker login -u gitlab-ci-token -p $CI_BUILD_TOKEN $CI_REGISTRY # check gitlab runner config if not working
  script:
    - |
      if [ -z "$DOCKER_IMG_NAME" ]; then
        echo "CI job variable DOCKER_IMG_NAME must be set. Example: 'frontend'" >&2 # print to stderr
        exit 1
      fi
    - |
      if [ -n "$DOCKER_DOCKERFILE" ]; then
        docker build --pull -f $DOCKER_DOCKERFILE -t "${CI_REGISTRY_IMAGE}/$DOCKER_IMG_NAME:latest" "$DOCKER_BUILD_DIR"
      else
        docker build --pull -t "${CI_REGISTRY_IMAGE}/$DOCKER_IMG_NAME:latest" "$DOCKER_BUILD_DIR"
      fi
    - |
      if [ -n "$DOCKER_ADDITIONAL_IMG_TAG" ]; then
        docker tag "${CI_REGISTRY_IMAGE}/$DOCKER_IMG_NAME:latest" "${CI_REGISTRY_IMAGE}/$DOCKER_IMG_NAME:$DOCKER_ADDITIONAL_IMG_TAG"
        docker push "${CI_REGISTRY_IMAGE}/$DOCKER_IMG_NAME:$DOCKER_ADDITIONAL_IMG_TAG"
      fi
    - docker push "${CI_REGISTRY_IMAGE}/$DOCKER_IMG_NAME:latest"


build-img-webserver:
  stage: build-img
  extends: [ .docker-build ]
  variables:
    DOCKER_IMG_NAME: "webserver"
    DOCKER_ADDITIONAL_IMG_TAG: $CI_COMMIT_SHORT_SHA
    # if image needs also other modules contained in project root
    # -> build in project root and specify Dockerfile path
    DOCKER_BUILD_DIR: "webserver"
    DOCKER_DOCKERFILE: "" # Empty == use Dockerfile in build dir
  only:
    - master
```

## Sources
- https://docs.gitlab.com/runner/install/docker.html
- https://docs.gitlab.com/runner/executors/docker.html
- https://docs.gitlab.com/ee/ci/docker/using_docker_images.html
- https://docs.gitlab.com/ee/ci/jobs/
- https://hub.docker.com/r/gitlab/gitlab-runner/