# Fitur Image Recognition untuk Identifikasi Sampah

## Overview
Fitur ini memungkinkan pengguna untuk mengidentifikasi jenis sampah menggunakan kamera dengan bantuan AI. Setelah mengambil foto, sistem akan menganalisis gambar dan menampilkan informasi tentang jenis sampah beserta fun facts edukatif.

## Komponen Utama

### 1. ImageRecognitionService (`lib/services/image_recognition_service.dart`)
- Service untuk berkomunikasi dengan OpenRouter AI API
- Menggunakan model `google/gemini-2.0-flash-exp:free` untuk vision recognition
- Mengkonversi gambar ke base64 dan mengirim ke API
- Menyediakan fallback data untuk testing

### 2. WasteIdentificationResult (`lib/widgets/waste_identification_result.dart`)
- Widget popup yang muncul dari bawah dengan animasi slide up
- Menampilkan hasil identifikasi dengan icon, nama sampah, harga, dan fun facts
- Memiliki animasi smooth dengan fade dan slide transition

### 3. IdentifikasiCameraPage (`lib/pages/main_features/kategori_barang/identifikasi_camera.dart`)
- Halaman kamera utama untuk mengambil foto sampah
- Terintegrasi dengan image recognition service
- Menampilkan loading state saat memproses gambar
- Menampilkan hasil dalam popup overlay

## Cara Kerja

1. **Buka Kamera**: User membuka halaman identifikasi kamera
2. **Ambil Foto**: User mengarahkan kamera ke sampah dan menekan tombol capture
3. **Processing**: Gambar dikonversi ke base64 dan dikirim ke AI API
4. **Analisis**: AI menganalisis gambar dan mengembalikan data JSON dengan:
   - `wasteType`: Jenis sampah (contoh: "Botol Plastik")
   - `category`: Kategori sampah (organik/anorganik/B3)
   - `price`: Harga per kg dalam format "XX Pts/Kg"
   - `funFacts`: Array berisi 5 fakta menarik tentang sampah
   - `confidence`: Tingkat kepercayaan AI dalam persen
5. **Tampilkan Hasil**: Popup muncul dari bawah dengan animasi menampilkan hasil

## API Configuration

API Key yang digunakan:
```
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
```

Model AI:
```
google/gemini-2.0-flash-exp:free
```

## Fallback Data

Jika API gagal, sistem akan menggunakan data fallback dengan 3 contoh sampah:
- Botol Plastik (50 Pts/Kg)
- Kaleng Aluminium (120 Pts/Kg)  
- Kertas Bekas (30 Pts/Kg)

## Dependencies

- `camera`: ^0.11.0+2 - Untuk akses kamera
- `http`: ^1.1.0 - Untuk API calls
- `path`: ^1.9.0 - Untuk file path handling

## UI/UX Features

- **Loading State**: Tombol kamera berubah jadi loading spinner saat memproses
- **Smooth Animation**: Popup muncul dengan slide up dan fade animation
- **Responsive Design**: Adaptif dengan berbagai ukuran layar
- **Error Handling**: Menampilkan pesan error jika gagal
- **Icon Mapping**: Icon otomatis berdasarkan jenis sampah

## Testing

Untuk testing, sistem akan menggunakan fallback data jika API tidak tersedia, sehingga fitur tetap bisa ditest tanpa koneksi internet atau jika API key bermasalah.