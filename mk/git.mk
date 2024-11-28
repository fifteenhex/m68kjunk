# 1 - prefix
# 2 - git repo
define git_hash
.PHONY: $1.hash
$1.hash:
	HASH="nomnomnom";						\
	if [ -e $$@ ]; then						\
		HASH=`cat $$@ | sha256sum -`;				\
	fi;								\
	GITSTATE=`git -C $2 describe --match="" --always --dirty`;	\
	GITHASH=`echo $$$$GITSTATE | sha256sum -`;			\
	if [ "$$$$GITHASH" != "$$$$HASH" ]; then			\
		echo $$$$GITSTATE > $$@;				\
	fi
endef
