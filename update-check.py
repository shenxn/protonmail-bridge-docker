import sys
import os
import requests
import json
import re

is_pull_request = sys.argv[1] == "true"
print(f"is_pull_request={is_pull_request}")


def check_version(directory, new_version):
    print(f"Checking version for {directory}")

    if not new_version:
        print("Failed to get new version. Exiting.")
        exit(1)

    with open(f"{directory}/VERSION", "r") as f:
        old_version = f.read().rstrip()
    
    print(f"Up-to-date version {new_version}")
    print(f"Current version: {old_version}")

    if old_version != new_version:
        print(f"New release found: {new_version}")

        # bump up to new release
        with open(f"{directory}/VERSION", "w") as f:
            f.write(new_version)
        # commit
        result = os.system(f"git config --local user.email 'actions@github.com' \
            && git config --local user.name 'GitHub Actions' \
            && git add {directory}/VERSION \
            && git commit -m 'Bump {directory} version to {new_version}'")
        if result != 0:
            print("Failed to commit the bump. Exiting")
            exit(1)
        if is_pull_request:
            print("Action triggered by pull request. Do not push.")
        else:
            result = os.system("git push")
            if result != 0:
                print("Failed to push. Exiting")
                exit(1)
    else:
        print(f"Already newest version {old_version}")


# check deb version
response = requests.get("https://protonmail.com/download/current_version_linux.json")
content = json.loads(response.content)
version = re.match(".*_([0-9.-]+)_amd64\.deb", content["DebFile"]).group(1)
check_version("deb", version)


# check build version
response = requests.get(
    "https://api.github.com/repos/ProtonMail/proton-bridge/tags",
    headers={"Accept": "application/vnd.github.v3+json"},
    )
tags = json.loads(response.content)
version_re = re.compile("v\d+\.\d+\.\d+")
releases = [tag["name"][1:] for tag in tags if version_re.match(tag["name"])]
check_version("build", releases[0])
