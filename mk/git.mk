# 1 - prefix
# 2 - git repo
define git_hash

$1.hash: $1.hash_FORCE
	@echo HASH $2
	@ HASH="nomnomnom";						\
	if [ -e $$@ ]; then						\
		HASH=`cat $$@ | sha256sum -`;				\
	fi;								\
	GITSTATE=`git -C $2 describe --match="" --always --dirty`;	\
	GITHASH=`echo $$$$GITSTATE | sha256sum -`;			\
	if [ "$$$$GITHASH" != "$$$$HASH" ]; then			\
		echo $$$$GITSTATE > $$@;				\
	fi

$1.hash_FORCE: ;

endef

.PHONY:git-sync
git-sync:
	git pull --recurse-submodules
