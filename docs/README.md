# Dokumentation

Diese Dokumentation beschreibt das Big-Bang-Refactoring des Jenkins-Repositories.

## Dokumente

- [ARCHITECTURE.md](ARCHITECTURE.md): Zielarchitektur, Schichtenmodell, V2-Pipelines und kanonische Pfade.
- [REFACTORING.md](REFACTORING.md): Was verschoben wurde, welche Referenzen angepasst wurden und wie man es reproduziert.
- [ALT_NEU_VERGLEICH.md](ALT_NEU_VERGLEICH.md): Vergleich der alten Struktur mit der neuen Big-Bang-Architektur.

## Kernaussage

Die reale Zielimplementierung liegt in `pipelines/v2/`, `scripts/`, `infrastructure/`, `data/` und `config/`. Alte Jenkins- und Skriptpfade wurden entfernt, damit die neuen Pfade eindeutig die Quelle der Wahrheit sind. `pipelines/legacy/` bleibt nur als Referenz/Fallback erhalten.
