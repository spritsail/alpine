def main(ctx):
  versions = [
    ["3.9",[]],
    ["3.10",[]],
    ["3.11", ["latest"]],
    ["edge", []],
  ]
  return [step(v[0], v[1]) for v in versions] + [notify(["build-%s" % v for v, _ in versions])]

def step(alpinever,tags=[]):
  return {
    "kind": "pipeline",
    "name": "build-%s" % alpinever,
    "steps": [
      {
        "name": "build",
        "image": "spritsail/docker-build",
        "pull": "always",
        "settings": {
          "repo": "alpine-dev-%s" % alpinever,
          "build_args": [
            "ALPINE_TAG=%s" % alpinever,
          ],
        },
      },
      {
        "name": "test",
        "image": "spritsail/docker-test",
        "pull": "always",
        "settings": {
          "repo": "spritsail/alpine",
          "run": "su-exec nobody apk --version",
        },
      },
      {
        "name": "publish",
        "image": "spritsail/docker-publish",
        "pull": "always",
        "settings": {
          "from": "alpine-dev-%s" % alpinever,
          "repo": "spritsail/alpine",
          "tags": [alpinever] + tags,
        },
        "environment": {
          "DOCKER_USERNAME": {
            "from_secret": "docker_username",
          },
          "DOCKER_PASSWORD": {
            "from_secret": "docker_password",
          },
        },
        "when": {
          "branch": ["master"],
          "event": ["push"],
        },
      },
    ]
  }

def notify(versions):
  return {
    "kind": "pipeline",
    "name": "notify",
    "depends_on": versions,
    "steps": [
      {
        "name": "notify",
        "image": "spritsail/notify",
        "environment": {
          "WEBHOOK_URL": {
            "from_secret": "webhook_url",
          },
          "NOTIFY_TOKEN": {
            "from_secret": "notify_token",
          },
        },
        "when": {
          "status": [ "success", "failure" ],
        },
      },
    ],
  }
