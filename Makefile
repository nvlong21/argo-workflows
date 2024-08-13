export SHELL:=bash
export SHELLOPTS:=$(if $(SHELLOPTS),$(SHELLOPTS):)pipefail:errexit

# https://stackoverflow.com/questions/4122831/disable-make-builtin-rules-and-variables-from-inside-the-make-file
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

# -- build metadata
BUILD_DATE            := $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
# below 3 are copied verbatim to release.yaml
GIT_COMMIT            := $(shell git rev-parse HEAD || echo unknown)
GIT_UPSTREAM_TAG      := v3.5.10
TAG_COMMIT_HASH       :=$(shell git ls-remote upstream $(GIT_UPSTREAM_TAG) | cut -f1)
GIT_TAG               := $(shell git describe --exact-match --tags --abbrev=0  2> /dev/null || echo untagged)
GIT_REMOTE            := origin
GIT_BRANCH            := $(shell git rev-parse --symbolic-full-name --verify --quiet --abbrev-ref HEAD)
RELEASE_TAG           := $(shell if [[ "$(GIT_TAG)" =~ ^v[0-9]+\.[0-9]+\.[0-9]+.*$$ ]]; then echo "true"; else echo "false"; fi)
DEV_BRANCH            := $(shell [ "$(GIT_BRANCH)" = main ] || [ `echo $(GIT_BRANCH) | cut -c -8` = release- ] || [ `echo $(GIT_BRANCH) | cut -c -4` = dev- ] || [ $(RELEASE_TAG) = true ] && echo false || echo true)
SRC                   := $(GOPATH)/src/github.com/argoproj/argo-workflows
VERSION               := latest
# VERSION is the version to be used for files in manifests and should always be latest unless we are releasing
# we assume HEAD means you are on a tag
ifeq ($(RELEASE_TAG),true)
VERSION               := $(GIT_TAG)
endif

$(info GIT_COMMIT=$(GIT_COMMIT))
$(info GIT_BRANCH=$(GIT_BRANCH))
$(info RELEASE_TAG=$(RELEASE_TAG))
$(info DEV_BRANCH=$(DEV_BRANCH))
$(info VERSION=$(VERSION))
$(info GIT_TAG=$(GIT_TAG))
$(info TAG_COMMIT_HASH=$(TAG_COMMIT_HASH))

override LDFLAGS += \
  -X github.com/argoproj/argo-workflows/v3.version=$(VERSION) \
  -X github.com/argoproj/argo-workflows/v3.buildDate=$(BUILD_DATE) \
  -X github.com/argoproj/argo-workflows/v3.gitCommit=$(GIT_COMMIT)

ifneq ($(GIT_TAG),)
override LDFLAGS += -X github.com/argoproj/argo-workflows/v3.gitTag=${GIT_TAG}
endif

ifndef $(GOPATH)
	GOPATH=$(shell go env GOPATH)
	export GOPATH
endif

.PHONY: run
run: git-remote git-merge pre-commit clean-up

git-remote:
	@echo "-------- Adding git remote upstream --------"
	git config remote.upstream.url >&- || git remote add upstream https://github.com/argoproj/argo-workflows.git
	git remote update

git-merge:
	@echo "-------- Merging git tag from upstream --------"
	git config merge.ours.driver true
	git merge -X ours -X ignore-all-space $(TAG_COMMIT_HASH)
	git status --porcelain | awk '{if ($1=="DU") print $2}' | xargs git rm
	git rm -r --cached -f .
	git add .
	git checkout $(GIT_BRANCH) ./workflow/util/util.go

pre-commit:
	@echo "-------- Running pre-commit checks --------"
	go mod tidy
	go mod vendor

clean-up:
	git clean -dfX

