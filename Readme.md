# Gitlab Runner in Docker

Run a Gitlab runner inside a Docker container. 
This is especially beneficial to set up specific runners for a single GitLab project or group.

The runner uses the Docker executor and also has privileged access to Docker on the host.
This enables the runner to build and push docker images.

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
To fix this, you need to set a lower MTU for docker daemon:
The exact MTU depends on your network configuration.
In my Openstack VM, 1450 works for me.
```shell
nano /etc/docker/daemon.json
```
Content:
```json
{
  "mtu": 1450
}
```
```shell
systemctl restart docker 
```

## Sources
- https://docs.gitlab.com/runner/install/docker.html
- https://docs.gitlab.com/runner/executors/docker.html
- https://docs.gitlab.com/ee/ci/docker/using_docker_images.html
- https://hub.docker.com/r/gitlab/gitlab-runner/