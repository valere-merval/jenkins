# Shared Library Smoke Tests

These tests prove that the `vars/ -> src/` refactor is transparent: every
`vars/*.groovy` facade still loads and delegates to its `src/org/jenkins/pipeline/*Support`
class through `methodMissing`, with unchanged step names and signatures.

There are two ways to run them.

## 1. Locally (fastest, no Jenkins needed)

Requires the `groovy` CLI on your PATH.

```bash
# from the repo root, any of these:
./test/smoke/run.sh
# or
make smoke
```

Expected output ends with:

```
SMOKE OK: all facades load and delegate.
```

What it does: instantiates each `*Support` class with a fake CPS script,
calls its "pure" methods (parameters, data maps, config, agent label, type
mapping) and asserts the returned structures. It also parses
`vars/jenkinsOps.groovy` to confirm the facade loads.

A tiny local-only stub for the Declarative plugin's `Utils` class lives in
`test/smoke/stubs/`. It is **never** shipped to Jenkins; the real class comes
from the *Pipeline: Declarative* plugin at runtime.

## 2. On the real Jenkins (end-to-end confirmation)

The local test cannot execute real pipeline steps (`sh`, `sshagent`, ...).
For that, run the smoke Jenkinsfile on your Jenkins instance:

`test/smoke/librarySmokeTest.Jenkinsfile`

Create a **Pipeline** job pointing at this repo and this Jenkinsfile path
(or add it to your job DSL / multibranch config). It:

- loads `@Library('jenkins')`,
- calls one **non-destructive** step of each facade
  (`jenkinsOps`, `jsDataDeployment`, `jsSoftwareDeployment`,
  `jsEnvironmentControl`, `jsConfigurationGroovy`),
- asserts the results and prints `SMOKE OK` on success.

It performs **no deployment**, no SSH, and no external side effects.
```
Jenkins > New Item > Pipeline
  Definition:        Pipeline script from SCM
  SCM:               Git  ->  <this repo>
  Script Path:       test/smoke/librarySmokeTest.Jenkinsfile
```
