# Refactoring-Dokumentation

## Ziel des Big-Bang-Refactorings

Das Repository sollte nicht nur kosmetisch verbessert werden, sondern eine echte professionelle DevOps-/Jenkins-Architektur erhalten.

Die Lösung ist ein Big-Bang-Refactoring ohne verbleibende Compatibility-Symlinks:

- echte Dateien wurden in fachliche Zielbereiche verschoben,
- alte doppelte Root-Pfade wurden entfernt,
- alle aktiven Jenkinsfiles wurden als V2-Zielpipelines mit `@Library('jenkins')` bereitgestellt,
- Jenkins-/Skript-Referenzen wurden auf die neuen Pfade angepasst,
- obsolete Dateien liegen separat unter `legacy/obsolete/`,
- alle Änderungen werden in einem einzigen Commit zusammengefasst.

## Was wurde verschoben?

### Jenkinsfiles

Von:

```text
deployment/*.Jenkinsfile
deployment/*.jenkinsfile
configuration/modifyConfigurationGroovy.Jenkinsfile
```

Nach:

```text
pipelines/legacy/deployment/
pipelines/legacy/configuration/
```

Zusätzlich wurden vollständige V2-Zielpipelines erzeugt:

```text
pipelines/v2/deployment/
pipelines/v2/configuration/
```

Aktive Jenkins-Jobs sollen diese neuen V2 Script Paths direkt verwenden.

### Deployment-Skripte

Von:

```text
deployment/*.sh
deployment/compare_bibe_tpo_info_*
```

Nach:

```text
scripts/deployment/
```

Relative Aufrufe innerhalb der Skripte wurden auf `config/update-stack/` und `infrastructure/ansible/` angepasst.

### Root-Operations-Skripte

Von Root:

```text
check_kernel
check_qualys
chkCsirtRuleUpdate.sh
create-snapshot.py
terminate_psx_bibe.sh
terminate_psx_tpo.sh
uploglevel2st.sh
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

### Jenkins-Konfiguration

Von:

```text
configuration/BuilderJenkinsConfiguration.groovy
configuration/Configuration.groovy
```

Nach:

```text
config/jenkins-configuration-builder.groovy
config/jenkins-configuration.example.groovy
```

## V2-Pipeline-Migration

Die V2-Pipelines wurden konservativ aus den Legacy-Jenkinsfiles abgeleitet, damit Verhalten, Parameter, Cron-Trigger, Active Choices, Build-Badges und Descriptions erhalten bleiben.

Geändert wurde gezielt:

- `@Library('jenkins') _` wird geladen.
- `agent { label 'master' }` nutzt `jenkinsOps.defaultAgentLabel()`.
- direkte `sshagent([...])`-Blöcke nutzen `jenkinsOps.withSshAgent`.
- direkte Arbeitsverzeichnisse wie `scripts/deployment`, `data/pman` und `config/update-stack` nutzen `jenkinsOps.withDeploymentScripts`, `jenkinsOps.withPman` und `jenkinsOps.withUpdateStack`.
- V2-Wrapper mit reiner Legacy-Delegation wurden entfernt.

Legacy bleibt als Referenz/Fallback unter `pipelines/legacy/` erhalten.

## Shared Library

Die Jenkins Shared Library bleibt am Root, weil Jenkins diese Struktur erwartet:

```text
vars/
src/
resources/
```

Zentrale Fassade:

```text
vars/jenkinsOps.groovy
```

Namespace:

```text
org.jenkins
```

## Obsolete Dateien

Alte und nicht mehr aktive Dateien wurden nach `legacy/obsolete/` verschoben, z. B.:

```text
legacy/obsolete/deployment/_old/
legacy/obsolete/deployment/onOffEnvinroment_old.Jenkinsfile
legacy/obsolete/ide/idea/
```

Diese Dateien bleiben für Audit und Rollback sichtbar, sind aber nicht Teil der aktiven Zielarchitektur.

## Neue aktive Pfade

Beispiele für neue Jenkins Script Paths:

```text
pipelines/v2/deployment/BIBE_SWEinsatz.Jenkinsfile
pipelines/v2/deployment/TPO_SWEinsatz.Jenkinsfile
pipelines/v2/deployment/BIBE_TPO_DataDeployment.Jenkinsfile
pipelines/v2/configuration/modifyConfigurationGroovy.Jenkinsfile
```

Beispiele für neue Datei-/Skriptpfade:

```text
scripts/deployment/BIBE_createSnapshot.sh
scripts/ops/create-snapshot.py
infrastructure/ansible/
data/pman/
config/update-stack/
```

## Manuelle Reproduktion

Das Refactoring kann manuell reproduziert werden durch:

1. Zielordner anlegen.
2. Jenkinsfiles nach `pipelines/legacy/` verschieben.
3. Deployment-Skripte nach `scripts/deployment/` verschieben.
4. Root-Operations-Skripte nach `scripts/ops/` verschieben.
5. Ansible, PMAN und update-stack in `infrastructure/`, `data/`, `config/` verschieben.
6. V2-Jenkinsfiles unter `pipelines/v2/` aus den Legacy-Jenkinsfiles erzeugen.
7. V2-Jenkinsfiles auf Shared-Library-Helfer und neue Pfade aktualisieren.
8. Jenkinsfiles und Skripte auf die neuen relativen Pfade aktualisieren.
9. Obsolete Artefakte nach `legacy/obsolete/` verschieben.
10. Alte Compatibility-Symlinks entfernen.
11. Doku und Validierung aktualisieren.
12. `make validate` ausführen.
13. Alles in einem Commit committen.

## Historienstrategie

Die vorherigen Refactoring-Commits wurden bewusst zusammengeführt. Der Remote-Branch soll nur einen einzigen neuen Refactoring-Commit gegenüber dem ursprünglichen Stand enthalten.

Dafür wird ein History-Rewrite mit `--force-with-lease` verwendet, nicht ein normaler Push.

## Validierung

Ausgeführt werden muss:

```bash
make validate
```

Zusätzlich sinnvoll:

```bash
git diff --check
find . -type l
```

`find . -type l` darf keine Ausgabe liefern, weil im aktiven Repository keine Symlinks mehr verwendet werden sollen.

## Rollback

Wenn ein V2-Job in Jenkins unerwartet Probleme macht, bleibt der äquivalente Legacy-Jenkinsfile unter `pipelines/legacy/` als Referenz/Fallback im Repository erhalten. Ein Git-Rollback auf den Commit vor dem Big-Bang bleibt weiterhin möglich.

## Wichtig

Dieses Refactoring ist bewusst groß, aber nicht blind. Es trennt Architektur sauber, entfernt doppelte Pfade, stellt vollständige V2-Pipelines bereit und dokumentiert die neue Struktur vollständig.
