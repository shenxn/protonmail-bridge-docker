import requests, os, sys, subprocess

def git(command):
    return os.system(f"git {command}")

def git_output(command):
    result = subprocess.run(f"git {command}", shell=True, capture_output=True, text=True)
    return result.stdout.strip()


# Get latest upstream release
release = requests.get("https://api.github.com/repos/ProtonMail/proton-bridge/releases/latest").json()
version = release['tag_name']
print(f"Latest upstream release: {version}")

# Read current version
with open("VERSION", 'r') as f:
    current_version = f.read().strip()

if version == current_version:
    print("Already up to date.")
    exit(0)

print(f"New version detected: {current_version} -> {version}")

# Don't push anything during pull_request runs (used for testing this script itself)
is_pull_request = len(sys.argv) > 1 and sys.argv[1] == "true"
if is_pull_request:
    print("Pull request run — skipping push.")
    exit(0)

# Write new version
with open("VERSION", 'w') as f:
    f.write(version + "\n")

# Configure git identity
git("config --local user.name 'GitHub Actions'")
git("config --local user.email 'actions@github.com'")

# Create and push a branch for the version bump
branch = f"bump/{version}"
git(f"checkout -b {branch}")
git("add VERSION")
git(f'commit -m "Bump version to {version}"')

if git(f"push origin {branch}") != 0:
    print("Git push failed!")
    exit(1)

# Open a pull request via GitHub API
token = os.environ.get("GITHUB_TOKEN")
repo  = os.environ.get("GITHUB_REPOSITORY")

upstream_url = f"https://github.com/ProtonMail/proton-bridge/releases/tag/{version}"

pr_body = f"""\
Automated version bump from `{current_version}` to `{version}`.

**Before merging:**
- Check the [upstream release notes]({upstream_url}) for any new system dependencies or breaking changes.
- Confirm the test build below passes. If it fails, a new dependency likely needs to be added to the Dockerfile.

This PR was opened automatically by the update-check workflow.
"""

response = requests.post(
    f"https://api.github.com/repos/{repo}/pulls",
    json={
        "title": f"Bump version to {version}",
        "body": pr_body,
        "head": branch,
        "base": "master",
    },
    headers={
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json",
    },
)

if response.status_code == 201:
    print(f"PR opened: {response.json()['html_url']}")
else:
    print(f"Failed to create PR: {response.status_code} {response.text}")
    exit(1)
