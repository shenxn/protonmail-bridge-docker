import json, os, re, subprocess, sys, urllib.request

UPSTREAM = "ProtonMail/proton-bridge"
VERSION_RE = re.compile(r"v\d+\.\d+\.\d+")
COMMIT_RE = re.compile(r"[0-9a-f]{40}")


def api(path):
  request = urllib.request.Request(
    f"https://api.github.com/repos/{UPSTREAM}/{path}",
    headers={"Accept": "application/vnd.github+json"},
  )
  token = os.environ.get("GH_TOKEN")
  if token:
    request.add_header("Authorization", f"Bearer {token}")
  with urllib.request.urlopen(request, timeout=30) as response:
    return json.load(response)


def git(*args, check=True):
  return subprocess.run(["git", *args], check=check).returncode


# Everything below comes from a repository we do not control, so it is
# validated before it is written to disk or passed to any command.
release = api("releases/latest")
version = release["tag_name"]
if not VERSION_RE.fullmatch(version):
  sys.exit(f"Unexpected release tag: {version!r}")

# Tags are mutable, so the build is pinned to the commit the tag points to now.
commit = api(f"commits/{version}")["sha"]
if not COMMIT_RE.fullmatch(commit):
  sys.exit(f"Unexpected commit id: {commit!r}")

number = version[1:]
deb_prefix = f"https://github.com/{UPSTREAM}/releases/download/{version}/"
debs = [
  asset["browser_download_url"] for asset in release["assets"]
  if re.fullmatch(rf"protonmail-bridge_{re.escape(number)}-\d+_amd64\.deb", asset["name"])
]
if len(debs) != 1 or debs[0] != deb_prefix + debs[0].rsplit("/", 1)[-1]:
  sys.exit(f"Unexpected deb assets: {debs!r}")
deb = debs[0]

print(f"Latest release is: {version} ({commit})")

with open("VERSION", "w") as f:
  f.write(version)

with open("COMMIT", "w") as f:
  f.write(commit)

with open("deb/PACKAGE", "w") as f:
  f.write(deb)

git("add", "-A")

if git("diff", "--cached", "--quiet", check=False) == 0:
  print("Version didn't change")
  sys.exit(0)

if os.environ.get("DRY_RUN", "true") != "false":
  print("Dry run, not opening a pull request.")
  sys.exit(0)

branch = f"update-{version}"
if git("ls-remote", "--exit-code", "--heads", "origin", branch, check=False) == 0:
  print(f"Branch {branch} already exists, nothing to do.")
  sys.exit(0)

base = subprocess.run(
  ["git", "rev-parse", "--abbrev-ref", "HEAD"],
  check=True, capture_output=True, text=True,
).stdout.strip()
title = f"Bump version to {version}"

git("config", "--local", "user.name", "GitHub Actions")
git("config", "--local", "user.email", "actions@github.com")
git("checkout", "-b", branch)
git("commit", "-m", title)
git("push", "origin", branch)

# The bump is reviewed and merged by a person instead of being pushed to the
# default branch, because merging it publishes new images.
subprocess.run(
  [
    "gh", "pr", "create",
    "--base", base,
    "--head", branch,
    "--title", title,
    "--body", f"Upstream released {version} at commit {commit}.\n\nMerging this publishes new images.",
  ],
  check=True,
)
