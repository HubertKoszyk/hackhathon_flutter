# ♿ NavAble — Dostępny Kraków bez barier
> **Inteligentna nawigacja miejska oparta na AI (Gemini 3.8 Flash), uwzględniająca profile mobilności oraz standardy dostępności cyfrowej WCAG 2.2 AA.**

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![WCAG](https://img.shields.io/badge/WCAG-2.2%20AA-success)](https://www.w3.org/WAI/standards-guidelines/wcag/)
[![Gemini AI](https://img.shields.io/badge/AI-Gemini%203.8%20Flash-8E75C2?logo=google&logoColor=white)](https://ai.google.dev)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 💡 O projekcie

Tradycyjne nawigacje (np. Google Maps) prowadzą użytkowników najkrótszą trasą, całkowicie ignorując schody, brak ramp, wysokie krawężniki czy zabytkowy bruk. Dla osoby na wózku, rodzica z wózkiem dziecięcym czy seniora oznacza to nagłe zderzenie z barierą nie do pokonania.

**NavAble** rozwiązuje ten problem. Aplikacja analizuje infrastrukturę pieszą Krakowa, identyfikuje bariery architektoniczne i wyznacza **bezpieczne, w 100% dostępne trasy alternatywne (Bypass)**, wspierając się multimodalnym modelem **Google Gemini 3.8 Flash** oraz rozkładami jazdy **GTFS MPK Kraków**.

---

## ✨ Kluczowe funkcjonalności

### 1. 🦽 Trzy spersonalizowane profile mobilności
* **Wózek inwalidzki:** eliminuje schody, wymaga krawężników 0–1 cm, ramp o nachyleniu <6% oraz unika zabytkowych "kocich łbów".
* **Senior / Osoba o kuli:** unika śliskich nawierzchni i stromych zejść, wyszukuje ławki i spoczniki co 100–150 m.
* **Wózek dziecięcy:** 0 schodów (brak konieczności dźwigania wózka), gładkie nawierzchnie chroniące dziecko przed wstrząsami.

### 2. 🧠 Hybrydowy silnik wyznaczania tras (OSRM + Geometria + Gemini AI)
* **Krok 1 (OSRM):** pobranie surowej geometrii i odległości trasy pieszej.
* **Krok 2 (Silnik geometryczny Krakowa):** analiza korytarza trasy i detekcja kolizji ze znanymi barierami (tunel Lubicz, Krater Ronda Mogilskiego, Wzgórze Wawelskie, Kładka Bernatka, Sukiennice, torowiska).
* **Krok 3 (Gemini 3.8 Flash AI):** automatyczny audyt dostępności, szacowanie liczby schodów, ocena nawierzchni i generowanie werdyktu dostosowanego do profilu.
* **Krok 4 (Sinusoidalny Bypass):** generowanie łagodnego obejścia omijającego przeszkodę o certyfikowane rampy i zjazdy.
* **Krok 5 (GTFS MPK Kraków):** weryfikacja alternatywnych połączeń niskopodłogowymi tramwajami i autobusami.

### 3. 👁️ Dostępność cyfrowa (WCAG 2.2 AA)
* **Tekstowa alternatywa dla mapy:** pełny widok tekstowy z nawigacją krok po kroku dla osób niewidomych korzystających z czytników ekranu (TalkBack / VoiceOver).
* **Tryb wysokiego kontrastu (High Contrast):** zgodny z wymogami kontrastu AAA/AA (żółto-czarny / wysoki kontrast).
* **Dynamiczne skalowanie tekstu:** odporność na powiększenie czcionki (135%+ Text Scale) bez błędów typu overflow.
* **Semantyka i czytniki ekranu:** etykiety semantyczne (`Semantics`) dla wszystkich elementów interaktywnych.

### 4. 📍 Baza Dostępnego Krakowa
* Katalog dostępnych obiektów użyteczności publicznej (muzea, urzędy, toalety).
* Parkingi z miejscami dla osób z niepełnosprawnościami ("koperty") z nawigacją bezpośrednio od zaparkowanego auta.
* Realne audyty ze zdjęciami barier i obejść.

---

## 🚀 Szybki start (Instrukcja dla Jury)

### Wymagania wstępne
* Zainstalowany **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (wersja ≥ 3.12.0)
* Android Studio (emulator Androida) lub fizyczne urządzenie z włączonym debugowaniem USB

### Krok po kroku

1. **Sklonuj repozytorium:**
   ```bash
   git clone https://github.com/HubertKoszyk/hackhathon_flutter.git
   cd hackhathon_flutter
   ```

2. **Pobierz zależności:**
   ```bash
   flutter pub get
   ```

3. **Uruchom aplikację:**
   ```bash
   flutter run
   ```

### 🔑 Opcjonalnie: Klucz Gemini API
> Aplikacja posiada **pełny silnik offline/fallback** z topologią Krakowa, więc działa **od razu bez podawania klucza**.

Aby aktywować pełną analizę AI Gemini 3.8 Flash, uruchom z parametrem:
```bash
flutter run --dart-define=GEMINI_API_KEY=TWÓJ_KLUCZ_API
```
*(Klucz można również wkleić bezpośrednio w aplikacji: ikona ⚙️ Ustawienia → Klucz API Gemini).*

### 📦 Gotowa paczka APK (Release)
```bash
flutter build apk --release
```
Plik wynikowy znajdziesz w: `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🛠️ Architektura i technologie

* **Framework:** [Flutter](https://flutter.dev) (Dart)
* **Zarządzanie stanem:** [Provider](https://pub.dev/packages/provider) (`AppState`)
* **Mapy:** [flutter_map](https://pub.dev/packages/flutter_map) + [latlong2](https://pub.dev/packages/latlong2) (OpenStreetMap)
* **Routing:** [OSRM](https://project-osrm.org/) API + własny krakowski silnik geometryczny bypassu
* **AI:** Google Gemini 3.8 Flash (`google_generative_ai` / REST API)
* **Komunikacja miejska:** Moduł GTFS Transit Service (Kraków MPK)
* **Lokalizacja:** [geolocator](https://pub.dev/packages/geolocator)
* **Wielojęzyczność:** PL, EN, UK (`AppTranslations`)

---

## 🧪 Testy

Projekt posiada zestaw testów jednostkowych oraz testów dostępności WCAG:
```bash
flutter test
```

---

## 👥 Zespół

Projekt stworzony z pasją podczas hackathonu na rzecz bardziej dostępnego i otwartego Krakowa. ❤️
