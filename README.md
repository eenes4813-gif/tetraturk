# TetraTürk

Flutter + yt-dlp ile Android ve Windows için video/ses indirici.

## 0) Proje iskeleti
```
flutter create --org com.tetraturk --project-name tetraturk --platforms=android,windows .
```
(Bu klasörde çalıştırın; pubspec.yaml ve lib/ dosyalarının üzerine yazmaz, gerekirse bu dosyaları tekrar kopyalayın.)

## Windows
```
flutter build windows --release
```
Çıktı: `build\windows\x64\runner\Release`. `windows_tools\setup_windows.ps1` dosyasını o klasöre kopyalayıp çalıştırın
(yt-dlp.exe + ffmpeg.exe `tools` klasörüne iner). Klasörü olduğu gibi paylaşabilirsiniz.

## Android
1. `android_files/MainActivity.kt` dosyasını `android/app/src/main/kotlin/com/tetraturk/tetraturk/MainActivity.kt` üzerine kopyalayın.
2. `android/app/build.gradle.kts` içine ekleyin:
```kotlin
android {
    defaultConfig { minSdk = 24; ndk { abiFilters += listOf("arm64-v8a", "armeabi-v7a") } }
    packaging { jniLibs { useLegacyPackaging = true } }
}
dependencies {
    implementation("io.github.junkfood02.youtubedl-android:library:0.17.2")
    implementation("io.github.junkfood02.youtubedl-android:ffmpeg:0.17.2")
}
```
3. `android/app/src/main/AndroidManifest.xml` içinde `<manifest>` altına: `<uses-permission android:name="android.permission.INTERNET"/>`
4. `flutter build apk --release --split-per-abi` (telefonlar için genelde `app-arm64-v8a-release.apk`)

## Kalite ve kodek
- Çözünürlük "En yüksek" iken kaynakta ne varsa (8K/4K dahil) en yükseği seçilir.
- Kodek bir tercihtir: AV1/VP9 genelde en yüksek çözünürlükleri sunar, H.264 en uyumlu olanıdır.
- MKV her kodek+ses birleşimini kabul eder; MP4 en uyumlusu, WebM ise yalnızca VP9/AV1+Opus içindir.
