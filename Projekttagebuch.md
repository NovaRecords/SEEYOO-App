# Projekttagebuch

## Tag 1 (01.07.2025)

- 🟢 **Heutige Hauptaufgaben:** Ich habe mir heute vorgenommen den Live-TV bereich zu designen. Alle notwendigen Elemente einzubauen und passende Farben und Stile zu implementieren.
- 🟢 **Fortschritt & Ergebnisse:** Ich habe die grundlegende Struktur des Live-TV Bereichs erstellt und alle notwendigen Elemente implementiert.
- 🟢 **Herausforderungen & Blockaden:** Es ging noch eigentlich. Wenn das ganze mit API verbunden wird, dann kommen die richtigen Herausforderungen.
- 🟢 **Was ich heute gelernt habe:** Ich habe heute gelernt dass man vieeeeeeeeellll Geduld braucht um weiter zu kommen. Aber es klappt!
- 🟢 **Plan für morgen:** Morgen werde ich den Live-TV bereich mit der API verbinden. Ich werde die API Daten in die App einbinden und die Kanäle mit den richtigen Daten aus der API anzeigen. Die Logos von Kanälen muss ich noch kreieren. Mal sehen. Bin zuversichtlich.

![Screenshot des Live-TV Bereichs](pics/tv-screen01.png)
*Abbildung 1: Live-TV Bereich*

## Tag 2 (02.07.2025)

- 🟢 **Heutige Hauptaufgaben:** Ich habe mir heute vorgenommen den Live-TV bereich mit der API zu verbinden. Ich habe die API Daten in die App einbinden können und die Kanäle mit den richtigen Daten aus der API anzeigen. 
- 🟢 **Fortschritt & Ergebnisse:** Ich habe die API Daten in die App einbinden können und die Kanäle mit den richtigen Daten aus der API anzeigen. Logos für die Sender habe ich noch nicht kreiert. 
- 🟢 **Herausforderungen & Blockaden:** Ich habe noch keine Logos für die Sender kreiert. Die Anbindung an die API ist schwierig. Konnte nur erstmal die liste von Kanälen aus der API abrufen. Keine EPG-Daten, Keine Favoriten.
- 🟢 **Was ich heute gelernt habe:** Ich habe heute gelernt dass man noch mehr  Geduld braucht um weiter zu kommen. Aber es wird schon!
- 🟢 **Plan für morgen:** Morgen werde ich die Logos für die Sender kreieren. Ich plane morgen weiter zu kommen mit EPG-Daten und Favoriten.

![Screenshot des Live-TV Bereichs](pics/tv-screen02.png)
*Abbildung 1: Live-TV Bereich*

![Screenshot des Menü Bereichs](pics/menu-screen02.png)
*Abbildung 2: Menü Bereich*

## Tag 3 (03.07.2025)

- 🟢 **Heutige Hauptaufgaben:** Logos für TV-Kanäle, EPG-Daten, Kategorien, TV-Favoriten.
- 🟢 **Fortschritt & Ergebnisse:** Ich habe die Logos für die Sender kreiert. Genauer gesagt habe ich die Logos für die Sender aus der API abgerufen und in die App eingebunden. EPG-Daten voll implementiert und unter "Programm" gebracht. Habe auch "Kategorien" gemacht, jetzt kann man die Sender nach Kategorien filtern. Zu Favoriten bin leider noch nicht gekommen... 
- 🟢 **Herausforderungen & Blockaden:** Die API ist sehr komplex und es nimmt unheimlich viel Zeit in Anspruch. Aber es klappt!
- 🟢 **Was ich heute gelernt habe:** Heute habe ich gelenrt dass man am besten schon nach kleinen änderungen, die man geprüft hat und die funktionieren - am besten sofort die Änderungen ins Repo pusht. Hatte heute fast alles verloren gehabt... 
- 🟢 **Plan für morgen:** Ich plane mir die TV-Favoriten zu implementieren.
Dies vorraussetzt allerdings die USERID implementation. Muss zuerst USERID implementiert werden, danach könnte ich die Favoriten unter die Lupe nehmen.

![Screenshot des Menü Bereichs](pics/tv-screen03.png)
*Abbildung 1: Menü Bereich*

![Screenshot des EPG Bereichs](pics/EPG-screen01.png)
*Abbildung 2: EPG Bereich*

![Screenshot des Kategorien Bereichs](pics/Kat-screen01.png)
*Abbildung 3: Kategorien Bereich* 

## Tag 4 (04.07.2025)

- 🟢 **Heutige Hauptaufgaben:** Heute wollte ich die USERID und Favoriten implementieren.
- 🟢 **Fortschritt & Ergebnisse:** Es gab so viele kleinigkeiten die man unbedingt machen sollte. Habe dafür den heutigen Tag geopfert. Muss wohl USERID und Favoriten auf den Nächsten Tag verschieben.
- 🟢 **Herausforderungen & Blockaden:** Ich müsste die Logik für die EPG-Daten Abfrage überdenken. Wir laden ja die EPG-Daten beim starten des Apps für die nächsen 20 Sendungen, für die "Programm". Ich habe zuesrt die EPG-Daten für die TV-Kanäle separat abgefragt. Das führte zu Problemen mit den EPG-Daten. Dann müsste ich die logik überlegen, dass ich die EPG-Daten nutze, die bereits geladen sind. Das war eine Herausforderung.
- 🟢 **Was ich heute gelernt habe:** Ich habe heute gelernt dass man sehr schnell Überblick verlieren kann, wenn man nicht den Plan befolgt. Aber man lernt draus.
- 🟢 **Plan für morgen:** Ich plane USERID und Favoriten zu beweltigen.

![Screenshot des Live-TV Bereichs](pics/tv-screen04.png)
*Abbildung 1: Live-TV Bereich*

![Screenshot des EPG Bereichs](pics/EPG-screen02.png)
*Abbildung 2: EPG Bereich*

![Screenshot des Kategorien Bereichs](pics/Kat-screen02.png)
*Abbildung 3: Kategorien Bereich* 


## Tag 5 (05.07.2025)

- 🟢 ** Samstag **

## Tag 6 (06.07.2025)

- 🟢 ** Sonntag **

## Tag 7 (07.07.2025)

- 🟢 **Heutige Hauptaufgaben:** USERID und Favoriten
- 🟢 **Fortschritt & Ergebnisse:** Ich habe erfolgreich den USERID implementiert. Auch Favoriten funktion wurde umgesetzt. Sortierung von Favoriten funktioniert.
- 🟢 **Herausforderungen & Blockaden:** Es gibt noch ein paar Probleme die ich noch lösen muss. Die Scrolllogik funktioniert nicht so wie ich es wollte. Sowohl in tv_screen als auch in tv_favorite_screen.
- 🟢 **Was ich heute gelernt habe:** Wenn man geduldig und hartnäckig ist, dann klapp schon alles!
- 🟢 **Plan für morgen:** Scrolllogik in tv_screen und tv_favorite_screen verbessern, Favoriten Delete-funktion implementieren, Ping-Logik implementieren, Letzte geschater Kanal speichern...

## Tag 8 (08.07.2025)

- 🟢 **Heutige Hauptaufgaben:** Scrolllogik in tv_screen und tv_favorite_screen verbessern, Favoriten Delete-funktion implementieren, Ping-Logik implementieren, Letzte geschater Kanal speichern...
- 🟢 **Fortschritt & Ergebnisse:** Heute habe ich sehr viele Kleinigkeiten umgesetzt die sehr wichtig waren. Scrolllogik in tv_screen und tv_favorite_screen verbessert. Favoriten Delete-funktion implementiert. Ping-Logik implementiert. Letzte geschauter Kanal speichert. Media-Info Status implementiert. 
- 🟢 **Herausforderungen & Blockaden:**  Ich habe heute fast 8 Stunden damit verbracht den verdammten Scrolllogik in tv_screen und tv_favorite_screen zu verbessern, danach zu reparieren, danach alles löschen und neu implementieren.... Es war eine Katastrophe! Und am ende war es eine klitzekleine sache, die das ganze verhalten der scrolllogik beeinflusst hat. Aber es hat geklappt!!!
- 🟢 **Was ich heute gelernt habe:** Heute habe ich das scrollen gelernt!!! 
- 🟢 **Plan für morgen:** Morgen werde ich mir den Bereich Einstellungen vornehmen, den Authorisation Bereich. (Mac-Adresse, Serial Number, Device ID).

## Tag 9 (09.07.2025)

- 🟢 **Heutige Hauptaufgaben:** Benutzerintegration der Billing API verbessern, dynamische Benutzer-IDs verwenden, Testbenutzer-Funktion entfernen
- 🟢 **Fortschritt & Ergebnisse:** Erfolgreiche Implementierung der getrennten ID-Verwaltung für Auth-API (user_id) und Billing-API (billing_user_id). Bei Anmeldung und Registrierung werden Benutzer jetzt korrekt in beiden Systemen synchronisiert. Testbenutzer-Funktion entfernt und durch benutzerfreundlichen Login-Button ersetzt.
- 🟢 **Herausforderungen & Blockaden:** Die größte Herausforderung war die unterschiedliche ID-Vergabe zwischen den beiden APIs zu verstehen und zu synchronisieren. Die ursprüngliche Implementierung verwendete Auth-API-IDs für Billing-API-Anfragen, was zu fehlenden Benutzerdaten führte. Ein weiteres Problem war ein nicht existierender Methodenaufruf "fallbackStoredUser()".
- 🟢 **Was ich heute gelernt habe:** Heute habe ich gelernt, wie wichtig es ist, in einer komplexen Anwendung mit mehreren APIs die Daten-IDs sauber zu trennen und zu verwalten. Die getrennte Speicherung von user_id und billing_user_id im StorageService sorgt für deutlich robustere Datenabfragen.
- 🟢 **Plan für morgen:** Bereich Mein Konto, Einstellungen zu Ende bringen und wenn zeitlich passt - anfangen mit Player-Implementation.

## Tag 10 (10.07.2025)

- 🟢 **Heutige Hauptaufgaben:** Benutzerkontodetails korrekt darstellen und Datenfluss zwischen Stalker Portal und Billing API verbessern; Aktivierungsstatus des Kontos anzeigen; Sicherheitsverbesserungen für API-Zugangsdaten implementieren.

- 🟢 **Fortschritt & Ergebnisse:** Erfolgreich implementiert: Anzeige des Konto-Aktivierungsstatus im Profil-Header mit farbkodierten Icons (grün für aktiv, rot für inaktiv); korrektes Laden und Anzeigen der MAC-Adresse aus dem Stalker Portal; Umbenennung von "Version" zu "Gerät" für bessere Klarheit; verbesserte Extraktion von Benutzerdaten aus dem Stalker Portal und Billing API; robuste Fallback-Mechanismen bei fehlenden Daten.

- 🟢 **Herausforderungen & Blockaden:** Versuch, die Billing API-Zugangsdaten in Flutter Secure Storage zu speichern, führte zu MissingPluginException beim Ausloggen; mussten zur hartcodierten Credential-Lösung zurückkehren, um die Funktionalität zu gewährleisten; iOS-spezifische Konfigurationen für Secure Storage waren herausfordernd.

- 🟢 **Was ich heute gelernt habe:** Die Komplexität bei der Integration von nativen Sicherheitsfeatures wie Secure Storage in Flutter-Apps; Wichtigkeit von robusten Fallback-Mechanismen; besseres Verständnis des Datenflusses zwischen den verschiedenen APIs und wie sie zusammenwirken, um ein vollständiges Benutzerprofil zu erstellen.

- 🟢 **Plan für morgen:** Player-Implementation für TV-Kanäle beginnen; verbleibende UI-Verbesserungen in den Einstellungen umsetzen; potenzielle sicherere Lösung für API-Credentials recherchieren, die mit allen Plattformen kompatibel ist.

Ein Paar Bilder zum Fortschritt:

<div style="display: flex; justify-content: center; gap: 20px;">
  <img src="pics/Start-screens.png" alt="Screenshot Startscreen" width="300">
  <img src="pics/login-screens.png" alt="Screenshot Login" width="300">
</div>

<div style="display: flex; justify-content: center; gap: 20px;">
  <img src="pics/menu-screen-tv.png" alt="Screenshot Menü TV" width="300">
  <img src="pics/tv-screen06.png" alt="Screenshot TV" width="300">
</div>

<div style="display: flex; justify-content: center; gap: 20px;">
  <img src="pics/EPG-screen04.png" alt="Screenshot EPG" width="300">
  <img src="pics/Kat-screen04.png" alt="Screenshot Kategorien" width="300">
</div>

<div style="display: flex; justify-content: center; gap: 20px;">
  <img src="pics/menu-screen-fav.png" alt="Screenshot Menü Favoriten" width="300">
  <img src="pics/fav-screen01.png" alt="Screenshot Favoriten1" width="300">
  <img src="pics/fav-screen02.png" alt="Screenshot Favoriten2" width="300">
</div>

<div style="display: flex; justify-content: center; gap: 20px;">
  <img src="pics/menu-screen-setting.png" alt="Screenshot Menü Einstellungen" width="300">
  <img src="pics/setting-screen01.png" alt="Screenshot Einstellungen1" width="300">
</div>

<div style="display: flex; justify-content: center; gap: 20px;">
  <img src="pics/menu-screen-konto.png" alt="Screenshot Menü Mein Konto" width="300">
  <img src="pics/konto-screen01.png" alt="Screenshot Mein Konto1" width="300">
</div>

## Tag 11 (11.07.2025)

- 🟢 **Heutige Hauptaufgaben:** Player-Implementation für TV-Kanäle
- 🟢 **Fortschritt & Ergebnisse:** Kategorienauswahl markierung hinzugefügt. Ausgewählten Kategorien-status speichern und laden hinzugefügt. Favoriten Sortierung hinzugefügt. Mit dem Player Integration begonnen.
- 🟢 **Herausforderungen & Blockaden:** Habe den ganzen Tag damit verbracht den richtigen Ansatz zu finden um Player Implementation zu ermöglichen. Ich habe mir die Dokumentation gelesen und versucht es mit verschiedenen Ansätzen. Aber es ging noch nicht. Das wird schon... bin mir ziemlich sicher.
- 🟢 **Was ich heute gelernt habe:** Wenn du denkst, dass du schon kurz vom Ziel bist - bist du gerade noch am Anfang....
- 🟢 **Plan für morgen:** Player Integration für TV-Kanäle.

## Tag 12 (12.07.2025)

- 🟢 ** Samstag **

## Tag 13 (13.07.2025)

- 🟢 ** Sonntag **

## Tag 14 (14.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
  - Integration eines HLS Video-Players in TV-Screen und TV-Favoriten-Screen
  - Optimierung des Querformat-Verhaltens und der Darstellung auf verschiedenen Geräten
  - Plattformspezifische Anpassungen der Statusleiste

- 🟢 **Fortschritt & Ergebnisse:**
  - Erfolgreiche Implementierung eines steuerungsfreien Video-Players mit video_player-Bibliothek
  - Konsistentes 16:9 Seitenverhältnis für den VideoPlayer durch AspectRatio-Widget
  - Plattformspezifische Statusleistensteuerung: Android-Statusleiste bleibt immer sichtbar, iOS behält immersives Verhalten
  - Player mit automatischem Looping und ohne zusätzliche Steuerelemente umgesetzt

- 🟢 **Herausforderungen & Blockaden:**
  - Unterschiedliches Verhalten der Statusleiste zwischen iOS und Android Geräten
  - Verhältnis des Video-Players musste für verschiedene Bildschirmgrößen angepasst werden
  - Sicherstellen der korrekten Ressourcenfreigabe bei Player-Wechsel oder Bildschirmwechsel

- 🟢 **Was ich heute gelernt habe:**
  - Die video_player-Bibliothek ist besser mit neueren Flutter-Versionen kompatibel als better_player
  - Plattformspezifische Implementierungsunterschiede erfordern explizite Behandlung in der App
  - Durch feste Constraints und AspectRatio-Widget kann ein konsistentes Videobild auf allen Geräten sichergestellt werden

- 🟢 **Plan für morgen:**
  - Weitere Optimierungen am Video-Player vornehmen
  - Player-Steuerungen (z.B. Play/Pause) als optionale Elemente implementieren
  - Behandlung von Orientierungswechseln verbessern

## Tag 15 (15.07.2025)

- 🟢 **Heutige Hauptaufgaben:** Verbesserung der Behandlung von Orientierungswechseln in der App.
- 🟢 **Fortschritt & Ergebnisse:** Ich habe verschiedene Ansätze zur Behandlung von Orientierungswechseln ausprobiert und Recherchen durchgeführt, bin jedoch noch nicht zu einer vollständigen Lösung gekommen. Erste Grundlagen für eine responsive Anpassung wurden gelegt.
- 🟢 **Herausforderungen & Blockaden:**
  - Die Komplexität des Video-Players bei Orientierungswechseln
  - Unterschiedliches Verhalten auf verschiedenen Geräten (besonders iOS vs. Android)
  - Anpassung des UI-Layouts im Querformat mit begrenztem Platz
  - Integration mit bestehendem Code ohne größere Umstrukturierungen
- 🟢 **Was ich heute gelernt habe:** Orientierungswechsel in Flutter erfordern eine sorgfältige Planung und Berücksichtigung verschiedener Faktoren wie Device-Größen, AspectRatio und SystemUI-Einstellungen. Eine universelle Lösung ist aufgrund der Verschiedenheit der Zielgeräte schwierig zu implementieren.
- 🟢 **Plan für morgen:** Fortsetzung der Arbeit an der Orientierungswechsel-Behandlung. Implementierung einer stabilen Lösung für den Video-Player und die Navigation im Querformat. 

## Tag 16 (16.07.2025)

- 🟢 **Heutige Hauptaufgaben:** 
  - Behebung des EPG-Anzeige-Problems in der Favoriten-Ansicht
  - Debugging der falschen Programminformationen bei Favoriten-Kanälen
  - Sicherstellung korrekter EPG-Datenzuordnung zwischen Favoriten-Liste und Detail-Ansicht
  
- 🟢 **Fortschritt & Ergebnisse:**
  - ✅ **Kritischer Bug gefunden und behoben:** `_loadEpgForSelectedChannel()` verwendete `_channels[_selectedChannelIndex]` statt `_favoriteChannels[_selectedChannelIndex]`
  - ✅ **EPG-Anzeige korrekt implementiert:** Favoriten-Liste zeigt jetzt die richtigen Programminformationen aus `_epgDataMap`
  - ✅ **Debug-System aufgebaut:** Temporäre Debug-Ausgaben implementiert um Kanal-IDs und EPG-Daten zu verfolgen
  - ✅ **Fallback-Logik implementiert:** Bevorzugt aktuelle EPG-Daten, fällt zurück auf `channel.currentShow` wenn nötig
  - ✅ **Vollständige Funktionalität:** "Programm"-Button zeigt jetzt das korrekte EPG für den ausgewählten Favoriten-Kanal

- 🟢 **Herausforderungen & Blockaden:**
  - Index-Mapping-Probleme zwischen verschiedenen Kanal-Listen (`_channels` vs `_favoriteChannels`)
  - Verwirrung über Datenquellen für EPG-Informationen (statische vs. dynamische Daten)
  - Debugging komplexer asynchroner Datenladevorgänge
  - Balance zwischen einfacher und robuster Implementierung

- 🟢 **Was ich heute gelernt habe:**
  - Index-Mapping-Fehler können subtile aber kritische Bugs verursachen - verschiedene Listen mit gleichem Index führen zu falschen Datenzuordnungen
  - Debug-Ausgaben sind essentiell um Datenflüsse in komplexen UI-Zuständen zu verstehen
  - EPG-Daten werden kanalbasiert über IDs zugeordnet und in `_epgDataMap` gespeichert
  - Fallback-Strategien sind wichtig für robuste EPG-Anzeige bei verschiedenen Datenquellen

- 🟢 **Plan für morgen:**
  - Weitere Tests der EPG-Funktionalität in verschiedenen Szenarien
  - Mögliche Optimierungen der EPG-Datenladung
  - Fortsetzung anderer UI/UX-Verbesserungen falls keine weiteren EPG-Probleme auftreten

## Tag 17 (17.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
  - Fullscreen Player Overlay im Favoriten-Screen vervollständigen
  - Overlay-Positionierung innerhalb der Player-Grenzen korrigieren
  - 1:1 Parität mit TV-Screen Overlay erreichen
  - "Beenden" Button aus Fullscreen-Ansicht entfernen

- 🟢 **Fortschritt & Ergebnisse:**
  - ✅ Overlay-Methode `_buildChannelInfoOverlay()` 1:1 vom TV-Screen kopiert
  - ✅ Channel-Logo URL-Logik vereinheitlicht (`http://app.seeyoo.tv${channel.logo!}`)
  - ✅ EPG-Formatierung mit `nextProgram.startTimeFormatted` korrigiert
  - ✅ Overlay-Positionierung mit `currentOffset` innerhalb AnimatedBuilder gelöst
  - ✅ "Beenden" Button erfolgreich entfernt
  - ✅ Overlay bewegt sich jetzt korrekt mit Swipe-Animationen
  - ✅ Overlay bleibt innerhalb der Player-Grenzen

- 🟢 **Herausforderungen & Blockaden:**
  - Overlay war anfangs außerhalb der Player-Grenzen positioniert
  - `currentOffset` Variable war nicht im richtigen Scope verfügbar
  - Musste Overlay von außerhalb des AnimatedBuilder nach innen verlagern

- 🟢 **Was ich heute gelernt habe:**
  - Overlay-Positionierung mit Animation-Offsets erfordert korrekten Scope
  - `left: currentOffset, right: -currentOffset` bewegt Overlay mit Content
  - AnimatedBuilder-Struktur ist kritisch für Swipe-Animation-Integration
  - Positioning-Probleme können durch falsche Widget-Hierarchie entstehen

- 🟢 **Plan für morgen:**
  - Weitere Tests der Overlay-Funktionalität in verschiedenen Szenarien
  - Mögliche Optimierungen der Fade-Animationen
  - Fortsetzung anderer UI/UX-Verbesserungen falls keine weiteren Overlay-Probleme auftreten

## Tag 18 (18.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
  - Abschluss aller geplanten Aufgaben von Tag 17
  - Vorbereitung für Backend-Aufbau auf Amazon AWS
  - Planung für Montag 21.07.25 AWS-Migration

- 🟢 **Fortschritt & Ergebnisse:**
  - ✅ Alle Overlay-Probleme aus Tag 17 vollständig gelöst
  - ✅ Fullscreen Player Overlay funktioniert perfekt in beiden Screens
  - ✅ Swipe-Animation und Channel-Info-Display abgeschlossen
  - ✅ AWS-Infrastruktur-Planung erstellt
  - ✅ Backend-Migration-Strategie entwickelt
  - ✅ Vorbereitungen für AWS-Setup am Montag abgeschlossen

- 🟢 **Herausforderungen & Blockaden:**
  - Keine größeren technischen Blockaden heute
  - AWS-Setup erfordert sorgfältige Planung für nahtlose Migration
  - Koordination zwischen Frontend-Stabilität und Backend-Migration

- 🟢 **Was ich heute gelernt habe:**
  - Erfolgreiche Projektabschlüsse erfordern systematische Herangehensweise
  - AWS-Migration-Planung ist kritisch für reibungslosen Übergang
  - Timing zwischen Frontend-Fertigstellung und Backend-Migration ist wichtig
  - Dokumentation aller Overlay-Fixes hilft bei zukünftigen ähnlichen Problemen

- 🟢 **Plan für morgen:**
  - Samstag: Entspannung und Vorbereitung für kommende Woche
  - Finalisierung der AWS-Setup-Checkliste
  - Review der Backend-Architektur-Dokumentation
  - Vorbereitung für intensiven AWS-Aufbau ab Montag

---
## Aktueller Stand - App Screenshots

<div style="display: flex; justify-content: center; gap: 20px;">
  <img src="pics/Sprint2/01.png" alt="Startbildschirm" width="300">
  <img src="pics/Sprint2/02.png" alt="Login Bildschirm" width="300">
</div>

<div style="display: flex; justify-content: center; gap: 20px;">
  <img src="pics/Sprint2/03.png" alt="Live-TV Menü" width="300">
  <img src="pics/Sprint2/04.png" alt="Live-TV" width="300">
</div>

<div style="display: flex; justify-content: center; gap: 20px;">
  <img src="pics/Sprint2/05.png" alt="Landscape Mode TV" width="600">
</div>

<div style="display: flex; justify-content: center; gap: 20px;">
  <img src="pics/Sprint2/06.png" alt="Favoriten Menü" width="300">
  <img src="pics/Sprint2/07.png" alt="Favoriten-TV" width="300">
</div>

<div style="display: flex; justify-content: center; gap: 20px;">
  <img src="pics/Sprint2/08.png" alt="Landscape Mode Favoriten" width="600">
</div>

<div style="display: flex; justify-content: center; gap: 20px;">
  <img src="pics/Sprint2/09.png" alt="EPG-Programm" width="300">
  <img src="pics/Sprint2/10.png" alt="Kategorien" width="300">
  <img src="pics/Sprint2/11.png" alt="Favoriten Bearbeitungsmodus" width="300">
</div>

<div style="display: flex; justify-content: center; gap: 20px;">
  <img src="pics/Sprint2/12.png" alt="Einstellungen Menü" width="300">
  <img src="pics/Sprint2/13.png" alt="Einstellungen" width="300">
</div>

<div style="display: flex; justify-content: center; gap: 20px;">
  <img src="pics/Sprint2/14.png" alt="Mein Konto Menü" width="300">
  <img src="pics/Sprint2/15.png" alt="Mein Konto" width="300">
</div>

## Tag 19 (19.07.2025)

- 🟢 ** Samstag **

## Tag 20 (20.07.2025)

- 🟢 ** Sonntag **

## Tag 21 (21.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
  - Implementierung und Test der Register/Login-Funktionalität
  - Behebung von Android-Build-Problemen
  - Vorbereitung der App für den Store-Deployment
  - Testen der App auf dem Zielgerät

- 🟢 **Fortschritt & Ergebnisse:**
  - Register/Login-Funktionalität erfolgreich implementiert und getestet
  - User-Authentication-Flow vollständig umgesetzt
  - Android-Build-Probleme erfolgreich behoben:
    - Namespace-Konfiguration für das `auto_orientation`-Plugin (Version 2.3.1) hinzugefügt
    - Namespace-Konfiguration für das `wakelock`-Plugin (Version 0.4.0) hinzugefügt
    - Kotlin-Version im `wakelock`-Plugin von 1.3.50 auf 1.5.20 aktualisiert
  - App läuft erfolgreich auf Android-Geräten

- 🟢 **Herausforderungen & Blockaden:**
  - Fehlende Namespace-Einträge in Plugin-Build-Dateien identifiziert und behoben
  - Veraltete Kotlin-Version im wakelock-Plugin aktualisiert
  - iOS-Build-Fehler identifiziert (Bearbeitung für morgen geplant):
    - `Generated.xcconfig` fehlt in den Suchpfaden
    - Probleme mit `.xcfilelist`-Dateien für Pods-Runner

- 🟢 **Was ich heute gelernt habe:**
  - Neuere Android Gradle Plugins erfordern explizite Namespace-Angaben in build.gradle-Dateien
  - Wie man Plugin-Abhängigkeiten in Flutter manuell aktualisiert
  - Kompatibilitätsanforderungen zwischen Kotlin Gradle Plugin und Android Gradle Plugin

- 🟢 **Plan für morgen:**
  - iOS-Build-Probleme beheben:
    - Flutter-Projekt bereinigen und neu initialisieren
    - CocoaPods aktualisieren und neu installieren
    - Build-Konfiguration im Xcode-Projekt anpassen
  - Vorbereitung für App Store und Play Store Deployment

## Tag 22 (22.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
  - iOS-Build- und Archivierungsprobleme beheben
  - App Store-Einreichung vorbereiten und durchführen
  - Problematische Flutter-Plugins identifizieren und beheben

- 🟢 **Fortschritt & Ergebnisse:**
  - Erfolgreiche Archivierung der iOS-App nach Behebung mehrerer Build-Probleme
  - Erfolgreicher Upload der App zum App Store Connect
  - Komplette Bereinigung und Neuaufbau des iOS-Projekts
  - Entfernung problematischer Plugins und Anpassung des Codes

- 🟢 **Herausforderungen & Blockaden:**
  - Probleme mit mehreren Plugins bei der iOS-Archivierung: device_info_plus, auto_orientation, battery_plus
  - Fehlende oder korrupte XCFileLists und Framework-Integrationen
  - Disk I/O Fehler und Build-Datenbankprobleme in Xcode DerivedData
  - Syntaxfehler nach Code-Refaktorierung

- 🟢 **Was ich heute gelernt habe:**
  - Manche Flutter-Plugins verursachen Probleme nur beim Archivieren, nicht beim normalen Build
  - Vollständige Bereinigung von DerivedData und Flutter-Build-Artefakten kann hartnäckige Build-Probleme lösen
  - Wie man Flutter-App-Code refaktoriert, um ohne bestimmte Plugins zu funktionieren
  - iOS-Archivierungs- und Einreichungsprozess für den App Store

- 🟢 **Plan für morgen:**
  - Backend bei AWS aufsetzen
  - Alternativen für entfernte Plugins evaluieren
  - Testplan für App Store Review vorbereiten

## Tag 23 (23.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
  - Schriftgrößen auf Android-Geräten anpassen (10-12% kleiner als auf iOS)
  - EPG-Daten im Bearbeitungsmodus der Favoriten ausblenden
  - Globale Lösung für plattformspezifische Schriftgrößenanpassung implementieren

- 🟢 **Fortschritt & Ergebnisse:**
  - Erfolgreiche Implementierung einer globalen Lösung für Android-Schriftgrößen (12% kleiner)
  - Verwendung von MediaQuery.textScaleFactor für konsistente Anpassung in der gesamten App
  - EPG-Daten werden nun im Bearbeitungsmodus nicht mehr angezeigt, was die UI übersichtlicher macht
  - Entfernung nicht mehr benötigter Hilfsfunktionen und Dateien (platform_utils.dart)

- 🟢 **Herausforderungen & Blockaden:**
  - Anfänglicher Ansatz mit TextTheme-Anpassung führte zu Null-Check-Fehlern
  - Erste Implementierung zeigte keine sichtbaren Änderungen auf Android-Geräten
  - Musste alternative Lösung mit MediaQuery finden für zuverlässige plattformspezifische Anpassungen

- 🟢 **Was ich heute gelernt habe:**
  - MediaQuery.textScaleFactor ist eine effektivere Methode zur globalen Schriftgrößenanpassung als TextTheme-Modifikationen
  - Bedingte Rendering mit if-Statements in Flutter-Widgets für kontextabhängige UI-Elemente
  - Wie man plattformspezifische Anpassungen global und wartbar implementiert

- 🟢 **Plan für morgen:**
  - Strategie zur Generierung einer eindeutigen Geräte-ID entwickeln, die konsistent bleibt
  - Implementierung einer Methode zur Umwandlung der Geräte-ID in eine MAC-Adresse
  - Sicherstellen, dass die generierte ID über App-Neustarts hinweg konsistent bleibt
  - API-Integration mit der neuen Geräte-ID-Lösung testen

## Tag 24 (24.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
  - Persistente Geräte-Identifikation finalisieren und produktionsreif machen
  - MAC-Adresse standardisieren und API-Integration vervollständigen
  - Account-Screen mit Geräteinformationen erweitern
  - Debug-Code entfernen und Clean Code sicherstellen

- 🟢 **Fortschritt & Ergebnisse:**
  ✅ **Persistente Geräte-Identifikation vollständig implementiert:**
    • Android: Nutzt Android ID (überlebt App-Deinstallation)
    • iOS: Nutzt identifierForVendor (überlebt App-Deinstallation)
    • MAC-Format: Standard XX:XX:XX:XX:XX:XX Format
    • Sichere Speicherung: Keychain/Keystore Integration
  
  ✅ **API-Integration erfolgreich:**
    • Persistente MAC-Adresse wird automatisch bei jedem Login gesendet
    • Server speichert und gibt die neue MAC-Adresse zurück
    • Nahtlose Integration in bestehende Authentifizierung
  
  ✅ **Benutzeroberfläche erweitert:**
    • Account-Screen erweitert mit:
      ◦ vMAC (persistente MAC-Adresse)
      ◦ Platform (Android/iOS)
      ◦ Version (Betriebssystemversion)
      ◦ Gerät (Gerätemodell)
  
  ✅ **Produktionsreife erreicht:**
    • Debug-Screens entfernt
    • Clean Code ohne tote Referenzen
    • Robuste Fallback-Mechanismen implementiert

- 🟢 **Herausforderungen & Blockaden:**
  - Keine größeren technischen Blockaden heute
  - Zeitmanagement: Viele andere Korrekturen und Implementierungen haben Backend-Aufgaben verzögert
  - Priorisierung: Geräte-ID-System hatte Vorrang vor Backend-Entwicklung

- 🟢 **Was ich heute gelernt habe:**
  - Plattformspezifische Geräte-Identifikation ist komplex aber lösbar
  - Sichere Speicherung mit flutter_secure_storage funktioniert zuverlässig
  - MAC-Adress-Generierung aus Device-IDs ist konsistent reproduzierbar
  - Clean Code und Produktionsreife erfordern konsequente Refactoring-Zyklen
  - API-Integration für Geräte-Identifikation läuft nahtlos

- 🟢 **Plan für morgen:**
  - **FOKUS: Backend-Aufgaben angehen!**
  - Backend-Architektur analysieren und verstehen
  - Offene Backend-Issues identifizieren und priorisieren
  - Erste Backend-Implementierungen starten
  - Da in den letzten Tagen viele Frontend-Korrekturen gemacht wurden, ist es Zeit sich dem Backend zu widmen

## Tag 25 (25.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
  - Backend-Architektur analysieren und verstehen
  - Offene Backend-Issues identifizieren und priorisieren
  - Erste Backend-Implementierungen starten

- 🟢 **Fortschritt & Ergebnisse:**
  - Erste Backend-Implementierungen abgeschlossen. 

- 🟢 **Herausforderungen & Blockaden:**
  - Zur zeit noch keine Blockaden oder Ähnliches..

- 🟢 **Was ich heute gelernt habe:**
  - VPC, Subnetze, Sicherheitsgruppen - alles noch mal gelernt.

- 🟢 **Plan für morgen:**
  - am Montag werde ich die Server konfigurieren um eine lauffähige Backend zu bekommen.

## Tag 26 (26.07.2025)

- 🟢 ** Samstag **

## Tag 27 (27.07.2025)

- 🟢 ** Sonntag **

## Tag 28 (28.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
  - Google und Facebook OAuth Login/Registrierung implementieren und testen
  - CocoaPods-Probleme bei iOS Build beheben
  - OAuth-Flow end-to-end testen
  - UI-Verbesserungen im Account-Bereich

- 🟢 **Fortschritt & Ergebnisse:**
  - ✅ **CocoaPods erfolgreich repariert:** Homebrew-Installation und Symlink-Konflikte behoben
  - ✅ **Google OAuth vollständig implementiert:** End-to-end funktionsfähig
    - Google Cloud Console OAuth Client konfiguriert (iOS: 17584210819-m8t06j7kiob4g9ucl1dj4v1mvsteh04b)
    - GoogleService-Info.plist korrekt eingebunden
    - Info.plist mit GIDClientID und REVERSED_CLIENT_ID konfiguriert
    - Automatische User-Erstellung in Billing-API (User ID 155 erstellt)
    - OAuth-Passwort-Generierung und sichere Speicherung
    - Nahtlose Navigation zur Hauptapp nach Login
  - ✅ **Facebook OAuth konfiguriert:** App ID 754547147514361, bereit zum Testen
  - ✅ **OAuth-Service implementiert:** Einheitliche Behandlung von Google/Facebook
  - ✅ **UI-Cleanup durchgeführt:**
    - OAuth-Buttons nur noch im Login-Screen (nicht mehr im Registrierungs-Screen)
    - Geräteinformationen optimiert: "Platform" entfernt, "Version" → "OS Version"
    - Account-Status-Label verbessert: "aktiviert" → "aktiv"
    - E-Mail-Anzeige mit intelligentem Zeilenumbruch nach 20 Zeichen

- 🟢 **Herausforderungen & Blockaden:**
  - **CocoaPods-Installation:** Mehrere Versuche nötig (Ruby gem vs. Homebrew)
  - **Build-Fehler:** User-Model-Parameter (lname/secondName) existierten nicht
  - **Google OAuth Konfiguration:** GIDClientID fehlte in Info.plist
  - **OAuth-Flow-Design:** Entscheidung für MVP-Ansatz ohne Passwort-Option für OAuth-User

- 🟢 **Was ich heute gelernt habe:**
  - **CocoaPods-Troubleshooting:** Symlink-Konflikte und verschiedene Installationsmethoden
  - **iOS OAuth-Konfiguration:** Wichtigkeit von GIDClientID und REVERSED_CLIENT_ID
  - **Flutter OAuth-Integration:** google_sign_in und flutter_facebook_auth Packages
  - **UX-Design:** OAuth-Buttons strategisch nur im Login-Screen platzieren
  - **API-Integration:** Billing-API User-Erstellung mit automatischer Passwort-Generierung

- 🟢 **Plan für morgen:**
  - Backend-Konfiguration und -Optimierung
  - Server-Setup für produktive Umgebung
  - Facebook OAuth end-to-end testen
  - Weitere Backend-Verbesserungen implementieren

## Tag 29 (29.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
  - OAuth-Implementierung debuggen und finalisieren
  - Backend-Integration für bestehende Benutzer verbessern
  - Google Sign-In Konfiguration auf Android optimieren
  - Entscheidung über OAuth-Zukunft treffen
  - Projekt-Cleanup und Code-Bereinigung

- 🟢 **Fortschritt & Ergebnisse:**
  - ✅ **OAuth-Problem gelöst:** Google Sign-In funktioniert jetzt auf Android (fehlende Web Client-ID war das Problem)
  - ✅ **Backend-Logik erweitert:** Bestehende Benutzer werden bei OAuth-Anmeldung korrekt behandelt
  - ✅ **Strategische Entscheidung:** OAuth-Implementierung entfernt aufgrund Billing-API-Limitationen
  - ✅ **Code-Bereinigung:** google-services.json, OAuth-Dependencies und Implementierung entfernt
  - ✅ **UI-Platzhalter:** Google/Facebook Buttons bleiben für zukünftige Implementierung
  - ✅ **Version Update:** App-Version auf 1.0.0+8 erhöht
  - ✅ **Git-Management:** Alle Änderungen committet und gepusht
  - 🔄 **Backend-Arbeit:** Parallel an Backend-Optimierungen gearbeitet

- 🟢 **Herausforderungen & Blockaden:**
  - **Billing-API-Limitierung:** OAuth-Login ohne Passwort noch nicht unterstützt
  - **Architektur-Entscheidung:** Zwischen funktionierender aber unvollständiger OAuth-Lösung und sauberer Implementierung entschieden
  - **Dependency-Management:** Komplexe OAuth-Dependencies erfolgreich entfernt ohne App-Funktionalität zu beeinträchtigen

- 🟢 **Was ich heute gelernt habe:**
  - **Google OAuth Konfiguration:** Web Client-ID ist für Flutter Android OAuth zwingend erforderlich
  - **API-Architektur:** Billing-APIs müssen OAuth-spezifische Endpunkte unterstützen für nahtlose Integration
  - **Code-Hygiene:** Rechtzeitige Entfernung nicht funktionierender Features ist besser als Workarounds
  - **Git-Workflow:** Strukturierte Commits mit aussagekräftigen Messages für komplexe Änderungen
  - **Strategische Entwicklung:** Manchmal ist "weniger" mehr - fokussierte Features statt halbfertiger Implementierungen

- 🟢 **Plan für morgen:**
  - **Backend weiterentwickeln:** Server-Optimierungen und API-Verbesserungen
  - **Projekt-Präsentation erstellen:** Umfassende Dokumentation der App-Features und Architektur
  - **Produktions-Vorbereitung:** App für finale Tests und Deployment vorbereiten
  - **Feature-Dokumentation:** Vollständige Übersicht aller implementierten Funktionen
  - **OAuth-Roadmap:** Planung für zukünftige OAuth-Integration wenn Billing-API bereit ist

## Tag 30 (30.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
  - **Backend-Entwicklung:** Server-Optimierungen und API-Verbesserungen vorantreiben
  - **Projektpräsentation:** Umfassende Dokumentation der App-Features und Architektur erstellen
  - **vMAC-Kollisionsproblem:** Kritischen Bug bei Android-Geräte-Identifikation lösen
  - **Code-Qualität:** Robuste Geräte-ID-Generierung implementieren

- 🟢 **Fortschritt & Ergebnisse:**
  - **✅ vMAC-Kollisionsproblem vollständig gelöst:**
    - Root Cause identifiziert: `androidInfo.id` aus device_info_plus ist nicht die echte Android ID
    - android_id Package (v0.3.6) hinzugefügt für echte Android ID
    - DeviceIdService aktualisiert: `AndroidId().getId()` statt Build-Fingerprint
    - Erfolgreich getestet: Neue vMAC F6:85:E2:1B:B2:19 generiert
    - Vollständige API-Integration funktioniert (User ID 165, Portal ID 91)
  - **Backend-Architektur:** Weitere Optimierungen und Strukturverbesserungen
  - **Projektpräsentation:** Dokumentation der implementierten Features begonnen
  - **Code-Hygiene:** Imports korrigiert, dart:math hinzugefügt

- 🟢 **Herausforderungen & Blockaden:**
  - **vMAC-Kollisionen bei identischen Android-Geräten:** Zwei verschiedene Geräte generierten die gleiche vMAC-Adresse
  - **device_info_plus Limitation:** `androidInfo.id` gibt Build-Fingerprint statt echter Android ID zurück
  - **Debugging-Aufwand:** Recherche und Analyse der Android ID Generierung nötig
  - **Import-Fehler:** Missing dart:math Import führte zu Build-Fehlern

- 🟢 **Was ich heute gelernt habe:**
  - **Android ID Fallstricke:** device_info_plus `id` Feld ist nicht die echte Android ID
  - **Kollisionsrisiken:** Identische Gerätemodelle können gleiche Build-Fingerprints haben
  - **Deterministische vs. Zufällige IDs:** Wichtigkeit konsistenter Geräte-Identifikation
  - **Package-Recherche:** android_id Package als zuverlässige Alternative
  - **Debugging-Strategien:** Systematische Analyse von ID-Generierungsproblemen
  - **API-Integration:** Robuste Geräte-ID-Übertragung an Backend-Services

- 🟢 **Plan für morgen:**
  - **Backend weiterentwickeln:** Server-Optimierungen und API-Verbesserungen fortsetzen
  - **vMAC-Tests abschließen:** Zweites Android-Gerät testen für finale Kollisions-Bestätigung
  - **Projektpräsentation:** Dokumentation vervollständigen
  - **Code-Review:** Weitere Backend-Komponenten analysieren und optimieren
  - **Deployment-Vorbereitung:** App für Produktionsumgebung vorbereiten

## Tag 31 (31.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
  - **Abschlusspräsentation fertigstellen:** Präsentation für das SEEYOO App Projekt erstellen
  - **Backend-Setup:** Vollständige Backend-Infrastruktur aufsetzen und konfigurieren
  - **Präsentationsvorbereitung:** Finale Vorbereitungen für morgigen Präsentationstag

- 🟢 **Fortschritt & Ergebnisse:**
  - **✅ Präsentation abgeschlossen:** "Abschlussprojekt SEEYOO App.pdf" fertiggestellt und in `pics/Präsentation/` gespeichert
  - **✅ Backend vollständig aufgesetzt:** Komplette Backend-Infrastruktur implementiert und funktionsfähig
  - **✅ Projektabschluss erreicht:** Alle wesentlichen Komponenten der SEEYOO TV App sind implementiert und getestet
  - **✅ Präsentationsreife:** App und Dokumentation sind bereit für die morgige Präsentation

- 🟢 **Herausforderungen & Blockaden:**
  - **Backend-Komplexität:** Aufsetzen der gesamten Backend-Infrastruktur war zeitaufwendig aber erfolgreich
  - **Präsentationsstruktur:** Alle wichtigen Projektaspekte in einer kohärenten Präsentation zusammenzufassen

- 🟢 **Was ich heute gelernt habe:**
  - **Projektabschluss-Management:** Wichtigkeit einer strukturierten Präsentationsvorbereitung
  - **Backend-Deployment:** Praktische Erfahrungen beim Aufsetzen einer produktionsreifen Backend-Infrastruktur
  - **Dokumentation:** Wert einer kontinuierlichen Projektdokumentation für die finale Präsentation

- 🟢 **Plan für morgen:**
  - **🎯 PRÄSENTATIONSTAG! (01.08.2025)**
  - **Finale Präsentation:** SEEYOO App Abschlussprojekt präsentieren
  - **Demo vorbereiten:** Live-Demo der App-Funktionalitäten
  - **Q&A Session:** Fragen zu technischen Implementierungen und Architektur-Entscheidungen beantworten
  - **Projektabschluss:** Erfolgreichen Abschluss des SEEYOO TV App Projekts feiern! 🎉
