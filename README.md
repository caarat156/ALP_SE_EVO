# EVO - Event Management System

Aplikasi iOS untuk manajemen event terintegrasi menggunakan Swift dan Firebase.

## Fitur Utama

### Untuk Peserta (Peserta)
- ✅ Registrasi event
- ✅ Lihat tiket QR Code
- ✅ Check-in otomatis dengan QR
- ✅ Berikan feedback untuk event
- ✅ Nilai panitia dan vendor

### Untuk Panitia (Committee)
- ✅ Buat dan kelola event
- ✅ Lihat daftar kehadiran real-time
- ✅ Scan QR untuk check-in peserta
- ✅ Lihat recap dan statistik event
- ✅ Kelola form evaluasi

### Untuk Vendor
- ✅ Kelola katalog produk
- ✅ Lihat invoice pembayaran
- ✅ Lacak status payment
- ✅ Update detail produk

### Untuk Admin
- ✅ Kelola semua event global
- ✅ Kelola daftar vendor
- ✅ Kelola user (peserta, panitia)
- ✅ Lihat dashboard sistem
- ✅ Laporan keseluruhan

## Arsitektur

### 3-Tier Architecture
1. **Client Tier** - Swift iOS App (MVVM)
2. **Application Tier** - Firebase Cloud Functions
3. **Data Tier** - Firebase Firestore

### Design Patterns
- MVVM untuk separation of concerns
- Singleton untuk Firebase Service
- Environment Objects untuk state management

## Setup Instructions

### 1. Prerequisites
- Xcode 14.0 atau lebih tinggi
- iOS 15.0 atau lebih tinggi
- CocoaPods atau SPM

### 2. Firebase Setup

#### a. Buat Project di Firebase Console
1. Buka https://console.firebase.google.com
2. Klik "Create a new project"
3. Nama project: `ALP_SE_EVO`
4. Aktifkan Google Analytics (optional)

#### b. Tambahkan iOS App
1. Di Firebase Console, klik "Add app" → iOS
2. Bundle ID: `com.tengkiawan.ALPSEVO` (atau sesuaikan)
3. Unduh `GoogleService-Info.plist`
4. Taruh file di root folder Xcode project
5. Pastikan target `ALP_SE_EVO` dipilih

#### c. Aktifkan Authentication
1. Buka Firebase Console → Authentication
2. Klik "Get started"
3. Aktifkan "Email/Password"

#### d. Setup Firestore Database
1. Buka Firebase Console → Firestore Database
2. Klik "Create database"
3. Mulai di "production mode"
4. Lokasi: Asia Tenggara (singapore) atau sesuaikan

#### e. Setup Security Rules
Buka Firestore → Rules dan ganti dengan:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      allow read: if request.auth != null;
    }
    
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (request.auth.token.claims.role == 'admin' || 
         request.auth.token.claims.role == 'panitia');
    }
    
    match /tickets/{ticketId} {
      allow read, write: if request.auth != null;
    }
    
    match /feedback/{docId} {
      allow write: if request.auth != null;
      allow read: if request.auth != null;
    }
    
    match /vendors/{vendorId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == vendorId;
    }
    
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 3. Install Dependencies

#### Menggunakan SPM (Recommended)
1. Di Xcode: File → Add Packages
2. Masukkan: `https://github.com/firebase/firebase-ios-sdk.git`
3. Pilih versi terbaru (9.0 atau lebih tinggi)
4. Pilih targets: ALP_SE_EVO
5. Tunggu indexing selesai

Packages yang diperlukan:
- Firebase-Authentication
- Firebase-Firestore

#### Atau Menggunakan CocoaPods
Jika menggunakan CocoaPods, buat Podfile:

```bash
cd /Users/macintoshhd/Documents/SEM\ 4/SE/ALP_SE_EVO
pod init
```

Edit Podfile:
```ruby
target 'ALP_SE_EVO' do
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
end
```

Jalankan:
```bash
pod install
```

### 4. Demo Credentials

Setup akun demo di Firebase Authentication:

```
Peserta:
  Email: peserta@evo.com
  Password: password123

Panitia:
  Email: panitia@evo.com
  Password: password123

Vendor:
  Email: vendor@evo.com
  Password: password123

Admin:
  Email: admin@evo.com
  Password: password123
```

### 5. Build & Run

1. Buka `ALP_SE_EVO.xcodeproj`
2. Pilih scheme `ALP_SE_EVO`
3. Pilih simulator atau device
4. Press Cmd+R atau klik Run

## Project Structure

```
ALP_SE_EVO/
├── Models/
│   ├── User.swift
│   ├── Event.swift
│   ├── Ticket.swift
│   ├── Vendor.swift
│   └── Feedback.swift
├── ViewModels/
│   ├── AuthManager.swift
│   └── ViewModels.swift
├── Services/
│   └── FirebaseService.swift
├── Views/
│   ├── ContentView.swift (Login)
│   ├── PesertaViews.swift
│   ├── PanitiaViews.swift
│   ├── VendorViews.swift
│   └── AdminViews.swift
├── ALP_SE_EVOApp.swift
└── GoogleService-Info.plist
```

## Non-Functional Requirements Implementation

### 1. Speed (< 2 detik untuk QR validation)
- Firebase database indexing pada ticket ID
- Realtime Database untuk instant updates
- Client-side caching

### 2. Security
- QR Code terenkripsi
- RBAC (Role-Based Access Control)
- Secure communication via HTTPS
- Firebase Security Rules

### 3. Ease of Use
- Auto brightness saat menampilkan ticket
- Intuitive UI dengan SwiftUI
- Tab-based navigation

### 4. Reliability
- Pessimistic locking untuk quota management
- Local session persistence
- Error handling dan retry logic

### 5. Portability
- Auto Layout dengan SwiftUI constraints
- Support iPhone SE hingga Pro Max
- Responsive design

## Testing

### Unit Tests
```bash
Cmd+U di Xcode
```

### Test Data
Aplikasi dilengkapi dengan mock data untuk testing tanpa Firebase.

## Troubleshooting

### Firebase Connection Issues
1. Verifikasi GoogleService-Info.plist di target
2. Check Firebase rules di console
3. Ensure authentication diaktifkan

### Auth Errors
- Invalid email format? Cek regex validation
- Email already exists? Try different email
- Wrong password? Reset via Firebase console

### Firestore Queries Slow
- Check indexes di Firestore
- Optimize query dengan filter yang tepat
- Monitor read/write operations

## Development Notes

### Adding New Features

1. **Buat Model** → Models/
2. **Buat ViewModel** → ViewModels/
3. **Tambah Service Method** → Services/FirebaseService.swift
4. **Buat View** → Views/
5. **Update Navigation** di main app

### Code Style
- Swift naming conventions
- MARK: untuk organization
- Comprehensive comments untuk complex logic

## Future Enhancements

- [ ] Push notifications
- [ ] Offline sync dengan Core Data
- [ ] QR Code library untuk real generation
- [ ] Image upload untuk profile
- [ ] Email notifications
- [ ] Advanced analytics
- [ ] Dark mode support

## License

Ciputra University - Software Engineering 2026

## Team

- Angelique Kyra Wahyudi (awahyudi02@student.ciputra.ac.id)
- Christian Owen Tengkawan (ctengkawan@student.ciputra.ac.id)
- Amadeus Ian Gunadi (aiangunadi@student.ciputra.ac.id)
- Anastasia Eugene Maylinda (amaylinda@student.ciputra.ac.id)
