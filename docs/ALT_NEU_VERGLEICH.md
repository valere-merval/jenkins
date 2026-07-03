# Vergleich: Alte Architektur vs. Neue Big-Bang-Architektur

## Kurzfassung

Die alte Architektur war ein historisch gewachsenes Skript-Repository. Die neue Architektur ist ein strukturiertes Jenkins-/DevOps-Plattform-Repository mit klaren Verantwortlichkeiten, vollständigen V2-Zielpipelines und ohne doppelte Compatibility-Pfade.

## Vergleichstabelle

| Bereich | Alte Architektur | Neue Big-Bang-Architektur |
|---|---|---|
| Repository-Name | `jenkins_self` | `jenkins` |
| Jenkinsfiles | Direkt in `deployment/` und `configuration/` | Vollständige V2-Zielpipelines in `pipelines/v2/`, Legacy-Referenz in `pipelines/legacy/` |
| Neue Pipelines | Nicht vorhanden | `pipelines/v2/deployment/` und `pipelines/v2/configuration/` |
| Shared Library | Nicht vorhanden | `vars/`, `src/org/jenkins/`, `resources/org/jenkins/` |
| Deployment-Skripte | Gemischt mit Jenkinsfiles in `deployment/` | Reale Skripte in `scripts/deployment/` |
| Root-Skripte | Direkt im Repository-Root | `scripts/ops/` |
| Ansible | `ansible-playbook/` im Root | `infrastructure/ansible/` |
| PMAN | `pman/` im Root | `data/pman/` |
| Stack-Konfiguration | `update-stack/` im Root | `config/update-stack/` |
| Jenkins-Konfiguration | `configuration/*.groovy` | `config/*.groovy` |
| Obsolete Dateien | Zwischen aktiven Dateien | `legacy/obsolete/` |
| Doku | Minimal | Deutsche Architektur-, Refactoring- und Vergleichsdokumentation |
| Validierung | Nicht zentral | `make validate` und Root-`Jenkinsfile` inklusive V2-Abdeckung |
| Commit-Historie | Mehrere Refactoring-Commits | Ein einzelner reproduzierbarer Big-Bang-Commit |

## Alte Architektur

```text
jenkins_self/
├── deployment/                    # Jenkinsfiles, Shell-Skripte und alte Dateien gemischt
├── configuration/                 # Jenkinsfile und Groovy-Konfiguration gemischt
├── ansible-playbook/              # Infrastruktur-Artefakte im Root
├── pman/                          # PMAN-Daten im Root
├── update-stack/                  # Stack-Konfiguration im Root
├── *.sh / Checks / Python         # Operations-Skripte im Root
└── README.md                      # Minimale Beschreibung
```

### Hauptprobleme

1. Jenkinsfiles und Shell-Skripte waren vermischt.
2. Root-Verzeichnis war betrieblich überladen.
3. Alte und aktive Dateien lagen nebeneinander.
4. Es gab keine Jenkins Shared Library.
5. Wiederverwendbare Logik war kopiert oder hardcodiert.
6. Die Struktur war schwer auditierbar.
7. Compatibility-Symlinks hätten nach der Migration wie doppelte Ordner gewirkt.

## Neue Architektur

```text
jenkins/
├── vars/
├── src/org/jenkins/
├── resources/org/jenkins/
├── pipelines/v2/deployment/
├── pipelines/v2/configuration/
├── pipelines/legacy/deployment/
├── pipelines/legacy/configuration/
├── scripts/deployment/
├── scripts/ops/
├── infrastructure/ansible/
├── data/pman/
├── config/update-stack/
├── config/*.groovy
├── legacy/obsolete/
└── docs/
```

### Verbesserungen

1. Klare Trennung von Pipeline, Skript, Infrastruktur, Daten und Konfiguration.
2. Jenkins Shared Library für wiederverwendbare Logik.
3. Vollständige V2-Zielpipelines für alle migrierten Legacy-Jenkinsfiles.
4. Keine doppelt sichtbaren Root-/Compatibility-Pfade mehr.
5. Alte Dateien sind sauber archiviert.
6. Die Dokumentation erklärt Architektur, Migration und Reproduktion.
7. Der gesamte Umbau ist in einem Commit nachvollziehbar.

## Warum diese Architektur senior/professionell ist

Eine rein optische Verschiebung wäre riskant. Eine professionelle DevOps-Architektur braucht eindeutige Quellen der Wahrheit und einen kontrollierten Migrationspfad.

Deshalb kombiniert diese Lösung:

- echte Zielstruktur,
- vollständige V2-Pipelines mit `@Library('jenkins')`,
- Legacy-Jenkinsfiles als Referenz/Fallback,
- keine Compatibility-Symlinks im aktiven Repository,
- zentrale Shared Library,
- Validierung,
- deutsche Dokumentation,
- ein einzelner reproduzierbarer Commit.

## Beispiel: Vorher/Nachher

Vorher:

```text
deployment/BIBE_SWEinsatz.Jenkinsfile
deployment/BIBE_PE_S3Sync.sh
```

Nachher:

```text
pipelines/v2/deployment/BIBE_SWEinsatz.Jenkinsfile
scripts/deployment/BIBE_PE_S3Sync.sh
```

Referenz/Fallback:

```text
pipelines/legacy/deployment/BIBE_SWEinsatz.Jenkinsfile
```

## Ergebnis

Das Repository ist jetzt fachlich sauber strukturiert. Jenkins-Jobs sollen direkt die V2 Script Paths verwenden; dadurch gibt es keine verwirrenden doppelten Ordner oder Root-Symlinks mehr.
