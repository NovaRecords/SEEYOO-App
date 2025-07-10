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

<div style="display: flex; justify-content: space-between;">
  <img src="pics/Start-screens.png" alt="Screenshot Startscreen" width="300">
  <img src="pics/login-screens.png" alt="Screenshot Login" width="300">
</div>

<div style="display: flex; justify-content: space-between;">
  <img src="pics/menu-screen-tv.png" alt="Screenshot Menü TV" width="300">
  <img src="pics/tv-screen06.png" alt="Screenshot TV" width="300">
</div>

<div style="display: flex; justify-content: space-between;">
  <img src="pics/EPG-screen04.png" alt="Screenshot EPG" width="300">
  <img src="pics/kat-screen04.png" alt="Screenshot Kategorien" width="300">
</div>

<div style="display: flex; justify-content: space-between;">
  <img src="pics/menu-screen-fav.png" alt="Screenshot Menü Favoriten" width="300">
  <img src="pics/fav-screen01.png" alt="Screenshot Favoriten1" width="300">
  <img src="pics/fav-screen02.png" alt="Screenshot Favoriten2" width="300">
</div>

<div style="display: flex; justify-content: space-between;">
  <img src="pics/menu-screen-settings.png" alt="Screenshot Menü Einstellungen" width="300">
  <img src="pics/settings-screen01.png" alt="Screenshot Einstellungen1" width="300">
</div>

<div style="display: flex; justify-content: space-between;">
  <img src="pics/menu-screen-account.png" alt="Screenshot Menü Mein Konto" width="300">
  <img src="pics/konto-screen01.png" alt="Screenshot Mein Konto1" width="300">
</div>

## Tag 11 (11.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**
- 🟢 **Plan für morgen:**

## Tag 12 (12.07.2025)

- 🟢 ** Samstag **

## Tag 13 (13.07.2025)

- 🟢 ** Sonntag **

## Tag 14 (14.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**
- 🟢 **Plan für morgen:**

## Tag 15 (15.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**
- 🟢 **Plan für morgen:**

## Tag 16 (16.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**
- 🟢 **Plan für morgen:**

## Tag 17 (17.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**
- 🟢 **Plan für morgen:**

## Tag 18 (18.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**
- 🟢 **Plan für morgen:**

## Tag 19 (19.07.2025)

- 🟢 ** Samstag **

## Tag 20 (20.07.2025)

- 🟢 ** Sonntag **

## Tag 21 (21.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**
- 🟢 **Plan für morgen:**

## Tag 22 (22.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**
- 🟢 **Plan für morgen:**

## Tag 23 (23.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**
- 🟢 **Plan für morgen:**

## Tag 24 (24.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**
- 🟢 **Plan für morgen:**

## Tag 25 (25.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**
- 🟢 **Plan für morgen:**

## Tag 26 (26.07.2025)

- 🟢 ** Samstag **

## Tag 27 (27.07.2025)

- 🟢 ** Sonntag **

## Tag 27 (27.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**
- 🟢 **Plan für morgen:**

## Tag 28 (28.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**
- 🟢 **Plan für morgen:**

## Tag 29 (29.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**
- 🟢 **Plan für morgen:**

## Tag 30 (30.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**
- 🟢 **Plan für morgen:**

## Tag 31 (31.07.2025)

- 🟢 **Heutige Hauptaufgaben:**
- 🟢 **Fortschritt & Ergebnisse:**
- 🟢 **Herausforderungen & Blockaden:**
- 🟢 **Was ich heute gelernt habe:**

