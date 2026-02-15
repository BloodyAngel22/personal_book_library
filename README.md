# Personal Book Library

A comprehensive Flutter application for managing your personal book collection with barcode scanning, reading progress tracking, and statistics.

## Features

### 📚 Library Management
- **Three-Tab Organization**: Books organized by "To Read", "Reading", and "Finished" status
- **Manual Entry**: Add books manually with title, author, pages, and optional details
- **ISBN Scanning**: Scan book barcodes to automatically fetch book information
- **Book Search**: Search for books online using Google Books API and Open Library API

### 📖 Reading Progress
- **Progress Tracking**: Update current page with slider or manual input
- **Visual Progress Bars**: Beautiful gradient progress indicators
- **Automatic Status Updates**: Status changes automatically based on progress

### 📊 Statistics & Analytics
- **Reading Speed**: Calculate average pages read per day
- **Estimated Finish Date**: Based on reading speed calculations
- **Days Remaining**: Estimated days to complete the current book
- **Library Statistics**: Total books, pages read, and completion rate

### 🎨 UI/UX
- **Material 3 Dark Theme**: Modern, sleek dark interface
- **Hero Animations**: Smooth transitions between screens
- **Shimmer Loading**: Elegant loading states
- **Cached Network Images**: Fast image loading with offline support
- **Responsive Design**: Adapts to different screen sizes

## Technical Stack

| Component | Technology |
|-----------|------------|
| Language | Dart |
| Framework | Flutter (Material 3) |
| State Management | Cubit (flutter_bloc) |
| Database | SQLite (sqflite) |
| Navigation | auto_route |
| Networking | Dio |
| Scanner | mobile_scanner |
| Image Loading | cached_network_image |
| Shimmer Effects | shimmer |

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart      # App-wide constants
│   ├── database/
│   │   └── database_helper.dart    # SQLite database operations
│   ├── router/
│   │   ├── app_router.dart         # Route configuration
│   │   └── app_router.gr.dart      # Generated routes
│   └── theme/
│       └── app_theme.dart          # Material 3 dark theme
├── data/
│   ├── models/
│   │   └── book_model.dart         # Book data model
│   ├── providers/
│   │   └── book_api_service.dart   # API service (Google Books, Open Library)
│   └── repositories/
│       └── book_repository.dart    # Data repository
├── logic/
│   ├── cubits/
│   │   └── book_cubit.dart         # Book state management
│   └── states/
│       └── book_state.dart         # State definitions
├── presentation/
│   ├── screens/
│   │   ├── home_screen.dart        # Main library view
│   │   ├── search_screen.dart      # Book search
│   │   ├── book_detail_screen.dart # Book details & progress
│   │   ├── manual_entry_screen.dart # Manual book entry
│   │   └── scanner_screen.dart     # ISBN barcode scanner
│   └── widgets/
│       ├── book_card_widget.dart   # Book list/grid cards
│       ├── progress_indicator_widget.dart # Progress widgets
│       └── shimmer_loading.dart    # Loading placeholders
└── main.dart                       # App entry point
```

## Database Schema

### Books Table

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key (auto-increment) |
| title | TEXT | Book title |
| author | TEXT | Author name |
| description | TEXT | Book description |
| thumbnail_url | TEXT | Cover image URL |
| total_pages | INTEGER | Total number of pages |
| current_page | INTEGER | Current reading position |
| start_date | INTEGER | Reading start date (timestamp) |
| status | TEXT | "to_read", "reading", or "finished" |
| isbn | TEXT | ISBN-10 or ISBN-13 |
| publisher | TEXT | Publisher name |
| published_date | TEXT | Publication date |
| created_at | INTEGER | Record creation timestamp |
| updated_at | INTEGER | Last update timestamp |

## API Integration

### Google Books API (Primary)
- Search by ISBN, title, or author
- Fetches: title, author, description, page count, cover image, publisher

### Open Library API (Fallback)
- Used when Google Books has no results
- Alternative data source with similar information

## Reading Statistics Formulas

### Average Pages Per Day
```
Average = current_page / (days_elapsed + 1)
```

### Estimated Days Remaining
```
Remaining = (total_pages - current_page) / Average
```

### Estimated Finish Date
```
Finish_Date = Current_Date + Remaining_Days
```

## Setup Instructions

### Prerequisites
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- iOS Simulator / Android Emulator

### Installation

1. **Clone or copy the project**
   ```bash
   cd personal_book_library
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate route files** (if needed)
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
Add camera permission to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

#### iOS
Add camera usage description to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan book barcodes</string>
```

## Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.3      # State management
  equatable: ^2.0.5         # Value equality
  sqflite: ^2.3.0           # Local database
  path: ^1.8.3              # Path utilities
  path_provider: ^2.1.1     # File paths
  auto_route: ^7.8.4        # Navigation
  dio: ^5.4.0               # HTTP client
  connectivity_plus: ^5.0.2 # Network status
  mobile_scanner: ^4.0.1    # Barcode scanning
  cached_network_image: ^3.3.0 # Image caching
  shimmer: ^3.0.0           # Loading animations
  intl: ^0.18.1             # Internationalization
  uuid: ^4.2.1              # Unique IDs
```

## Usage Guide

### Adding Books
1. **Manual Entry**: Tap the + icon in the app bar
2. **Search Online**: Use the search icon to find books online
3. **Scan Barcode**: Tap the FAB to scan ISBN barcodes

### Tracking Progress
1. Open a book from your library
2. Use the slider or enter the current page number
3. Progress saves automatically

### Viewing Statistics
- Reading speed and estimated finish date appear automatically for books in "Reading" status
- Based on your reading pace since starting the book

## Contributing

Feel free to submit issues and pull requests. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is open source and available under the MIT License.

---

**Made with ❤️ using Flutter**
