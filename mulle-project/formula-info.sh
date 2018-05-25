# -- Formula Info --
# If you don't have this file, there will be no homebrew
# formula operations.
#
PROJECT="mulle-fetch"      # your project/repository name
DESC="🏃🏿 Download and unpack source repositories or archives"
LANGUAGE="bash"                # c,cpp, objc, bash ...
# NAME="${PROJECT}"        # formula filename without .rb extension

DEPENDENCIES='${BOOTSTRAP_TAP}mulle-bashfunctions'

# more convenient to have this ad dependencies I think
DEBIAN_DEPENDENCIES="mulle-bashfunctions (>= 1.5.0), curl, git, tar, unzip"
