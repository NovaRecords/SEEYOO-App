# Product Backlog - SEEYOO Live-TV Streaming App

## Einführung
Dieses Dokument dient als zentrale Sammlung aller Anforderungen, Funktionen und technischen Aufgaben für die Entwicklung der SEEYOO Live-TV Streaming App. Der Backlog ist nach Epics gruppiert und priorisiert.

## Priorisierungslegende
- **MUST HAVE** (Muss): Unverzichtbare Kernfunktionalitäten für den Start
- **SHOULD HAVE** (Sollte): Wichtige Funktionen, aber nicht kritisch für den Start
- **COULD HAVE** (Könnte): Nützliche Erweiterungen, wenn Zeit bleibt
- **WON'T HAVE** (Nicht in dieser Version): Für zukünftige Versionen geplant

## Backlog Items

### 1. Benutzerverwaltung (User Management)
| ID | User Story | Akzeptanzkriterien | Priorität | Story Points |
|----|------------|---------------------|-----------|--------------|
| US-1 | Als Benutzer möchte ich mich registrieren, um auf die App zugreifen zu können | - E-Mail-Verifizierung vorhanden<br>- Validierung der Eingaben<br>- Fehlermeldungen auf Deutsch | MUST | 5 |
| US-2 | Als Benutzer möchte ich mich anmelden, um auf mein Konto zuzugreifen | - E-Mail/Passwort Login<br>- Fehlerbehandlung für falsche Anmeldedaten<br>- "Angemeldet bleiben"-Funktion | MUST | 3 |
| US-3 | Als Benutzer möchte ich mein Passwort zurücksetzen können, falls ich es vergessen habe | - E-Mail-Versand mit Reset-Link<br>- Ablaufzeit für Reset-Link | MUST | 3 |
| US-4 | Als Benutzer möchte ich mein Profil bearbeiten können | - Ändern von Name, E-Mail, Passwort<br>- Profilbild hochladen | SHOULD | 5 |

### 2. Kanalübersicht (Channel Browsing)
| ID | User Story | Akzeptanzkriterien | Priorität | Story Points |
|----|------------|---------------------|-----------|--------------|
| US-5 | Als Benutzer möchte ich eine Übersicht aller verfügbaren Kanäle sehen | - Kachelansicht der Kanäle<br>- Ladeanimation während des Ladens<br>- Fehlerbehandlung bei Verbindungsproblemen | MUST | 8 |
| US-6 | Als Benutzer möchte ich nach Kanälen suchen können | - Suchfunktion mit Echtzeit-Vorschlägen<br>- Keine Ergebnisse gefunden Meldung | SHOULD | 5 |
| US-7 | Als Benutzer möchte ich Kanäle nach Kategorien filtern können | - Kategorieauswahl über Dropdown<br>- Mehrfachauswahl möglich | SHOULD | 5 |
| US-8 | Als Benutzer möchte ich meine Lieblingssender speichern können | - Herz-Icon zum Markieren<br>- Eigene Favoriten-Ansicht | SHOULD | 3 |

### 3. Video-Streaming
| ID | User Story | Akzeptanzkriterien | Priorität | Story Points |
|----|------------|---------------------|-----------|--------------|
| US-9 | Als Benutzer möchte ich einen Kanal auswählen und sofort ansehen können | - Schneller Stream-Start (<2s)<br>- Automatische Anpassung der Videoqualität<br>- Pufferanzeige bei Ladezeiten | MUST | 13 |
| US-10 | Als Benutzer möchte ich die Videoqualität manuell einstellen können | - Qualitätsauswahl im Player-Menü<br>- Automatische Anpassung als Standard | SHOULD | 5 |
| US-11 | Als Benutzer möchte ich das Video im Vollbildmodus ansehen können | - Automatische Bildschirmrotation<br>- Steuerelemente ein-/ausblendbar | MUST | 3 |
| US-12 | Als Benutzer möchte ich das Video pausieren und fortsetzen können | - Pause/Fortsetzen-Button<br>- Fortsetzungsfunktion nach Unterbrechung | WONT | 5 |

### 4. Elektronische Programmzeitschrift (EPG)
| ID | User Story | Akzeptanzkriterien | Priorität | Story Points |
|----|------------|---------------------|-----------|--------------|
| US-13 | Als Benutzer möchte ich das aktuelle und kommende Programm sehen | - Übersichtliche Zeitleiste<br>- Aktuelles Programm hervorgehoben | MUST | 8 |
| US-14 | Als Benutzer möchte ich nach Sendungen suchen können | - Volltextsuche über alle Sendungen<br>- Filter nach Datum/Zeit | WONT | 5 |
| US-15 | Als Benutzer möchte ich eine Erinnerung für eine Sendung einstellen können | - Benachrichtigung vor Sendungsbeginn<br>- Einstellbare Erinnerungszeit | WONT | 8 |

### 5. Technische Anforderungen
| ID | Anforderung | Beschreibung | Priorität | Story Points |
|----|------------|--------------|-----------|--------------|
| TECH-1 | Responsive Design | Die App muss auf verschiedenen Bildschirmgrößen gut aussehen | MUST | 8 |
| TECH-2 | Offline-Modus | Grundlegende Funktionen ohne Internetverbindung | SHOULD | 13 |
| TECH-3 | Performance-Optimierung | Schnelle Ladezeiten und flüssige Wiedergabe | MUST | 8 |
| TECH-4 | Analytics Integration | Nutzungsdaten für spätere Verbesserungen sammeln | COULD | 5 |

### 6. Sicherheit
| ID | Anforderung | Beschreibung | Priorität | Story Points |
|----|------------|--------------|-----------|--------------|
| SEC-1 | Sichere Authentifizierung | Implementierung von JWT | MUST | 8 |
| SEC-2 | Verschlüsselung | Alle Datenübertragungen müssen verschlüsselt sein | MUST | 5 |
| SEC-3 | Datenschutz | Einhaltung der DSGVO | MUST | 5 |

## Technische Verbesserungen (Technical Debt)
| ID | Beschreibung | Priorität | Story Points |
|----|--------------|-----------|--------------|
| TD-1 | Code-Refactoring | Verbesserung der Codequalität | SHOULD | 5 |
| TD-2 | Testabdeckung erhöhen | Mindestens 80% Testabdeckung erreichen | SHOULD | 8 |
| TD-3 | Dokumentation aktualisieren | Technische Dokumentation vervollständigen | COULD | 3 |

## Release-Planung

### MVP (Minimum Viable Product) - Version 1.0
- Benutzerverwaltung (Anmeldung, Registrierung)
- Grundlegende Kanalübersicht
- Basis-Streaming-Funktionalität
- Einfache EPG-Ansicht

### Version 1.1
- Erweiterte Suche und Filter
- Favoritenfunktion
- Verbesserte Benutzeroberfläche
- Performance-Optimierungen

### Zukünftige Versionen
- Personalisierte Empfehlungen
- Social-Features (Teilen, Kommentare)
- Erweiterte Benachrichtigungen
- Integration mit Smart-Home-Systemen

## Offene Fragen
- Welche Kanäle sollen in der ersten Version verfügbar sein?
- Gibt es spezielle Anforderungen an die Barrierefreiheit?
- Sollen Werbeinhalte unterstützt werden?

## Änderungshistorie
| Datum | Version | Beschreibung | Autor |
|-------|---------|--------------|-------|
| 26.06.2025 | 1.0 | Erste Version des Product Backlogs | Vitali Mack |
