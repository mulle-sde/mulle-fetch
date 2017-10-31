# -- Formula Info --
# If you don't have this file, there will be no homebrew
# formula operations.
#
PROJECT="mulle-fetch"      # your project/repository name
DESC="🏃 Retrieve project archives or repostiories in various shapes and forms"
LANGUAGE="bash"                # c,cpp, objc, bash ...
# NAME="${PROJECT}"        # formula filename without .rb extension

DEPENDENCIES='${BOOTSTRAP_TAP}mulle-bashfunctions'

DEBIAN_DEPENDENCIES="mulle-bashfunctions (>= 1.0.0), curl, git, tar, unzip"
