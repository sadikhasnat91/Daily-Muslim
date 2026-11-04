# 🕌 Muslim Daily

> **Your Daily Islamic Companion**

Muslim Daily is a modern, premium, and user-friendly Islamic mobile application built with **Flutter**. It is designed to provide Muslims with essential daily Islamic tools in one beautiful and convenient application.

The app combines **accurate location-based prayer times, Quran, Azan notifications, Qibla Finder, Islamic Calendar, Duas, Tasbih, prayer tracking, and personalized Islamic content** into a single experience.

---

## ✨ Features

### 🕌 Prayer Times

* Accurate daily prayer times
* Location and timezone-based calculations
* Fajr
* Sunrise
* Dhuhr
* Asr
* Maghrib
* Isha
* Current prayer detection
* Next prayer countdown
* Prayer start and end times
* Multiple calculation methods
* Madhhab support
* Automatic daily updates
* Country and city selection

### 🔔 Azan Notifications

* Automatic prayer-time notifications
* Azan audio support
* Fajr, Dhuhr, Asr, Maghrib & Isha notifications
* Enable/disable individual prayers
* Vibration support
* Notification preferences
* Automatic rescheduling when location or prayer settings change

### 📖 Quran

* Complete 114 Surahs
* Arabic Quran text
* Bangla translation
* English translation
* Surah search
* Continue Reading
* Last Read
* Bookmarks
* Favorite Ayahs
* Reading progress
* Audio recitation support
* Ayah-level navigation

### 🧭 Qibla Finder

* Real-time Qibla direction
* Device compass integration
* GPS-based location
* Distance to the Kaaba
* Compass calibration support
* Smooth animated compass

### 📅 Islamic Calendar

* Gregorian calendar
* Hijri calendar
* Monthly calendar view
* Year navigation
* Islamic events
* Ramadan
* Eid-ul-Fitr
* Eid-ul-Adha
* Laylatul Qadr
* Shab-e-Barat
* Ashura
* Islamic New Year
* Isra and Mi'raj
* Mawlid

### 🤲 Duas

Organized Islamic duas by category:

* Morning & Evening
* Before Sleep
* Travel
* Eating
* Prayer
* Parents
* Forgiveness
* Health
* Protection
* Daily Life

### 📿 Tasbih

* Digital Tasbih counter
* Custom target
* Progress tracking
* Daily history
* Reset functionality
* Vibration feedback

### 👤 Profile

* User name
* Profile image
* Country
* Personal settings
* Prayer statistics
* Quran reading statistics
* Daily streak
* Preferences

### 📊 Prayer & Reading Tracking

* Daily prayer progress
* Prayer history
* Quran reading progress
* Reading streak
* Bookmarks
* Favorite Ayahs
* Personal activity tracking

---

## 🎨 Design

Muslim Daily focuses heavily on modern UI/UX.

### Design Principles

* Premium minimalism
* Modern Islamic aesthetic
* Material 3
* Dark mode
* Light mode
* Glassmorphism
* Smooth animations
* Elegant typography
* Responsive layouts
* Accessibility-friendly components
* Consistent design system

The goal is to create an Islamic application that feels **modern, peaceful, elegant, and easy to use**, rather than following traditional or outdated Islamic app designs.

---

## 🛠️ Tech Stack

| Technology              | Purpose                                |
| ----------------------- | -------------------------------------- |
| **Flutter**             | Cross-platform application development |
| **Dart**                | Programming language                   |
| **Material 3**          | UI framework                           |
| **Hive**                | Local data persistence                 |
| **REST APIs**           | Dynamic data                           |
| **GPS / Location**      | Prayer & Qibla calculations            |
| **Device Compass**      | Qibla detection                        |
| **Local Notifications** | Azan & prayer reminders                |

---

## 🏗️ Architecture

The application follows a scalable architecture designed for long-term development.

```text
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── utils/
│   └── widgets/
│
├── config/
│
├── models/
│
├── services/
│   ├── prayer/
│   ├── quran/
│   ├── notification/
│   ├── location/
│   └── qibla/
│
├── repository/
│
├── features/
│   ├── home/
│   ├── prayer/
│   ├── quran/
│   ├── duas/
│   ├── qibla/
│   ├── calendar/
│   ├── tasbih/
│   └── profile/
│
├── routes/
│
├── theme/
│
└── main.dart
```

---

## 🌍 Location & Timezone

Muslim Daily is designed to calculate prayer times according to the user's selected location.

The application considers:

```text
Country
   ↓
City / Location
   ↓
Latitude & Longitude
   ↓
Timezone
   ↓
Calculation Method
   ↓
Madhhab
   ↓
Prayer Times
```

Prayer times are dynamically calculated based on the selected date and location rather than relying on fixed values.

This allows prayer times to change naturally throughout the year according to seasonal solar changes.

---

## 📖 Quran Data

The Quran module is designed around stable Surah and Ayah identifiers.

```text
001 → Al-Fatihah
002 → Al-Baqarah
003 → Aal-E-Imran
...
114 → An-Nas
```

Quran content is intended to be sourced from reliable and verified Quran datasets.

The application should never generate or modify Quranic Arabic text automatically.

---

## 🔐 Privacy

Muslim Daily is designed with a privacy-first approach.

Personal preferences such as:

* Profile information
* Selected location
* Prayer settings
* Bookmarks
* Reading progress
* Tasbih history

can be stored locally on the device where possible.

Location permission is only required for features that depend on location, such as accurate prayer calculations and Qibla detection.

---

## 🚀 Getting Started

### Prerequisites

Make sure you have installed:

* Flutter SDK
* Dart SDK
* Android Studio or Android SDK
* VS Code or another preferred IDE
* Git

Check Flutter installation:

```bash
flutter doctor
```

---

### Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/muslim_daily.git
```

Navigate to the project:

```bash
cd muslim_daily
```

Install dependencies:

```bash
flutter pub get
```

---

### Run the Application

For development:

```bash
flutter run
```

For Chrome:

```bash
flutter run -d chrome
```

For Android:

```bash
flutter run -d android
```

---

## ⚙️ Configuration

If the project requires API keys or external services, keep credentials outside the source code.

Use environment configuration or secure build-time variables.

**Never commit API keys, secret tokens, or private credentials to GitHub.**

Example:

```text
.env
```

should be included in `.gitignore` when applicable.

---

## 🧪 Testing

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Build Android release:

```bash
flutter build apk --release
```

Build App Bundle:

```bash
flutter build appbundle --release
```

---

## 📱 Supported Platforms

| Platform | Status                |
| -------- | --------------------- |
| Android  | 🚧 Active Development |
| iOS      | 🚧 Planned            |
| Web      | 🚧 Development        |
| Windows  | 🔮 Future             |
| macOS    | 🔮 Future             |

---

## 🗺️ Roadmap

### Phase 1 — Core

* [x] Modern UI
* [x] Navigation
* [x] Prayer screen
* [x] Quran interface
* [x] Profile
* [ ] Complete prayer calculation
* [ ] Complete Quran dataset
* [ ] Location system

### Phase 2 — Islamic Tools

* [ ] Qibla Finder
* [ ] Azan notifications
* [ ] Islamic Calendar
* [ ] Duas
* [ ] Tasbih
* [ ] Prayer tracking

### Phase 3 — Personalization

* [ ] User profile
* [ ] Reading streak
* [ ] Prayer statistics
* [ ] Quran bookmarks
* [ ] Favorite Ayahs
* [ ] Custom notification settings

### Phase 4 — Advanced Features

* [ ] Quran audio downloads
* [ ] Multiple reciters
* [ ] Tafsir
* [ ] Multiple languages
* [ ] Mosque Finder
* [ ] Zakat Calculator
* [ ] Ramadan Mode
* [ ] Advanced Quran search

---

## 🎯 Project Goals

Muslim Daily aims to provide a simple and reliable digital companion for everyday Islamic practices.

The primary goals are:

* Make essential Islamic tools accessible in one application
* Provide accurate location-based prayer information
* Encourage regular Quran reading
* Make Qibla detection simple
* Provide timely prayer reminders
* Create a peaceful and distraction-free Islamic experience

---

## 🤝 Contributing

Contributions are welcome.

If you would like to contribute:

1. Fork the repository
2. Create a feature branch

```bash
git checkout -b feature/your-feature
```

3. Make your changes
4. Test the application
5. Commit your changes

```bash
git commit -m "Add your feature"
```

6. Push the branch

```bash
git push origin feature/your-feature
```

7. Open a Pull Request

---

## ⚠️ Important Note

Islamic information must be handled carefully.

Prayer calculations, Quranic text, translations, Hadith, Duas, and Islamic calendar information should be obtained from reliable and verified sources.

Do not use AI-generated Quranic text or unverified religious information as authoritative content.

---

## 📄 License

This project is currently under development.

The license and terms of use will be defined before the first public release.

---

## ❤️ Acknowledgements

Built with ❤️ using Flutter.

Muslim Daily is created with the goal of combining modern technology and thoughtful Islamic tools into one simple daily companion.

---

### 🕌 Muslim Daily

**Your Daily Islamic Companion.**
