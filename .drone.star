repo = "spritsail/alpine"
archs = ["amd64", "arm64"]
versions = ["edge", "3.14", "3.15", "3.16"]
branches = ["master"]

def main(ctx):
  builds = []

  for ver in versions:
    depends_on = []
    srctpl = "drone/%s/${DRONE_BUILD_NUMBER}:%s-ARCH" % (ctx.repo.slug, ver)
    for arch in archs:
      key = "build-%s-%s" % (ver, arch)
      tmprepo = "drone/%s/${DRONE_BUILD_NUMBER}:%s-%s" % (ctx.repo.slug, ver, arch)
      builds.append(step(ver, arch, key, tmprepo))
      depends_on.append(key)

    if ctx.build.branch in branches:
      tags = []
      if ver == versions[-1]:
        tags.append("latest")
      builds.append(publish(ver, srctpl, depends_on, tags))

  return builds

def step(ver, arch, key, tmprepo):
  vertest = "grep -q '%s' /etc/alpine-release && " % ver if ver != "edge" else ""
  return {
    "kind": "pipeline",
    "name": key,
    "platform": {
      "os": "linux",
      "arch": arch,
    },
    "steps": [
      {
        "name": "build",
        "image": "spritsail/docker-build",
        "pull": "always",
        "settings": {
          "build_args": [
            "ALPINE_TAG=%s" % ver,
          ],
          "repo": tmprepo,
        },
      },
      {
        "name": "test",
        "image": "spritsail/docker-test",
        "pull": "always",
        "settings": {
          "run": vertest + "su-exec nobody apk --version",
          "repo": tmprepo,
        },
      },
      {
        "name": "publish",
        "image": "spritsail/docker-publish",
        "pull": "always",
        "settings": {
          "from": tmprepo,
          "repo": tmprepo,
          "registry": {"from_secret": "registry_url"},
          "username": {"from_secret": "registry_username"},
          "password": {"from_secret": "registry_password"},
        },
        "when": {
          "branch": branches,
          "event": ["push"],
        },
      },
    ]
  }

def publish(ver, srctpl, depends, tags=[]):
  return {
    "kind": "pipeline",
    "name": "publish-%s" % ver,
    "depends_on": depends,
    "platform": {
      "os": "linux",
    },
    "steps": [
      {
        "name": "publish",
        "image": "spritsail/docker-multiarch-publish",
        "pull": "always",
        "settings": {
          "src_template": srctpl,
          "src_registry": {"from_secret": "registry_url"},
          "src_username": {"from_secret": "registry_username"},
          "src_password": {"from_secret": "registry_password"},
          "dest_repo": repo,
          "dest_username": {"from_secret": "docker_username"},
          "dest_password": {"from_secret": "docker_password"},
          "tags": [ver] + tags,
        },
        "when": {
          "branch": branches,
          "event": ["push"],
        },
      },
    ]
  }

# vim: ft=python sw=2
