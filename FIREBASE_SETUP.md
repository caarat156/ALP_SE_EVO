# Firebase Setup Guide untuk EVO App

## Step 1: Create Firebase Project

### 1.1 Buat Project Baru
1. Buka https://console.firebase.google.com
2. Klik **"Create a project"** atau **"Add project"**
3. Masukkan nama project: `ALP-SE-EVO`
4. Pilih location terdekat (Southeast Asia - Singapore)
5. Klik **"Create project"**
6. Tunggu proses selesai (~2-3 menit)

## Step 2: Setup iOS App

### 2.1 Register iOS App
1. Di Firebase Dashboard, klik **"Add app"** 
2. Pilih **iOS** (Apple icon)
3. Isi informasi:
   - **iOS Bundle ID**: `com.tengkiawan.ALPSEVO`
   - Nickname (optional): `EVO iOS`
4. Klik **"Register app"**

### 2.2 Download Google Service Info Plist
1. Di halaman "Download config file", klik **"Download GoogleService-Info.plist"**
2. File akan ter-download ke komputer
3. Buka Xcode project `ALP_SE_EVO.xcodeproj`
4. Drag file `GoogleService-Info.plist` ke Xcode
5. Pastikan:
   - ✅ "Copy items if needed" tercentang
   - ✅ Target `ALP_SE_EVO` terseleksi
   - ✅ File muncul di project navigator
6. Klik **"Finish"**

### 2.3 Install Firebase SDK
Lanjutkan dengan langkah "Add Firebase SDK" di Firebase console atau gunakan Swift Package Manager:

1. Di Xcode: **File → Add Packages**
2. Masukkan URL: `https://github.com/firebase/firebase-ios-sdk.git`
3. Pilih versi: **"Up to Next Major"** → `9.0.0`
4. Klik **"Add Package"**
5. Pilih packages yang diperlukan:
   - ☑ **FirebaseAuth**
   - ☑ **FirebaseFirestore**
6. Klik **"Add to Project"**
7. Pilih target: `ALP_SE_EVO`
8. Klik **"Add Package"**
9. Tunggu indexing selesai

## Step 3: Enable Firebase Services

### 3.1 Setup Authentication
1. Di Firebase Console, buka **Authentication**
2. Klik **"Get Started"** (jika belum setup)
3. Di tab **"Sign-in method"**, klik **Email/Password**
4. Aktifkan toggle "Enable"
5. Klik **"Save"**

### 3.2 Create Demo Users
1. Klik tab **"Users"** di Authentication
2. Untuk setiap user di bawah, klik **"Add user"**:

**User 1 - Peserta:**
- Email: `peserta@evo.com`
- Password: `password123`

**User 2 - Panitia:**
- Email: `panitia@evo.com`
- Password: `password123`

**User 3 - Vendor:**
- Email: `vendor@evo.com`
- Password: `password123`

**User 4 - Admin:**
- Email: `admin@evo.com`
- Password: `password123`

### 3.3 Setup Firestore Database
1. Di Firebase Console, buka **Firestore Database**
2. Klik **"Create database"**
3. Mode: Pilih **"Start in production mode"**
4. Location: **Southeast Asia (Singapore)**
5. Klik **"Create"**
6. Tunggu database siap (~1-2 menit)

### 3.4 Setup Firestore Security Rules
1. Di Firestore, buka tab **"Rules"**
2. Ganti konten dengan kode di bawah:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Public collections
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (request.auth.token.role == 'admin' || 
         request.auth.token.role == 'panitia');
    }
    
    // User profiles
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Tickets
    match /tickets/{ticketId} {
      allow read, write: if request.auth != null;
    }
    
    // Feedback
    match /feedback/{feedbackId} {
      allow read, write: if request.auth != null;
    }
    
    // Vendors
    match /vendors/{vendorId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == vendorId || 
                       request.auth.token.role == 'admin';
    }
    
    // Catalog
    match /catalog/{catalogId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Invoices
    match /invoices/{invoiceId} {
      allow read, write: if request.auth != null;
    }
    
    // Default deny
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

3. Klik **"Publish"**

> Catatan: Untuk versi tugas ini, **Cloud Storage tidak digunakan**. Semua data gambar / media digantikan dengan teks dan metadata di aplikasi.

## Step 4: Create Firestore Collections

### 4.1 Create Collections
Buka Firestore Console dan buat collections berikut dengan memberi custom ID:

**Collection 1: users**
- Click "Start collection"
- Collection ID: `users`
- Document ID: gunakan salah satu User ID (bisa dapat dari Authentication)
- Atau skip untuk sekarang (auto-create saat app dijalankan)

**Collection 2: events**
- Collection ID: `events`
- Skip document untuk sekarang

**Collection 3: tickets**
- Collection ID: `tickets`
- Skip document untuk sekarang

**Collection 4: feedback**
- Collection ID: `feedback`
- Skip document untuk sekarang

**Collection 5: vendors**
- Collection ID: `vendors`
- Skip document untuk sekarang

**Collection 6: catalog**
- Collection ID: `catalog`
- Skip document untuk sekarang

**Collection 7: invoices**
- Collection ID: `invoices`
- Skip document untuk sekarang

## Step 5: Create Custom Claims (Optional - For Advanced Features)

Untuk menggunakan custom claims untuk role-based access:

1. Buka Firebase Console → **All Products → Extensions**
2. Setup Firebase Admin SDK
3. Gunakan Firebase CLI:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login ke Firebase
firebase login

# Set custom claims untuk user
firebase firestore --set /users/[USER_UID] -- role=peserta
```

Atau gunakan Cloud Functions untuk auto-assign roles saat user register.

## Step 6: Konfigurasi App

### 6.1 Update Package.swift (SPM)
Pastikan SPM packages sudah ter-install dengan benar.

### 6.2 Test Connection
1. Build dan run app
2. Klik login
3. Masukkan:
   - Email: `peserta@evo.com`
   - Password: `password123`
4. Klik "Login"

Jika berhasil:
- ✅ App akan masuk ke Peserta Dashboard
- ✅ Data akan dimuat dari Firestore

### 6.3 Troubleshooting Login
Jika login gagal:

**Error: "The email address is badly formatted"**
- Pastikan email benar: `peserta@evo.com`

**Error: "The password is invalid"**
- Pastikan password benar: `password123`
- Cek di Firebase Console → Authentication → Users

**Error: "There is no user record corresponding to this identifier"**
- User belum dibuat di Firebase Authentication
- Lihat langkah 3.2 lagi

**Error: "Could not automatically select an app"**
- Pastikan `GoogleService-Info.plist` sudah ditambah ke Xcode
- Restart Xcode dan clean build folder

## Step 7: Setup Demo Data (Optional)

Untuk menambah demo data:

1. Buka Firestore Console
2. Collection `events`, klik "Add document"
3. Document ID: `event1` (atau auto)
4. Tambah fields:

```
title: "Freshmen Welcoming"
description: "Welcome event untuk mahasiswa baru"
event_date: 2026-06-15 10:00:00
location: "Ciputra University Auditorium"
quota: 500
registered_count: 245
status: "upcoming"
created_by: "admin_uid_here"
created_at: 2026-06-02 10:00:00
```

## Step 8: Test All Features

### Test Peserta
1. Login dengan `peserta@evo.com`
2. ✅ Lihat dashboard
3. ✅ Register ke event
4. ✅ Lihat tiket

### Test Panitia
1. Logout
2. Login dengan `panitia@evo.com`
3. ✅ Buat event baru
4. ✅ Lihat attendance

### Test Vendor
1. Logout
2. Login dengan `vendor@evo.com`
3. ✅ Tambah katalog item
4. ✅ Lihat invoices

### Test Admin
1. Logout
2. Login dengan `admin@evo.com`
3. ✅ Lihat semua events
4. ✅ Kelola vendors

## Troubleshooting Checklist

- [ ] GoogleService-Info.plist ada di project
- [ ] Firebase SDK ter-install via SPM
- [ ] Authentication dengan Email/Password enabled
- [ ] Firestore database dibuat
- [ ] Security rules sudah di-publish
- [ ] Demo users sudah dibuat
- [ ] Build settings cocok dengan Bundle ID

## Common Issues & Solutions

### Issue: App crash saat launch
**Solusi:**
- Clean build folder: Cmd+Shift+K
- Delete Derived Data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Rebuild project

### Issue: Firestore queries return empty
**Solusi:**
- Check Firestore rules (Mode: Production lebih ketat)
- Lihat Firestore → Database Usage untuk error messages
- Ensure collections dan documents sudah dibuat

### Issue: User tidak bisa login
**Solusi:**
- Cek user ada di Firebase → Authentication → Users
- Pastikan password benar
- Cek Firebase → Authentication → Logs untuk error details

### Issue: Data tidak tersimpan ke Firestore
**Solusi:**
- Check Firestore rules allows write
- Lihat console error messages
- Enable Firebase local emulator untuk debug

## Next Steps

1. ✅ Setup Firebase project sesuai guide ini
2. ✅ Build dan run app
3. ✅ Test dengan demo users
4. ✅ Customize sesuai kebutuhan
5. ✅ Deploy ke production

## Resources

- Firebase Documentation: https://firebase.google.com/docs
- Swift Documentation: https://developer.apple.com/swift/
- Firestore Best Practices: https://firebase.google.com/docs/firestore/best-practices

---

**Created by:** Tengkiawan Family
**Last Updated:** June 2, 2026
