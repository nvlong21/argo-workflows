export SHELL:=bash
export SHELLOPTS:=$(if $(SHELLOPTS),$(SHELLOPTS):)pipefail:errexit

# https://stackoverflow.com/questions/4122831/disable-make-builtin-rules-and-variables-from-inside-the-make-file
MAKEFLAGS += --no-builtin-rules

.SUFFIXES:

# -- build metadata
BUILD_DATE            := $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
# below 3 are copied verbatim to release.yaml
GIT_COMMIT            := $(shell git rev-parse HEAD || echo unknown)
GIT_REMOTE            := origin
GIT_BRANCH            := $(shell git rev-parse --symbolic-full-name --verify --quiet --abbrev-ref HEAD)
DEV_BRANCH            := $(shell [ "$(GIT_BRANCH)" = main ] || [ `echo $(GIT_BRANCH) | cut -c -8` = release- ] || [ `echo $(GIT_BRANCH) | cut -c -4` = dev- ] || [ $(RELEASE_TAG) = true ] && echo false || echo true)

$(info GIT_COMMIT=$(GIT_COMMIT))
$(info GIT_BRANCH=$(GIT_BRANCH))
$(info DEV_BRANCH=$(DEV_BRANCH))

override LDFLAGS += \
  -X github.com/argoproj/argo-workflows/v3.buildDate=$(BUILD_DATE) \
  -X github.com/argoproj/argo-workflows/v3.gitCommit=$(GIT_COMMIT)


ifndef $(GOPATH)
	GOPATH=$(shell go env GOPATH)
	export GOPATH
endif

SRC := $(GOPATH)/src/github.com/argoproj/argo-workflows

.PHONY: run
run: git-remote update-git-tag git-merge remove-deleted-files git-dir-up clean-up pre-commit

git-remote:
	@echo "--------------------- Adding git remote upstream ------------------------"
	git config remote.upstream.url >&- || git remote add upstream https://github.com/argoproj/argo-workflows.git
	git remote update

update-git-tag:
ifeq ($(tag),)
override tag = v3.5.10
endif
ifneq ($(tag),)
override TAG_COMMIT_HASH = $(shell git ls-remote upstream $(tag) | cut -f1)
endif
	@echo "TAG: $(tag)"
	@echo "TAG_COMMIT_HASH: $(TAG_COMMIT_HASH)"

git-merge:
	@echo "--------------------- Merging git tag from upstream ---------------------"
	git config merge.ours.driver true
	git merge -X ignore-all-space $(TAG_COMMIT_HASH) || echo "Merge failed with conflicts ⚠️. Resolve conflicts and commit."

remove-deleted-files:
	@echo "--------------------- Removing deleted files -------------------------"
	git status --porcelain | awk '{if ($$1=="DU") print $$2}' | xargs git rm > /dev/null

git-dir-up:
	@echo "--------------------- Removing .gitignore files -------------------------"
	git checkout feat-dependency-optimisation ./workflow/util/util.go
	git rm -r --cached -f . > /dev/null
	git add .

pre-commit:
	@echo "--------------------- Running pre-commit checks -------------------------"
	go mod tidy
	go mod vendor

clean-up:
	git clean -dfX

