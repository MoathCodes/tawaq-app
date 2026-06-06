# 🚀 azkar

A powerful and easy-to-use Flutter library that helps developers to fetch all Islamic Azkar.

---

## 📌 Table of Contents

* About
* Features
* Installation
* Usage
* API Reference
* Example
* Project Structure
* License
* Author

---

## 📖 About

`azkar` is a reusable package built with **Flutter** that simplifies Islamic Azkar.

It is designed to be:

* ⚡ Fast
* 🎯 Easy to use
* 🧩 Highly customizable
* 📱 Cross-platform (Android, iOS, Web, Desktop, Linux, macOS)

---

## ✨ Features

* ✔️ Introduction about Hisn Al-Muslim
* ✔️ Translated Azkar in 5 languages
* ✔️ Clean and modular architecture

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml id="a1b2c3"
dependencies:
  azkar: ^0.0.4
```

Then run:

```bash id="d4e5f6"
flutter pub get azkar
```

---

## 🚀 Usage

Import the package:

```dart id="g7h8i9"
import 'package:azkar/azkar.dart';
```

### Basic Example

```dart id="j1k2l3"
Azkar.getCategories(language)
```

## 🧩 API Reference

### Enum AzkarLang

* arabic
* english
* farsi
* kurdish
* russian

### Azkar.getAbout(AzkarLang language)

Returns AboutAzkar with information about Hisn Al Muslim.

### Azkar.getCategories(AzkarLang language)

Returns List with all categories by selected language.

### Azkar.getChapters(AzkarLang language)

Returns List with all chapters by selected language.

### Azkar.getChaptersByCategory(AzkarLang language, int categoryID)

Returns List of chapters from a certain category by selected language.

### Azkar.getItemsByChapter(AzkarLang language, int chapterID)

Returns List of items from a certain chapter by selected language.

---

## 📂 Project Structure

```id="p7q8r9"
lib/
 ├── azkar.dart
 ├── src/
 │   ├── type.dart
 │   ├── data/
 │       ├── about.dart
 │       ├── categories.dart
 │       ├── chapters.dart
 │       ├── items.dart
 
```

---

## 📄 License

This project is licensed under the MIT License.

---

## 👨‍💻 Author

**Aburas**
GitHub: https://github.com/ebrahimAburas/

