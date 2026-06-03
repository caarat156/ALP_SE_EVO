# Quick Start Guide - EVO App

## TL;DR - Get Running in 5 Minutes

### 1. Download GoogleService-Info.plist (2 min)
```
1. Go to https://console.firebase.google.com
2. Create new project called "ALP-SE-EVO"
3. Add iOS app with Bundle ID: com.tengkiawan.ALPSEVO
4. Download GoogleService-Info.plist
5. Drag into Xcode project
```

### 2. Install Firebase SDK (1 min)
```
Xcode Menu:
File → Add Packages
→ https://github.com/firebase/firebase-ios-sdk.git
→ Select FirebaseAuth, FirebaseFirestore
→ Add to Project
```

### 3. Setup Firebase (1 min)
```
Firebase Console:
- Authentication → Enable Email/Password
- Create 4 demo users (see credentials below)
- Firestore → Create database (production mode)
- Firestore → Update security rules (see FIREBASE_SETUP.md)
```

### 4. Build & Run (1 min)
```
Xcode: Cmd+R
Login with: peserta@evo.com / password123
```

## Demo Credentials

```
PESERTA
Email: peserta@evo.com
Password: password123

PANITIA
Email: panitia@evo.com
Password: password123

VENDOR
Email: vendor@evo.com
Password: password123

ADMIN
Email: admin@evo.com
Password: password123
```

## What You Can Do

### As Peserta (Participant)
- ✅ Register for events
- ✅ View your tickets with QR code
- ✅ Show ticket for check-in
- ✅ Rate events and staff
- ✅ View event details

### As Panitia (Committee)
- ✅ Create new events
- ✅ Scan QR codes for check-in
- ✅ View attendance records
- ✅ See event statistics
- ✅ Download event recap

### As Vendor
- ✅ Add products to catalog
- ✅ View invoices
- ✅ Track payment status
- ✅ Manage pricing

### As Admin
- ✅ Create global events
- ✅ Manage all vendors
- ✅ View system statistics
- ✅ Manage users
- ✅ Generate reports

## Important Files

| File | Purpose |
|------|---------|
| `README.md` | Full documentation |
| `FIREBASE_SETUP.md` | Detailed Firebase setup |
| `PROJECT_STRUCTURE.md` | Architecture & code organization |
| `ALP_SE_EVOApp.swift` | App entry point |
| `GoogleService-Info.plist` | Firebase credentials |

## Troubleshooting

### App won't start?
```
1. Clean: Cmd+Shift+K
2. Check GoogleService-Info.plist exists
3. Check Deployment Target is iOS 15+
4. Rebuild: Cmd+B
```

### Can't login?
```
1. Verify user exists in Firebase → Authentication
2. Check password is exactly: password123
3. Ensure Email/Password is enabled in Firebase
4. Try different account
```

### App says "could not select app"?
```
1. Restart Xcode
2. File → Project Settings
3. Ensure GoogleService-Info.plist is in target
4. Try Project → Clean Build Folder
```

### Data not appearing?
```
1. Check Firestore rules in Firebase console
2. Verify collections exist (users, events, tickets)
3. Check Security Rules allow read/write
4. Look at Firestore → Logs for errors
```

## Project Features

### Architecture
- **Pattern**: MVVM + Singleton Services
- **Database**: Firebase Firestore
- **Auth**: Firebase Authentication
- **UI**: SwiftUI + TabView Navigation

### Tech Stack
- Swift 5.9+
- SwiftUI
- Firebase SDK 9.0+
- iOS 15.0+ deployment target

### Security
- Role-Based Access Control (RBAC)
- Encrypted QR codes
- Custom Firestore security rules
- Session persistence

### Performance
- Optimized Firestore queries
- Efficient data syncing
- Responsive UI with property observers
- Minimal network requests

## File Structure Quick Reference

```
Models/               ← Data structures
├─ User.swift
├─ Event.swift
├─ Ticket.swift
├─ Vendor.swift
└─ Feedback.swift

ViewModels/           ← Business logic
├─ AuthManager.swift
└─ ViewModels.swift

Services/             ← Database layer
└─ FirebaseService.swift

Views/                ← UI screens
├─ LoginView (in ContentView.swift)
├─ PesertaViews.swift
├─ PanitiaViews.swift
├─ VendorViews.swift
└─ AdminViews.swift

Utilities/            ← Helpers
├─ Extensions.swift
└─ SampleData.swift
```

## Common Tasks

### Test with Different User?
1. Click profile tab
2. Scroll down and click "Logout"
3. Login with different credentials

### Create Test Event?
1. Login as panitia@evo.com
2. Go to Events tab
3. Click "Create New Event"
4. Fill form and create

### Register for Event?
1. Login as peserta@evo.com
2. Go to Events tab
3. Click "Register for New Event"
4. Choose event and confirm

### Check In Participant?
1. Login as panitia@evo.com
2. Go to Events tab
3. Select your event
4. Click "Check-in (QR Scan)"
5. Enter ticket ID or scan QR

## Next Steps

1. ✅ Setup Firebase (see FIREBASE_SETUP.md)
2. ✅ Run app and test all roles
3. ✅ Add your own demo data
4. ✅ Customize colors/branding
5. ✅ Deploy to Test Flight or App Store

## Getting Help

- **Firebase Issues** → FIREBASE_SETUP.md
- **Code Structure** → PROJECT_STRUCTURE.md
- **Full Docs** → README.md
- **Swift Docs** → https://developer.apple.com/swift/
- **Firebase Docs** → https://firebase.google.com/docs

## Tips & Tricks

### Speed Up Testing
- Use keyboard shortcuts: Cmd+R to rebuild
- Use simulator instead of real device (faster)
- Test one feature at a time

### View Console Logs
- Xcode: View → Debug Area → Show Console
- Or: Cmd+Shift+Y

### Reset All Data
```
1. Delete app from simulator
2. File → Clean Build Folder (Cmd+Shift+K)
3. Run app fresh
4. Create new test data in Firestore
```

### Debug Firestore
1. Open Firebase Console
2. Go to Firestore → Database
3. Check collections for data
4. Click Logs tab to see errors

## Performance Tips

- Minimize network calls
- Use pagination for large lists
- Cache frequently accessed data
- Optimize queries with filters
- Use local @Published properties

## Security Reminders

- ⚠️ Never commit GoogleService-Info.plist to public repo
- ⚠️ Update Firestore rules for production
- ⚠️ Use environment variables for sensitive data
- ⚠️ Enable 2FA on Firebase project

## Version Info

- **Swift**: 5.9 or higher
- **iOS**: 15.0 minimum
- **Xcode**: 14.0 or higher
- **Firebase SDK**: 9.0 or higher

---

**Created:** June 2, 2026
**Last Updated:** June 2, 2026
**Status:** ✅ Ready for use

Need help? Check the troubleshooting section or refer to detailed docs!
