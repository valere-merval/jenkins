# Jenkins Architektur

## Ziel

Dieses Repository ist als professionelles Jenkins-/DevOps-Plattform-Repository strukturiert. Es trennt Pipeline-Orchestrierung, Shared-Library-Code, operative Skripte, Infrastruktur-Artefakte, Konfigurationen, Datensteuerung und obsolete Artefakte sauber voneinander.

Das Refactoring ist ein Big-Bang-Refactoring im Repository: Die echten Implementierungen wurden in die neue Zielstruktur verschoben. Alte Root- und Compatibility-Symlinks wurden entfernt, damit keine doppelt wirkenden Pfade mehr sichtbar sind. Die Ziel-Pipelines unter `pipelines/v2/` sind vollständige, ausführbare Jenkinsfiles und delegieren nicht mehr pauschal an Legacy-Jobs.

## Zielstruktur

```text
jenkins/
├── vars/                         # Jenkins Shared Library Global Variables / Steps
├── src/org/jenkins/               # Groovy-Klassen, Konstanten, wiederverwendbare Logik
├── resources/org/jenkins/         # Ressourcen der Shared Library
├── pipelines/v2/deployment/       # Neue Deployment-Zielpipelines mit @Library('jenkins')
├── pipelines/v2/configuration/    # Neue Konfigurations-Zielpipelines mit @Library('jenkins')
├── pipelines/legacy/deployment/   # Migrierte Legacy-Deployment-Jenkinsfiles als Referenz/Fallback
├── pipelines/legacy/configuration/# Migrierte Legacy-Konfigurations-Jenkinsfiles als Referenz/Fallback
├── scripts/deployment/            # Reale Deployment-Shell-Skripte und Hilfsdateien
├── scripts/ops/                   # Reale Operations-Skripte aus dem ehemaligen Root
├── infrastructure/ansible/        # Reale Ansible-Struktur
├── data/pman/                     # Reale PMAN-Struktur
├── config/update-stack/           # Reale Stack-/Umgebungskonfigurationen
├── config/*.groovy                # Jenkins-Konfigurationsgeneratoren und Beispiele
├── legacy/obsolete/               # Archivierte, obsolete Artefakte
├── docs/                          # Deutsche Dokumentation
├── Jenkinsfile                    # Jenkins-Validierung des Repository-Layouts
└── Makefile                       # Lokale Validierung
```

## Schichtenmodell

### 1. Jenkins Shared Library

Die Shared Library bildet die Plattformschicht für alle V2-Pipelines.

Wichtige Dateien:

- `vars/jenkinsOps.groovy`: zentrale Pipeline-Fassade für Agent, Credentials, Arbeitsverzeichnisse und Jenkins-Helfer.
- `vars/jsDeployment.groovy`: fachliche Deployment-Helfer.
- `vars/jsAws.groovy`: AWS-Helfer.
- `vars/jsQuality.groovy`: Validierungs-Helfer.
- `src/org/jenkins/Defaults.groovy`: zentrale Konstanten.
- `resources/org/jenkins/pipeline-catalog.yml`: deklarativer Pipeline-Katalog.

### 2. V2-Zielpipelines

`pipelines/v2/` enthält für jedes aktive Legacy-Jenkinsfile ein gleichnamiges V2-Jenkinsfile. Diese V2-Dateien laden `@Library('jenkins')`, verwenden die neuen Repository-Pfade und kapseln wiederkehrende Details über `jenkinsOps`.

### 3. Migrierte Legacy-Pipelines

`pipelines/legacy/` enthält die bisherigen produktiven Jenkinsfiles als Referenz/Fallback. Sie bleiben im Repository, sind aber nicht die Zielarchitektur.

### 4. Operative Skripte

`scripts/deployment/` enthält die früheren Deployment-Skripte aus `deployment/`.

`scripts/ops/` enthält frühere Root-Skripte wie Checks, Snapshot- und Terminate-Helper.

### 5. Infrastruktur, Daten und Konfiguration

- `infrastructure/ansible/`: Ansible.
- `data/pman/`: PMAN-Konfigurationen.
- `config/update-stack/`: Stack-Konfiguration.
- `config/*.groovy`: Jenkins-Konfigurationsgeneratoren und Beispiele.

## Kanonische Pfade

Es gibt keinen aktiven Compatibility-Layer mehr. Jenkins-Jobs sollen die V2-Pfade direkt referenzieren.

Beispiele:

```text
pipelines/v2/deployment/BIBE_SWEinsatz.Jenkinsfile
pipelines/v2/deployment/TPO_SWEinsatz.Jenkinsfile
pipelines/v2/deployment/BIBE_TPO_DataDeployment.Jenkinsfile
pipelines/v2/configuration/modifyConfigurationGroovy.Jenkinsfile
scripts/deployment/BIBE_createSnapshot.sh
scripts/ops/create-snapshot.py
infrastructure/ansible/
data/pman/
config/update-stack/
```

Damit sind `deployment/`, `configuration/`, `ansible-playbook`, `pman`, `update-stack` und ehemalige Root-Skriptpfade nicht mehr Teil der aktiven Architektur.

## Betriebsfluss

V2-Jobs nach der Script-Path-Umstellung:

```text
Jenkins Job
    ↓
pipelines/v2/deployment/BIBE_SWEinsatz.Jenkinsfile
    ↓
@Library('jenkins')
    ↓
jenkinsOps.withDeploymentScripts / withSshAgent / withPman / withUpdateStack
    ↓
scripts/deployment/ oder scripts/ops/
    ↓
BIBE / TPO / PSX / AWS / Ansible / PMAN
```

## Obsolete Artefakte

Eindeutig alte Dateien liegen unter:

```text
legacy/obsolete/
```

Dort liegen nur Artefakte, die nicht aktiv benötigt werden, z. B. ehemalige `_old`-Skripte und IDE-Dateien.

## Qualitätsgates

`make validate` prüft:

- Zielverzeichnisse,
- kanonische neue Pfade,
- vollständige V2-Abdeckung aller Legacy-Jenkinsfiles,
- keine Legacy-Delegationswrapper in V2,
- dass keine Symlinks mehr im Repository liegen,
- Whitespace-Fehler im Git-Diff.

Der Root-`Jenkinsfile` führt dieselben Strukturprüfungen in Jenkins aus.

## Repository-Name

Der GitHub-Repository-Name ist `valere-merval/jenkins`.

Die Jenkins Shared Library soll unter dem Namen `jenkins` registriert werden.
