# Jenkins Architektur

## Ziel

Dieses Repository enthält nur noch die pipeline-spezifischen Jenkinsfiles, Infrastruktur-Helfer und Laufzeitkonfigurationen.
Die gemeinsame Jenkins Shared Library lebt in einem separaten Repository (`valere-merval/jenkins-library`).

## Zielstruktur

```text
jenkins/
├── pipelines/v2/deployment/       # Neue Deployment-Zielpipelines mit @Library('jenkins')
├── pipelines/v2/configuration/    # Neue Konfigurations-Zielpipelines mit @Library('jenkins')
├── pipelines/legacy/deployment/   # Migrierte Legacy-Deployment-Jenkinsfiles als Referenz/Fallback
├── pipelines/legacy/configuration/# Migrierte Legacy-Konfigurations-Jenkinsfiles als Referenz/Fallback
├── infrastructure/helpers/deployment/            # Reale Deployment-Shell-Skripte und Hilfsdateien
├── infrastructure/helpers/ops/                   # Reale Operations-Skripte aus dem ehemaligen Root
├── infrastructure/helpers/python/                # Reale Python-Hilfsskripte
├── infrastructure/ansible/        # Reale Ansible-Struktur
├── config/pman/                     # Reale PMAN-Struktur
├── config/update-stack/           # Reale Stack-/Umgebungskonfigurationen
├── legacy/obsolete/               # Archivierte, obsolete Artefakte
├── docs/                          # Deutsche Dokumentation
├── Jenkinsfile                    # Jenkins-Validierung des Repository-Layouts
└── Makefile                       # Lokale Validierung
```

## Shared Library

Die Shared Library ist ausgelagert in:

- Repository: `https://github.com/valere-merval/jenkins-library.git`
- Library-Name in Jenkins: `jenkins`
- Verwendung: `@Library('jenkins') _`

## Kanonische Pfade

Beispiele im Pipelines-Repo:

```text
pipelines/v2/deployment/BIBE_SWEinsatz.Jenkinsfile
pipelines/v2/deployment/TPO_SWEinsatz.Jenkinsfile
pipelines/v2/deployment/BIBE_TPO_DataDeployment.Jenkinsfile
pipelines/v2/configuration/modifyConfigurationGroovy.Jenkinsfile
infrastructure/helpers/deployment/BIBE_createSnapshot.sh
infrastructure/helpers/python/create-snapshot.py
infrastructure/ansible/
config/pman/
config/update-stack/
```

## Betriebsfluss

```text
Jenkins Job
    ↓
pipelines/v2/deployment/BIBE_SWEinsatz.Jenkinsfile
    ↓
@Library('jenkins')
    ↓
jenkinsOps.withDeploymentScripts / withSshAgent / withPman / withUpdateStack
    ↓
infrastructure/helpers/deployment/ oder infrastructure/helpers/ops/
    ↓
BIBE / TPO / PSX / AWS / Ansible / PMAN
```

## Qualitätsgates

`make validate` prüft:

- Zielverzeichnisse,
- kanonische neue Pfade,
- vollständige V2-Abdeckung aller Legacy-Jenkinsfiles,
- keine Legacy-Delegationswrapper in V2,
- dass keine Symlinks mehr im Repository liegen,
- Whitespace-Fehler im Git-Diff.
