# OAuth Setup Anleitung - Google & Facebook Login

Diese Anleitung erklärt, wie du Google Sign-In und Facebook Login für die SEEYOO TV App einrichtest.

## 🔧 Aktuelle Implementation

✅ **Bereits implementiert:**
- OAuth Service (`lib/services/oauth_service.dart`)
- StorageService erweitert für OAuth-Passwörter
- AuthScreen mit Google/Facebook Buttons
- Android/iOS Konfigurationsdateien vorbereitet

❌ **Noch zu konfigurieren:**
- Google Cloud Console Projekt
- Facebook Developer App
- Konfigurationsdateien mit echten Werten ersetzen

---

## 📱 Google Sign-In Setup

### 1. Google Cloud Console Projekt erstellen

1. Gehe zu [Google Cloud Console](https://console.cloud.google.com/)
2. Erstelle ein neues Projekt oder wähle ein bestehendes aus
3. Aktiviere die **Google Sign-In API**

### 2. OAuth 2.0 Client IDs erstellen

**Für Android:**
1. Gehe zu "APIs & Services" > "Credentials"
2. Klicke "Create Credentials" > "OAuth 2.0 Client ID"
3. Wähle "Android" als Application type
4. **Package name:** `com.seeyoo.seeyoo_app`
5. **SHA-1 Certificate fingerprint:** Führe aus:
   ```bash
   # Debug Keystore (für Entwicklung)
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Release Keystore (für Production)
   keytool -list -v -keystore /path/to/your/release.keystore -alias your-alias
   ```

**Für iOS:**
1. Erstelle eine weitere OAuth 2.0 Client ID
2. Wähle "iOS" als Application type
3. **Bundle ID:** `com.seeyoo.seeyooApp`

**Für Web (erforderlich):**
1. Erstelle eine dritte OAuth 2.0 Client ID
2. Wähle "Web application" als Application type

### 3. Konfigurationsdateien herunterladen

**Android:**
1. Lade `google-services.json` herunter
2. Ersetze `/android/app/google-services.json.template` mit der echten Datei
3. Benenne sie um zu `google-services.json`

**iOS:**
1. Lade `GoogleService-Info.plist` herunter
2. Ersetze `/ios/Runner/GoogleService-Info.plist.template` mit der echten Datei
3. Benenne sie um zu `GoogleService-Info.plist`
4. Füge sie in Xcode zum Runner-Target hinzu

### 4. iOS URL Scheme aktualisieren

1. Öffne die heruntergeladene `GoogleService-Info.plist`
2. Kopiere den Wert von `REVERSED_CLIENT_ID`
3. Ersetze in `/ios/Runner/Info.plist`:
   ```xml
   <string>YOUR_REVERSED_CLIENT_ID_HERE</string>
   ```
   mit dem echten Wert, z.B.:
   ```xml
   <string>com.googleusercontent.apps.123456789-abcdef</string>
   ```

---

## 📘 Facebook Login Setup

### 1. Facebook Developer App erstellen

1. Gehe zu [Facebook Developers](https://developers.facebook.com/)
2. Klicke "My Apps" > "Create App"
3. Wähle "Consumer" als App-Typ
4. Gib App-Name ein: "SEEYOO TV"
5. Notiere dir die **App ID** und **Client Token**

### 2. Facebook Login konfigurieren

1. Gehe zu "Add a Product" > "Facebook Login"
2. Wähle "Settings" unter Facebook Login
3. Füge folgende **Valid OAuth Redirect URIs** hinzu:
   - `fbYOUR_APP_ID://authorize` (ersetze YOUR_APP_ID)

### 3. Platform Settings

**Android Platform hinzufügen:**
1. Gehe zu "Settings" > "Basic"
2. Klicke "+ Add Platform" > "Android"
3. **Package Name:** `com.seeyoo.seeyoo_app`
4. **Class Name:** `com.seeyoo.seeyoo_app.MainActivity`
5. **Key Hashes:** Führe aus:
   ```bash
   # Debug Key Hash
   keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
   
   # Release Key Hash (für Production)
   keytool -exportcert -alias your-alias -keystore /path/to/your/release.keystore | openssl sha1 -binary | openssl base64
   ```

**iOS Platform hinzufügen:**
1. Klicke "+ Add Platform" > "iOS"
2. **Bundle ID:** `com.seeyoo.seeyooApp`

### 4. Konfigurationsdateien aktualisieren

**Android:**
1. Ersetze in `/android/app/src/main/res/values/strings.xml`:
   ```xml
   <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
   <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
   <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
   ```

**iOS:**
1. Ersetze in `/ios/Runner/Info.plist`:
   ```xml
   <string>YOUR_FACEBOOK_APP_ID</string>
   <string>fbYOUR_FACEBOOK_APP_ID</string>
   ```

---

## 🧪 Testing

### 1. Build und Test

```bash
# Dependencies installieren
flutter pub get

# Android Build
flutter build apk --debug

# iOS Build
flutter build ios --debug
```

### 2. Test-Accounts

**Google:** Verwende deine normale Google-E-Mail für Tests

**Facebook:** 
1. Gehe zu "Roles" > "Test Users" in der Facebook App
2. Erstelle Test-User für verschiedene Szenarien

### 3. Debug-Logs

Die App gibt detaillierte Logs aus:
- `OAuth: Starting Google Sign-In`
- `OAuth: User created successfully in billing system`
- `AuthScreen: Google OAuth successful`

---

## 🚨 Wichtige Hinweise

### Sicherheit
- **Niemals** die `google-services.json` oder echte App-IDs in Git committen
- Verwende separate Apps für Development/Production
- Rotiere Client Tokens regelmäßig

### Production Deployment
- Erstelle separate Google/Facebook Apps für Production
- Verwende Release Key Hashes/Certificates
- Teste OAuth-Flow auf echten Geräten

### Troubleshooting
- **Google Sign-In Fehler:** Prüfe SHA-1 Fingerprints
- **Facebook Login Fehler:** Prüfe Key Hashes und Bundle IDs
- **iOS Build Fehler:** Stelle sicher, dass GoogleService-Info.plist in Xcode hinzugefügt ist

---

## 📋 Checkliste

### Google Sign-In
- [ ] Google Cloud Console Projekt erstellt
- [ ] OAuth 2.0 Client IDs für Android/iOS/Web erstellt
- [ ] SHA-1 Fingerprints hinzugefügt
- [ ] `google-services.json` heruntergeladen und platziert
- [ ] `GoogleService-Info.plist` heruntergeladen und platziert
- [ ] iOS URL Scheme mit REVERSED_CLIENT_ID aktualisiert

### Facebook Login
- [ ] Facebook Developer App erstellt
- [ ] Facebook Login Product hinzugefügt
- [ ] Android Platform mit Package Name und Key Hash konfiguriert
- [ ] iOS Platform mit Bundle ID konfiguriert
- [ ] `strings.xml` mit Facebook App ID aktualisiert
- [ ] iOS `Info.plist` mit Facebook App ID aktualisiert

### Testing
- [ ] `flutter pub get` ausgeführt
- [ ] Android Build erfolgreich
- [ ] iOS Build erfolgreich
- [ ] Google Sign-In auf Gerät getestet
- [ ] Facebook Login auf Gerät getestet
- [ ] Registrierung neuer User getestet
- [ ] Anmeldung bestehender User getestet

---

**Nach der Konfiguration sollten beide OAuth-Provider funktionsfähig sein! 🎉**
