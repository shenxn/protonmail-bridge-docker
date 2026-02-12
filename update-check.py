import requests, os, sys

def git(command):
  return os.system(f"git {command}")

release = requests.get("https://api.github.com/repos/protonmail/proton-bridge/releases/latest").json()
version = release['tag_name']

print(f"Latest release is: {version}")

with open("VERSION", 'w') as f:
  f.write(version)

git("config --local user.name 'GitHub Actions'")
git("config --local user.email 'actions@github.com'")

git("add -A")

if git("diff --cached --quiet") == 0:
  print("Version didn't change")
  exit(0)

git(f"commit -m 'Bump version to {version}'")

if git("push") != 0:
  print("Git push failed!")
  exit(1)
