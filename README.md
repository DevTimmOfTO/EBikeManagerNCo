# EBikeManagerNCo

Local-only Android-Begleit-App fürs E-Bike: Trip-Tracking, Batterie-Historie, Reparaturguides und Stellplatz-Erinnerung — alles offline, ohne Cloud-Zwang.

## Features

- **Dashboard** — Überblick über dein E-Bike auf einen Blick
- **Trips** — Fahrten manuell erfassen oder über Health Connect synchronisieren (Distanz, Dauer, Ø-Geschwindigkeit, Höhenmeter, Kalorien, Herzfrequenz), inkl. Streckenverlauf auf der Karte
- **Batterie-Historie** — Ladezyklen, Gesundheitschecks und geschätzter Akkuzustand über die Zeit (Verlauf als Chart)
- **Reparaturguides** — gebündelte Schritt-für-Schritt-Anleitungen für gängige E-Bike-Reparaturen
- **Parkposition** — letzten Standort deines Bikes merken und wiederfinden
- **Mehrere Bikes** — Verwaltung mehrerer Räder mit eigenen Stammdaten (Motor, Akku, ADFC-Codierung, Fotos)

## Tech Stack

Flutter, Riverpod, go_router, Drift (SQLite), flutter_map (OSM), Health Connect via `health`-Package. Details siehe [`EBikeManagerNCo-TODO.md`](EBikeManagerNCo-TODO.md).

## Status

In aktiver Entwicklung. Alle Daten bleiben lokal auf dem Gerät.

## Getting Started

```bash
flutter pub get
flutter run
```

Benötigt Android (compileSdk 37) und optional Health Connect für automatischen Trip-Sync.
