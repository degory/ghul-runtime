# CI/CD pipeline

This is a very simple CI/CD pipeline implemented as a GitHub workflow comprised of GitHub Actions

It is triggered on:
- creation of pull requests
- new commits to existing pull request branches
- successful merge of pull requests into the main branch

Every pipeline run executes the following jobs:
- Create a version number
- Build the .NET executable artifact from the application source code
- Execute 'tests'[^note] under .NET 5.0
- Create a draft release (if we're building the main branch after a successful PR merge)

[^note]: the 'tests' in this example simply run the built .NET application 


