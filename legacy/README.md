# Legacy und obsolete Artefakte

Dieser Bereich enthält ausschließlich Artefakte, die nicht mehr Teil der aktiven Architektur sind.

## Struktur

```text
legacy/
└── obsolete/
    ├── deployment/
    │   ├── _old/
    │   └── onOffEnvinroment_old.Jenkinsfile
    └── ide/
        └── idea/
```

## Abgrenzung

- `pipelines/legacy/` enthält weiterhin aktive Legacy-Jenkinsfiles, die produktiv relevant sein können.
- `legacy/obsolete/` enthält nur alte oder nicht mehr aktive Artefakte.

## Regel

Obsolete Dateien werden archiviert statt gelöscht, damit Audit und Rollback möglich bleiben.
