import requests, os, sys

def git(command):
  return os.system(f"git {command}")


release = requests.get("https://api.github.com/repos/protonmail/proton-bridge/releases/latest").json()
version = release['tag_name']
deb = [asset for asset in release ['assets'] if asset['name'].endswith('.deb')][0]['browser_download_url']

print(f"Latest release is: {version}")

with open("VERSION", 'w') as f:
  f.write(version)

with open("deb/PACKAGE", 'w') as f:
  f.write(deb)

git("config --local user.name 'GitHub Actions'")
git("config --local user.email 'actions@github.com'")

git("add -A")

if git("diff --cached --quiet") == 0: # Returns 0 if there are no changes
  print("Version didn't change")
  exit(0)

git(f"commit -m 'Bump version to {version}'")
is_pull_request = sys.argv[1] == "true"

if is_pull_request:
  print("This is a pull request, skipping push step.")
  exit(0)

if git("push") != 0:
  print("Git push failed!")
  exit(1)
