# XEPI Admin System

Web-based inventory and sales management system for XEPI, a Guatemalan retail company managing approximately 1,000 decorative products across a warehouse and a store.

## Tech Stack

- Flutter Web
- Firebase (Authentication, Firestore, Storage, Hosting)
- Python 3.13+ (migration scripts)

## Features

- Product catalog management with barcode scanning
- Real-time inventory tracking (warehouse and store locations)
- Order management (WhatsApp/Facebook orders)
- Sales recording and cash flow tracking
- Financial reports and analytics
- User role management (superuser and employee access levels)

## Setup

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Configure Firebase:
```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
cp web/firebase-config.js.example web/firebase-config.js
```
Edit both files with your Firebase project credentials.

3. Run development server:
```bash
flutter run -d chrome
```

4. Build for production:
```bash
flutter build web
```

5. Deploy to Firebase Hosting:
```bash
firebase deploy --only hosting
```

## Python Scripts

Migration and data import scripts are located in the `scripts/` directory. Install Python dependencies:

```bash
pip install -r requirements.txt
```

## Project Structure

- `lib/screens/` - Phase 1 functional screens
- `lib/screens/future/` - Phase 2 placeholder screens
- `lib/config/` - Theme and configuration
- `scripts/` - Python migration scripts

## Security

Sensitive files are gitignored. Never commit:
- `serviceAccountKey.json`
- `.env`
- `lib/firebase_options.dart`
- `web/firebase-config.js`
