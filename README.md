# Jenkins

Professionelles Jenkins-/DevOps-Plattform-Repository für BIBE/TPO-Daten- und Software-Deployments, PSX-Umgebungssteuerung, Jenkins-/AWS-Wartung und operative Betriebsautomatisierung.

## Architektur in einem Satz

Die Implementierung ist vollständig in fachliche Zielbereiche verschoben. Alte Root- und Compatibility-Symlinks wurden entfernt; die produktiven Ziel-Pipelines liegen jetzt als echte Shared-Library-basierte V2-Jenkinsfiles vor.

## Zielstruktur

```text
├── vars/                         # Jenkins Shared Library Steps
├── src/org/jenkins/               # Groovy-Klassen, Konstanten und wiederverwendbare Logik
├── resources/org/jenkins/         # Shared-Library-Ressourcen, z. B. Pipeline-Katalog
├── pipelines/v2/                  # Neue, ausführbare Ziel-Pipelines mit @Library('jenkins')
├── pipelines/legacy/              # Migrierte Legacy-Jenkinsfiles als Referenz/Fallback
├── scripts/deployment/            # Migrierte Deployment-Shell-Skripte und Hilfsdateien
├── scripts/ops/                   # Ehemalige Root-Operations-Skripte
├── infrastructure/ansible/        # Ansible-Playbooks, Inventories, Rollen und Templates
├── data/pman/                     # PMAN-Konfigurationen und Runner
├── config/update-stack/           # Stack-/Umgebungskonfigurationen
├── config/*.groovy                # Jenkins-Konfigurationsgeneratoren/-Beispiele
├── legacy/obsolete/               # Eindeutig obsolete/alte Artefakte
└── docs/                          # Deutsche Architektur- und Refactoring-Dokumentation
```

## Wichtige Script Paths

Jenkins-Jobs sollen auf die neuen V2-Pfade umgestellt werden, z. B.:

```text
pipelines/v2/deployment/BIBE_SWEinsatz.Jenkinsfile
pipelines/v2/deployment/TPO_SWEinsatz.Jenkinsfile
pipelines/v2/deployment/BIBE_TPO_DataDeployment.Jenkinsfile
pipelines/v2/configuration/modifyConfigurationGroovy.Jenkinsfile
```

Die Legacy-Pfade unter `pipelines/legacy/` bleiben als Referenz/Fallback im Repository, sind aber nicht mehr die Zielarchitektur.

## Jenkins Shared Library

Empfohlene Jenkins-Konfiguration:

- **Name**: `jenkins`
- **Default version**: `main`
- **Repository**: `https://github.com/valere-merval/jenkins.git`

Verwendung:

```groovy
@Library('jenkins') _
```

Zentrale Fassade:

```groovy
jenkinsOps.defaultAgentLabel()
jenkinsOps.withDeploymentScripts { ... }
jenkinsOps.withSshAgent { ... }
jenkinsOps.withPman { ... }
jenkinsOps.withUpdateStack { ... }
```

## Dokumentation

- [Architektur](docs/ARCHITECTURE.md)
- [Refactoring](docs/REFACTORING.md)
- [Vergleich alt vs. neu](docs/ALT_NEU_VERGLEICH.md)

## Validierung

```bash
make validate
```

Die Validierung prüft:

- Zielstruktur,
- kanonische V2- und Legacy-Pfade,
- vollständige V2-Abdeckung für alle Legacy-Jenkinsfiles,
- dass V2 keine Legacy-Delegationswrapper mehr enthält,
- dass keine Symlinks mehr im Repository liegen,
- Whitespace-Probleme im Git-Diff.

## Commit-Strategie

Die komplette Restrukturierung ist bewusst in einem einzigen Commit zusammengefasst, damit sie manuell nachvollzogen oder reproduziert werden kann.
