SCRIPTS=install.sh \
src/mulle-fetch-common-settings.sh \
src/mulle-fetch-copy.sh \
src/mulle-fetch-fetch.sh \
src/mulle-fetch-git.sh \
src/mulle-fetch-logging.sh \
src/mulle-fetch-mv-force.sh \
src/mulle-fetch-paths.sh \
src/mulle-fetch-scm.sh \
src/mulle-fetch-scripts.sh \
src/mulle-fetch-settings.sh \
src/mulle-fetch-shared.sh \
src/mulle-fetch-source.sh \
src/mulle-fetch-tag.sh \
src/mulle-fetch-warn-scripts.sh \
src/plugins/git.sh \
src/plugins/svn.sh \
src/plugins/symlink.sh \
src/plugins/tar.sh \
src/plugins/zip.sh

CHECKSTAMPS=$(SCRIPTS:.sh=.chk)

#
# catch some more glaring problems, the rest is done with sublime
#
SHELLFLAGS=-x -e SC2016,SC2034,SC2086,SC2164,SC2166,SC2006,SC1091,SC2039,SC2181,SC2059,SC2196,SC2197 -s sh

.PHONY: all
.PHONY: clean
.PHONY: shellcheck_check

%.chk:	%.sh
	- shellcheck $(SHELLFLAGS) $<
	(shellcheck -f json $(SHELLFLAGS) $< | jq '.[].level' | grep -w error > /dev/null ) && exit 1 || touch $@

all:	$(CHECKSTAMPS) mulle-fetch.chk shellcheck_check jq_check

mulle-fetch.chk:	mulle-fetch
	- shellcheck $(SHELLFLAGS) $<
	(shellcheck -f json $(SHELLFLAGS) $< | jq '.[].level' | grep -w error > /dev/null ) && exit 1 || touch $@

install:
	@ ./install.sh

clean:
	@- rm src/*.chk
	@- rm src/plugins/*.chk

shellcheck_check:
	which shellcheck || brew install shellcheck

jq_check:
	which shellcheck || brew install shellcheck
