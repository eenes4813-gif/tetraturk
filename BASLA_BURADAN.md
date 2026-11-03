# EXE ve APK'yı otomatik üretme (bilgisayara bir şey kurmadan)

1. https://github.com adresinde ücretsiz hesap açın, "New repository" ile yeni bir depo oluşturun (adı: tetraturk).
2. Bu zip'i çıkarın. Deponun sayfasında "uploading an existing file" bağlantısına tıklayıp
   çıkan klasörün İÇİNDEKİ her şeyi (.github klasörü dahil) sürükleyip bırakın, "Commit changes" deyin.
3. Üstteki "Actions" sekmesi → "TetraTurk derle" → "Run workflow".
4. Yaklaşık 10-15 dakika sonra bitince çalıştırmanın sayfasının altındaki "Artifacts" bölümünden indirin:
   - TetraTurk-Windows-Kurulum  → TetraTurk_Kurulum.exe (çift tıkla kur, masaüstüne kısayol koyar)
   - TetraTurk-Android-APK      → telefonunuza uygun .apk (çoğu telefon: arm64-v8a)
