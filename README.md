## Guide to publish custom versions from Argo Workflows

This guide will help you to publish a custom version of Argo Workflows with optimal dependencies. 
This guide will cater specific to the [devtron-labs](https://github.com/devtron-labs/devtron.git) project use case.


### Prerequisites
- [Git](https://git-scm.com/)
- [golang](https://golang.org/) version 1.21 or higher
- [bash](https://www.gnu.org/software/bash/) shell

### Steps

- Clone the Argo Workflows repository
```bash
git clone https://github.com/devtron-labs/argo-workflows.git
cd argo-workflows
```
- Add remote to the official Argo Workflows repository
```bash
git remote add upstream https://github.com/argoproj/argo-workflows.git
git remote update
```

- Export the version of Argo Workflows you want to publish
```bash
export Tag=v3.5.10
export TagHash=$(git ls-remote upstream $Tag | cut -f1)
```

- Validate the version and commit hash
```bash
echo $Tag
echo $TagHash
```
- Create a new branch for the custom version
```bash
git checkout -b release-$Tag $TagHash
```
- Get the prerequisites for the custom version from **main** branch and commit them
```bash
git checkout main ./go.mod ./go.sum ./Makefile ./.gitignore ./.gitattributes ./README.md
git commit -am "initial commit"
```

- Setup commit changes for the custom version by **make** command
```bash
make tag=$Tag
```
- Commit and push the changes to the custom version branch
```bash
git commit -am "release: $Tag"
git push --set-upstream origin release-$Tag
```
- Finally, create a git tag for the custom version
```bash
make git-tagging
```
- Now, create a new [release](https://github.com/devtron-labs/argo-workflows/releases/new) in the GitHub repository with the selected version tag

- All set! You have successfully published a custom version of Argo Workflows