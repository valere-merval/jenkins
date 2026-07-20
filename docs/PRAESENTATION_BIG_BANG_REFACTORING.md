# Big-Bang-Refactoring des Jenkins-/DevOps-Repositories

## Präsentationsdokumentation für DevOps-Kollegen

**Projekt:** Jenkins Plattform-Repository für BIBE/TPO, PSX-Umgebungen, Daten- und Software-Deployments  
**Repository-Zielname:** `jenkins`  
**Zielgruppe:** DevOps Engineers, Jenkins Maintainer, Plattform-/Betriebsteam  
**Sprache:** Deutsch  
**Ziel der Präsentation:** Architektur, technische Entscheidungen, Risiken, Validierung und Rollout des Refactorings nachvollziehbar erklären.

---

## 1. Executive Summary

Das bisherige Jenkins-Repository war historisch gewachsen: Jenkinsfiles, Shell-Skripte, PMAN, Ansible, Stack-Konfigurationen, Root-Operations-Skripte und obsolete Dateien lagen teilweise vermischt oder direkt im Repository-Root. Dadurch war schwer erkennbar, welche Dateien aktiv sind, welche nur historische Referenz sind und welche Pfade Jenkins produktiv verwenden soll.

Das Big-Bang-Refactoring hat das Repository in eine professionelle DevOps-Plattformstruktur überführt:

- klare Trennung von Pipelines, Shared Library, Scripts, Infrastruktur, Daten und Konfiguration,
- vollständige V2-Jenkinsfiles für alle Legacy-Pipelines,
- zentrale Jenkins Shared Library unter `vars/`, `src/` und `resources/`,
- Legacy-Jenkinsfiles bleiben als Referenz/Fallback erhalten,
- keine Compatibility-Symlinks mehr im aktiven Repository,
- zentrale Validierung über `make validate` und Root-`Jenkinsfile`,
- deutsche Architektur-, Refactoring- und Vergleichsdokumentation.

Die Kernidee: Jenkinsfiles sollen nicht mehr der Ort für wiederholte technische Details und kopierte Hilfsfunktionen sein. Sie sollen orchestrieren. Wiederverwendbare Logik gehört in die Shared Library.

---

## 2. Ausgangslage vor dem Refactoring

Die alte Struktur war funktional, aber nicht mehr gut skalierbar:

```text
jenkins_self/
├── deployment/                    # Jenkinsfiles, Shell-Skripte und alte Dateien gemischt
├── configuration/                 # Jenkinsfile und Groovy-Konfiguration gemischt
├── ansible-playbook/              # Infrastruktur-Artefakte im Root
├── pman/                          # PMAN-Daten im Root
├── update-stack/                  # Stack-Konfiguration im Root
├── *.sh / Checks / Python         # Operations-Skripte im Root
└── README.md                      # minimale Beschreibung
```

### Zentrale Probleme

1. **Vermischte Verantwortlichkeiten**  
   Jenkinsfiles, Deployment-Skripte, Konfigurationen, Ansible, PMAN und Ops-Skripte lagen teilweise im gleichen Bereich.

2. **Hohe kognitive Last**  
   Ein neuer Maintainer musste erst herausfinden, welche Datei aktiv, alt, experimentell oder produktiv ist.

3. **Wiederholte Jenkins-Logik**  
   Agent-Labels, SSH-Agent-Blöcke, Arbeitsverzeichnisse, PMAN-Aufrufe, Config-Parsing und Conditional-Stages waren in mehreren Jenkinsfiles verteilt.

4. **Unklare Zielpfade**  
   Historische Pfade und neue Zielpfade hätten parallel schnell zu doppelten Wahrheiten geführt.

5. **Schwache Auditierbarkeit**  
   Ohne klare Schichten und Validierung ist schwer beweisbar, dass alle Legacy-Pipelines abgedeckt sind.

6. **Wenig zentrale Qualitätssicherung**  
   Es gab keine ausreichend starke Repository-weite Validierung für Layout, Pfadkonventionen und V2-Abdeckung.

---

## 3. Zielbild der neuen Architektur

Die neue Struktur trennt bewusst nach fachlichen Verantwortlichkeiten:

```text
jenkins/
├── vars/                          # Jenkins Shared Library Global Variables / Steps
├── src/org/jenkins/                # Groovy-Klassen, Konstanten, wiederverwendbare Logik
├── resources/org/jenkins/          # Ressourcen der Shared Library
├── pipelines/v2/deployment/        # neue ausführbare Deployment-Zielpipelines
├── pipelines/v2/configuration/     # neue ausführbare Konfigurations-Zielpipelines
├── pipelines/legacy/deployment/    # Legacy-Jenkinsfiles als Referenz/Fallback
├── pipelines/legacy/configuration/ # Legacy-Konfigurationspipelines als Referenz/Fallback
├── scripts/deployment/             # reale Deployment-Shell-Skripte
├── scripts/ops/                    # frühere Root-Operations-Skripte
├── infrastructure/ansible/         # Ansible-Playbooks, Inventories, Rollen, Templates
├── data/pman/                      # PMAN-Konfigurationen und Runner
├── config/update-stack/            # Stack-/Umgebungskonfigurationen
├── config/*.groovy                 # Jenkins-Konfigurationsgeneratoren und Beispiele
├── legacy/obsolete/                # eindeutig obsolete Artefakte
├── docs/                           # deutsche Dokumentation
├── Jenkinsfile                     # Jenkins-Validierung des Repository-Layouts
└── Makefile                        # lokale Validierung
```

### Leitprinzipien

- **Ein aktiver Zielpfad pro Artefakt.**
- **Jenkinsfiles orchestrieren, Shared Library kapselt wiederverwendbare Logik.**
- **Legacy bleibt sichtbar, aber nicht aktiv.**
- **Keine Compatibility-Symlinks im produktiven Repository.**
- **Validierung ist Teil der Architektur, nicht nur ein nachgelagerter Test.**

---

## 4. Warum ein Big-Bang-Refactoring?

Ein inkrementelles Refactoring wirkt auf den ersten Blick risikoärmer. In diesem Fall hätte es aber neue Risiken erzeugt:

- alte und neue Pfade wären lange parallel aktiv,
- Jenkins-Jobs könnten auf unterschiedliche Pfadgenerationen zeigen,
- Compatibility-Symlinks würden im Repository wie echte Ordner aussehen,
- die Migration wäre schwerer auditierbar,
- technische Schulden blieben über mehrere Zwischenzustände sichtbar.

Deshalb wurde ein Big-Bang-Ansatz gewählt:

- alle realen Implementierungen wurden in die Zielstruktur verschoben,
- die V2-Pipelines wurden vollständig erzeugt,
- alte Pfade wurden nicht als aktive Compatibility-Schicht beibehalten,
- obsolete Dateien wurden bewusst archiviert,
- Validierung und Dokumentation wurden direkt mitgeliefert.

Der Big-Bang ist hier nicht "blindes großes Ändern", sondern ein kontrollierter Architektur-Schnitt mit reproduzierbarem Ergebnis.

---

## 5. Pipeline-Strategie: Legacy und V2

### Legacy-Pipelines

Die bisherigen Jenkinsfiles wurden nicht gelöscht. Sie liegen unter:

```text
pipelines/legacy/deployment/
pipelines/legacy/configuration/
```

Sie dienen als:

- Referenz für Verhalten,
- Fallback bei produktiven Problemen,
- Vergleichsbasis für die V2-Migration,
- Audit-Artefakt.

### V2-Pipelines

Für jedes aktive Legacy-Jenkinsfile gibt es ein gleichnamiges V2-Jenkinsfile:

```text
pipelines/v2/deployment/
pipelines/v2/configuration/
```

Aktueller Stand:

- `22` Legacy-Pipeline-Dateien,
- `22` V2-Pipeline-Dateien,
- V2 lädt die Jenkins Shared Library mit:

```groovy
@Library('jenkins') _
```

### Beispielhafte neue Jenkins Script Paths

```text
pipelines/v2/deployment/BIBE_SWEinsatz.Jenkinsfile
pipelines/v2/deployment/TPO_SWEinsatz.Jenkinsfile
pipelines/v2/deployment/BIBE_TPO_DataDeployment.Jenkinsfile
pipelines/v2/deployment/onOffEnvinroment.Jenkinsfile
pipelines/v2/configuration/modifyConfigurationGroovy.Jenkinsfile
```

---

## 6. Jenkins Shared Library

Die Shared Library ist die Plattformschicht der neuen Architektur.

Jenkins erwartet für Shared Libraries diese Root-Struktur:

```text
vars/
src/
resources/
```

### Zentrale Dateien

```text
vars/jenkinsOps.groovy
vars/jsDataDeployment.groovy
vars/jsSoftwareDeployment.groovy
vars/jsEnvironmentControl.groovy
vars/jsConfigurationGroovy.groovy
vars/jsConfigFile.groovy
vars/jsDeployment.groovy
vars/jsAws.groovy
vars/jsQuality.groovy
src/org/jenkins/Defaults.groovy
resources/org/jenkins/pipeline-catalog.yml
```

### Verantwortlichkeiten

| Datei | Verantwortung |
|---|---|
| `jenkinsOps.groovy` | zentrale Fassade für Agent, Credentials, Arbeitsverzeichnisse, Conditional-Stages, Trigger, Config-Lesen |
| `jsDataDeployment.groovy` | Parameter und PMAN-Datenstrukturen für BIBE/TPO-Dateneinsatz |
| `jsSoftwareDeployment.groovy` | BIBE/TPO-Software-Deployment-Parameter und Stage-Orchestrierung |
| `jsEnvironmentControl.groovy` | Ein-/Ausschalten von PSX-Umgebungen, AMI-Handling, Stack-Updates |
| `jsConfigurationGroovy.groovy` | Pflege von `Configuration.groovy`, Backup, Parsing, Generierung |
| `jsConfigFile.groovy` | wiederverwendbare Datei-/Config-Manipulationen |
| `jsAws.groovy` | AWS-bezogene Hilfsfunktionen |
| `jsQuality.groovy` | Validierungs- und Qualitätshelfer |
| `Defaults.groovy` | zentrale Konstanten wie Agent Label, Credential-ID, Standardpfade |

### Beispiel: vorher

In mehreren Jenkinsfiles gab es lokale Hilfsfunktionen:

```groovy
def run_with_ssh_agent(shell_code) { ... }
def stage(name, execute, block) { ... }
def isEnvironmentActive(String environment) { ... }
```

### Beispiel: nachher

```groovy
jenkinsOps.runDeploymentShell("./compare_bibe_tpo.sh D ${DESC}")
jenkinsOps.conditionalStage("BIBE ${currentKey}", condition) { ... }
jenkinsOps.isEnvironmentActive(currentKey)
```

Der Vorteil: technische Jenkins-Details sind zentral wartbar, und die Jenkinsfiles bleiben fachlich lesbarer.

---

## 7. Refactoring der Jenkinsfiles

Ein Ziel war, Jenkinsfiles deutlich kürzer und stärker orchestrierend zu machen.

Beispiele aus dem aktuellen Stand:

| Pipeline | Neuer Umfang |
|---|---:|
| `BIBE_SWEinsatz.Jenkinsfile` | ca. 156 Zeilen |
| `TPO_SWEinsatz.Jenkinsfile` | ca. 63 Zeilen |
| `BIBE_TPO_DataDeployment.Jenkinsfile` | ca. 239 Zeilen |
| `onOffEnvinroment.Jenkinsfile` | ca. 58 Zeilen |
| `modifyConfigurationGroovy.Jenkinsfile` | ca. 61 Zeilen |

Wichtig: Die Jenkinsfiles wurden nicht "leer" gemacht. Sie behalten den lesbaren Stage-Fluss. Die lange technische und fachliche Detail-Logik wurde in benannte Shared-Library-Methoden verschoben.

### Zielzustand

Jenkinsfiles sollen beantworten:

- Welche Stages gibt es?
- Welche Parameter steuern das Verhalten?
- Welche fachliche Operation wird in welcher Reihenfolge ausgeführt?

Die Shared Library soll beantworten:

- Wie wird ein Deployment-Skript mit SSH-Agent ausgeführt?
- Wie werden PMAN-Datenstrukturen aufgebaut?
- Wie wird `Configuration.groovy` gelesen, geändert und generiert?
- Wie werden Stack-Parameter gelesen und CloudFormation-Updates orchestriert?
- Wie wird ein Downstream-Job robust getriggert?

---

## 8. Neue kanonische Pfade

### Jenkinsfiles

Von:

```text
deployment/*.Jenkinsfile
configuration/modifyConfigurationGroovy.Jenkinsfile
```

Nach:

```text
pipelines/v2/deployment/
pipelines/v2/configuration/
```

### Deployment-Skripte

Von:

```text
deployment/*.sh
```

Nach:

```text
scripts/deployment/
```

### Operations-Skripte

Von Repository-Root:

```text
check_kernel
check_qualys
create-snapshot.py
terminate_psx_bibe.sh
terminate_psx_tpo.sh
```

Nach:

```text
scripts/ops/
```

### Infrastruktur und Daten

Von:

```text
ansible-playbook/
pman/
update-stack/
```

Nach:

```text
infrastructure/ansible/
data/pman/
config/update-stack/
```

---

## 9. Betriebsfluss nach dem Refactoring

```text
Jenkins Job
    ↓
pipelines/v2/deployment/BIBE_SWEinsatz.Jenkinsfile
    ↓
@Library('jenkins')
    ↓
vars/jenkinsOps.groovy / fachliche js*-Library
    ↓
scripts/deployment/ oder config/update-stack/ oder data/pman/
    ↓
BIBE / TPO / PSX / AWS / Ansible / PMAN
```

### Beispiel: Software-Deployment

```text
BIBE_SWEinsatz.Jenkinsfile
    ↓
jsSoftwareDeployment.bibeParameters(...)
    ↓
jsSoftwareDeployment.runBibe...
    ↓
jenkinsOps.runDeploymentShell(...)
    ↓
scripts/deployment/BIBE_*.sh
```

### Beispiel: Umgebung ein-/ausschalten

```text
onOffEnvinroment.Jenkinsfile
    ↓
jsEnvironmentControl.parameters(...)
    ↓
jsEnvironmentControl.prepareConfigurationFiles(...)
    ↓
jsConfigFile.setValue(...)
    ↓
config/update-stack/update-stack_new.py
    ↓
AWS CloudFormation
```

---

## 10. Validierung und Qualitätsgates

Die Validierung wurde bewusst als Teil des Repositories umgesetzt.

### Lokale Validierung

```bash
make validate
```

Prüft:

- Zielverzeichnisse,
- kanonische Pfade,
- V2- und Legacy-Abdeckung,
- keine Legacy-Delegationswrapper in V2,
- keine direkten alten SSH-/Directory-Hardcodings in V2,
- keine Symlinks,
- Whitespace-Fehler im Git-Diff.

### Jenkins-Validierung

Der Root-`Jenkinsfile` führt dieselben strukturellen Prüfungen in Jenkins aus:

- Layout-Validierung,
- kanonische Pfade,
- V2-Abdeckung,
- `@Library('jenkins')` in V2,
- keine reinen Legacy-Delegationswrapper,
- Whitespace-Check.

### Zusätzliche technische Checks

Sinnvolle Zusatzchecks:

```bash
git diff --check
find . -type l
bash -n scripts/deployment/*.sh
python3 -m py_compile scripts/ops/*.py data/pman/*.py config/update-stack/*.py
```

`find . -type l` soll keine aktiven Symlinks liefern.

---

## 11. Teststrategie in Jenkins

### 1. Shared Library korrekt registrieren

In Jenkins:

```text
Manage Jenkins → System → Global Trusted Pipeline Libraries
```

Empfohlene Konfiguration:

```text
Name: jenkins
Default version: main
Retrieval method: Modern SCM
SCM: Git
Repository: <internes Jenkins-Repository>
```

Für Branch-Tests sollte Version Override erlaubt sein.

### 2. Branch gezielt testen

Im Jenkinsfile einer Test-Branch:

```groovy
@Library('jenkins@jenkinsUmbau') _
```

Damit Jenkins nicht versehentlich den Jenkinsfile aus der Test-Branch, aber die Shared Library aus `main` lädt.

### 3. Parameter neu generieren lassen

Bei Jenkins Declarative Pipelines mit `properties([parameters(...)])` gilt:

- Pipeline einmal ausführen,
- danach "Build with Parameters" neu öffnen,
- Parameter prüfen.

### 4. Active Choices besonders testen

Active Choices Parameter sind sensibel, weil sie dynamische Groovy-Skripte ausführen.

Zu prüfen:

- erscheinen `RELEASE`-Werte?
- erscheinen S3-basierte Dropdowns wie `nvs_abo_verbund`, `LTBW`, `TWE`, `KAM`?
- gibt es neue Einträge unter `In-process Script Approval`?
- lädt Jenkins wirklich die richtige Shared-Library-Version?

### 5. Nicht-destruktive Tests zuerst

Empfohlene Reihenfolge:

1. `modifyConfigurationGroovy` mit `dryRun = true`,
2. `onOffEnvinroment` mit `dryRun = true`,
3. `BIBE_TPO_DataDeployment` nur Parameter/Dropdowns prüfen,
4. BIBE/TPO Software Deployment mit deaktivierten riskanten Aktionen,
5. gezielte produktionsnahe Tests in nicht-kritischen PSX-Umgebungen.

---

## 12. Risiken und Gegenmaßnahmen

| Risiko | Bedeutung | Gegenmaßnahme |
|---|---|---|
| Jenkins lädt falsche Shared-Library-Version | Jenkinsfile und Library passen nicht zusammen | Branch-spezifisch `@Library('jenkins@branch')` testen |
| Active Choices Dropdowns leer | Script Approval, falscher Branch oder veränderte Script-Definition | Script Approval prüfen, Parameter regenerieren, mit Legacy vergleichen |
| Pfadänderungen brechen Shell-Skripte | Skripte erwarten alte relative Pfade | `jenkinsOps.withDeploymentScripts`, `withPman`, `withUpdateStack`; Validierung kanonischer Pfade |
| Doppelte Pfade erzeugen Verwirrung | Legacy und Zielstruktur könnten parallel aktiv wirken | keine Compatibility-Symlinks, Legacy nur unter `pipelines/legacy` |
| Downstream-Jobs erhalten falsche Parameter | `build`-Aufruf nicht robust genug | `jenkinsOps.triggerJob` validiert Jobname und Parameter |
| Big-Bang wirkt schwer reviewbar | viele Dateien ändern sich gleichzeitig | Doku, klare Zielstruktur, Vergleich alt/neu, Validierungsregeln |
| Rollback nötig | V2-Job verhält sich unerwartet | Legacy-Jenkinsfile bleibt als Referenz/Fallback erhalten |

---

## 13. Rollout-Vorschlag

### Phase 1: Technischer Branch-Test

- Shared Library mit Branch Override testen.
- Alle wichtigen V2-Jenkinsfiles einmal laden.
- Parameterseiten prüfen.
- Script Approvals abarbeiten.

### Phase 2: Nicht-destruktive Pipeline-Tests

- `dryRun`-Pipelines,
- Parameter- und Config-Generierung,
- AWS-Leseoperationen,
- PMAN-Parameter-Aufbau.

### Phase 3: Kontrollierte Integration

- einzelne Testumgebung wählen,
- BIBE/TPO-Pipelines mit minimalem Risiko ausführen,
- Build-Badges, Descriptions, Stage-Skips und Fehlerbehandlung prüfen.

### Phase 4: Produktiver Cutover

- Jenkins Jobs auf V2 Script Paths umstellen,
- Shared Library `jenkins` auf `main` verwenden,
- Legacy als Fallback sichtbar lassen,
- Monitoring der ersten produktiven Läufe.

---

## 14. Was sich für Jenkins-Job-Betreiber ändert

### Script Path

Alt:

```text
deployment/BIBE_SWEinsatz.Jenkinsfile
```

Neu:

```text
pipelines/v2/deployment/BIBE_SWEinsatz.Jenkinsfile
```

### Shared Library

Die Jobs benötigen eine registrierte Shared Library:

```groovy
@Library('jenkins') _
```

### Repository-Pfade

Direkte Annahmen über alte Root-Pfade sollen nicht mehr verwendet werden:

```text
deployment/
configuration/
ansible-playbook/
pman/
update-stack/
```

Stattdessen:

```text
scripts/deployment/
config/
infrastructure/ansible/
data/pman/
config/update-stack/
```

---

## 15. Technische Highlights

### 1. Vollständige V2-Abdeckung

Es gibt für jedes Legacy-Jenkinsfile ein entsprechendes V2-Jenkinsfile. Das wird automatisiert validiert.

### 2. Shared-Library-Fassade

`jenkinsOps` kapselt Jenkins-spezifische technische Standards:

```groovy
jenkinsOps.defaultAgentLabel()
jenkinsOps.withDeploymentScripts { ... }
jenkinsOps.withSshAgent { ... }
jenkinsOps.withPman { ... }
jenkinsOps.withUpdateStack { ... }
jenkinsOps.triggerJob('job-name', [FLAG: true], [wait: true])
```

### 3. Fachliche Libraries

Die fachliche Logik wurde nicht in eine generische Utility-Kiste geworfen, sondern nach Domäne getrennt:

- Daten-Deployment,
- Software-Deployment,
- Environment Control,
- Configuration Groovy,
- Config File Operations.

### 4. Keine Symlinks

Symlinks wurden bewusst entfernt, damit es keine scheinbar aktiven doppelten Pfade gibt.

### 5. Auditierbarkeit

Die neue Struktur macht sichtbar:

- was aktiv ist,
- was Legacy ist,
- was obsolet ist,
- welche Pfade Jenkins verwenden soll,
- welche Qualitätsgates gelten.

---

## 16. Bekannte Besonderheit: Active Choices

Active Choices Parameter sind ein Spezialfall, weil die Parameter nicht nur statische Jenkins-Konfiguration sind. Sie führen Groovy-Skripte aus, lesen Dateien, rufen Shell-Kommandos auf und greifen indirekt auf AWS/S3 zu.

Deshalb gilt:

- Parameteränderungen müssen in Jenkins neu geladen werden,
- Script Approval kann nach Refactorings erneut nötig sein,
- Branch und Shared-Library-Version müssen zusammenpassen,
- bei leeren Dropdowns zuerst Jenkins-Log, Script Approval und geladene Library-Version prüfen.

Wichtig für die Präsentation: Diese Besonderheit ist kein Architekturfehler, sondern eine Jenkins-/Plugin-Eigenschaft, die beim Testen bewusst berücksichtigt werden muss.

---

## 17. Warum das professioneller ist

Die neue Architektur verbessert nicht nur die Ordnerstruktur, sondern die Wartbarkeit des gesamten Betriebsmodells:

- weniger kopierte Jenkins-Logik,
- klarere Verantwortlichkeiten,
- besserer Review-Kontext,
- stärkere Validierung,
- sichtbarer Fallback,
- bessere Onboarding-Fähigkeit,
- weniger Risiko durch versteckte alte Pfade,
- bessere Grundlage für weitere Automatisierung.

Aus DevOps-Sicht ist das Repository jetzt näher an einer Plattform-Codebase als an einer Sammlung historisch gewachsener Jenkins-Skripte.

---

## 18. Offene Punkte und nächste Schritte

Empfohlene nächste Schritte:

1. Branch-Test der wichtigsten Pipelines in Jenkins abschließen.
2. Active Choices Parameter gegen die Legacy-Pipelines vergleichen.
3. Script Approvals dokumentieren.
4. V2 Script Paths jobweise in Jenkins umstellen.
5. Für produktive Jobs eine kurze Runbook-Seite ergänzen.
6. Optional: Pipeline-Katalog stärker für Job-Generierung nutzen.
7. Optional: weitere fachliche Jenkinsfiles schrittweise in Shared Library abstrahieren.
8. Optional: automatisierte Jenkinsfile-Linting-/Replay-Checks ergänzen, falls im Jenkins verfügbar.

---

## 19. Vorschlag für eine 20-Minuten-Präsentation

### Slide 1: Titel

**Big-Bang-Refactoring des Jenkins-/DevOps-Repositories**

Kernbotschaft: Von einem historisch gewachsenen Skript-Repository zu einer wartbaren Jenkins-Plattformstruktur.

### Slide 2: Ausgangslage

- gemischte Verantwortlichkeiten,
- viele Root-Artefakte,
- Jenkinsfiles und Skripte vermischt,
- wiederholte Logik,
- unklare aktive Pfade.

### Slide 3: Zielbild

- klare Schichten,
- V2-Pipelines,
- Shared Library,
- Legacy als Referenz,
- Validierung als Gate.

### Slide 4: Neue Repository-Struktur

Zeige die Zielstruktur:

```text
vars/
src/org/jenkins/
resources/org/jenkins/
pipelines/v2/
pipelines/legacy/
scripts/deployment/
scripts/ops/
infrastructure/ansible/
data/pman/
config/update-stack/
legacy/obsolete/
docs/
```

### Slide 5: Warum Big-Bang?

- keine doppelten Pfade,
- keine lange Zwischenarchitektur,
- klares Zielbild,
- auditierbarer Schnitt,
- reproduzierbare Migration.

### Slide 6: Shared Library

- `jenkinsOps` als zentrale Fassade,
- fachliche Libraries für Daten, Software, Environment, Config,
- Jenkinsfiles bleiben Orchestrierung.

### Slide 7: V2-Pipelines

- 22 Legacy-Dateien,
- 22 V2-Dateien,
- keine reinen Legacy-Delegationswrapper,
- gleiche fachliche Pipeline-Namen und Stage-Flüsse.

### Slide 8: Validierung

- `make validate`,
- Root-`Jenkinsfile`,
- Pfadprüfung,
- V2-Abdeckung,
- keine Symlinks,
- Whitespace.

### Slide 9: Risiken und Testing

- Shared-Library-Version,
- Active Choices,
- Script Approval,
- dryRun,
- Branch-Tests.

### Slide 10: Ergebnis und nächster Schritt

- Repository ist wartbarer,
- Jenkins-Jobs können auf V2 Script Paths umgestellt werden,
- Legacy bleibt Fallback,
- kontrollierter Rollout.

---

## 20. Sprechtext für den Einstieg

> Ziel des Refactorings war nicht, Dateien kosmetisch in neue Ordner zu verschieben. Ziel war, aus einem historisch gewachsenen Jenkins-Skript-Repository eine wartbare DevOps-Plattformstruktur zu machen.  
>  
> Der wichtigste Architekturentscheid war: Jenkinsfiles sollen orchestrieren, aber wiederverwendbare technische und fachliche Logik gehört in eine Jenkins Shared Library. Gleichzeitig wollten wir keine doppelt sichtbaren alten und neuen Pfade behalten, weil das im Betrieb schnell zu Unsicherheit führt. Deshalb wurde das Refactoring bewusst als Big-Bang-Schnitt umgesetzt, aber mit Legacy-Fallback, Dokumentation und automatisierter Validierung.

---

## 21. Erwartbare Fragen und Antworten

### Warum wurden Symlinks entfernt?

Weil sie im Repository wie aktive Ordner wirken und im Betrieb zu doppelten Wahrheiten führen können. Ohne Symlinks gibt es genau einen kanonischen Pfad.

### Warum bleiben Legacy-Pipelines trotzdem erhalten?

Als Referenz und Fallback. Sie sind sichtbar, aber nicht Teil der Zielarchitektur.

### Wie stellen wir sicher, dass jede Legacy-Pipeline eine V2-Pipeline hat?

`make validate` vergleicht die Dateilisten unter `pipelines/legacy` und `pipelines/v2`.

### Was passiert, wenn ein V2-Job fehlschlägt?

Zuerst Jenkins-Log, Shared-Library-Version und Parameter prüfen. Für fachlichen Vergleich steht die Legacy-Version im Repository.

### Warum ist Active Choices ein Spezialfall?

Active Choices führt eigene Groovy-Skripte zur Parametererzeugung aus. Diese Skripte können durch Script Approval, Branch-Versionen oder Plugin-Verhalten beeinflusst werden.

### Warum nicht alles sofort in Shared Library auslagern?

Zu starke Abstraktion kann Jenkins-Pipelines schwer nachvollziehbar machen. Das Ziel ist eine Balance: Stage-Fluss bleibt im Jenkinsfile sichtbar, wiederverwendbare Details werden zentralisiert.

### Ist das Refactoring produktionssicher?

Es ist strukturell validiert und konservativ migriert. Produktive Sicherheit entsteht aber erst durch kontrollierte Jenkins-Tests, Branch-Tests, dryRun und schrittweisen Cutover.

---

## 22. Abschlussbotschaft

Das Big-Bang-Refactoring schafft eine klare technische Grundlage:

- eindeutige Pfade,
- vollständige V2-Pipelines,
- zentrale Shared Library,
- sichtbarer Legacy-Fallback,
- automatisierte Validierung,
- bessere Wartbarkeit für DevOps.

Die wichtigste Änderung ist nicht ein neuer Ordnerbaum. Die wichtigste Änderung ist ein neues Betriebsmodell: Pipeline-Code wird als Plattform-Code behandelt.

