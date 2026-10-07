# Jenkins Pipelines

Repository for the pipeline-specific Jenkinsfiles and runtime assets.

## What lives here

- `pipelines/v2/` – current Jenkinsfiles
- `pipelines/legacy/` – legacy Jenkinsfiles kept as reference/fallback
- `infrastructure/helpers/` – deployment, ops, and Python helper scripts used by the pipelines
- `infrastructure/ansible/` – Ansible content used by the pipelines
- `config/pman/` and `config/update-stack/` – runtime config and stack inputs
- `config/*.groovy` – config generators used by the pipeline flows
- `legacy/obsolete/` – archived obsolete artifacts
- `docs/` – repo documentation

## Shared library

The shared Jenkins library has moved to a separate repository:

- Repository: `https://github.com/valere-merval/jenkins-library.git`
- Library name in Jenkins: `jenkins`
- Usage in Jenkinsfiles: `@Library('jenkins') _`

## Validation

```bash
make validate
```

The validation checks the pipeline repository layout, canonical pipeline paths, and whitespace in the git diff.
