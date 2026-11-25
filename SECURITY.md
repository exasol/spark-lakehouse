# Security

If you believe you have found a new security vulnerability in this repository, please report it to us as follows.

## Reporting Security Issues

* Please do **not** report security vulnerabilities through public GitHub issues.

* Please create a draft security advisory on the GitHub page: the reporting form is under `> Security > Advisories`.
  The URL is https://github.com/exasol/spark-lakehouse/security/advisories/new.

* If you prefer to email, please send your report to `infosec@exasol.com`.

## Guidelines

* When reporting a vulnerability, please include as much information as possible, including the complete steps to
  reproduce the issue.

* Avoid sending us executables.

* Feel free to include any script you wrote and used but avoid sending us scripts that download and run binaries.

* We will prioritise reports that show how the exploits work in realistic environments.

* We prefer all communications to be in English.

* We do not offer financial rewards. We are happy to acknowledge your research publicly when possible.

## Handling Dependabot Alerts

Dependabot watches the GitHub Actions and the Docker base images of this repository, see
[`dependabot.yml`](.github/dependabot.yml). Maintainers handle its alerts and pull requests as follows:

* **Security alerts** are triaged within one week of being raised under `> Security > Dependabot`. Critical and high
  severity alerts are fixed first.
* **Fixing an alert** means merging the Dependabot pull request, or updating the affected version by hand when
  Dependabot cannot. A change to an image must increase its `IMAGE_BUILD_NUMBER` (see the [README](README.md#versioning))
  so that the fixed image is published.
* **Jars baked into the images** are not tracked by Dependabot. When an alert or advisory affects one of them, update
  the package version in the image's `Dockerfile` and increase its build number.
* **Dismissing an alert** requires a comment explaining why the vulnerability does not apply, e.g. the affected code
  is not reachable in the image.
