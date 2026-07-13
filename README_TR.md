# Robot Eyes

[Click here for English](README.md)

Raspberry Pi için GC9A01 SPI yuvarlak ekranlarla Flutter tabanlı robot göz görüntüleme sistemi.

## Demo Videoları

[![Demo Video 1](https://img.youtube.com/vi/yt5mXC8gClE/0.jpg)](https://youtube.com/shorts/yt5mXC8gClE)

[![Demo Video 2](https://img.youtube.com/vi/3ZRi2_EnEjg/0.jpg)](https://youtube.com/shorts/3ZRi2_EnEjg)

## Genel Bakış

Bu proje iki Flutter uygulamasından oluşmaktadır:

- **rpi_eyes** - Raspberry Pi üzerinde çalışan ve çift GC9A01 SPI yuvarlak ekranlara animasyonlu robot gözleri renderlayan göz görüntüleme uygulaması
- **rpi_eyes_control** - WebSocket üzerinden göz uygulamasına bağlanarak duyguları ve bakış yönünü kontrol eden kontrol uygulaması (masaüstü/mobil)

![Kontrol Uygulaması](docs/control-app.jpg)

## Özellikler

- 9 duygu durumu: idle (boşta), curious (meraklı), happy (mutlu), angry (kızgın), frightened (korkmuş), sad (üzgün), joyful (neşeli), bored (sıkılmış), friendly (arkadaş canlısı)
- Joystick arayüzü ile yumuşak bakış kontrolü
- Asenkron göz kırpma animasyonu
- Kontrol uygulaması ve göz uygulaması arasında WebSocket iletişimi
- Otomatik bağlantı için UDP yayın keşfi
- Çapraz platform kontrol uygulaması (macOS, iOS, Android)

## Donanım Gereksinimleri

### Ekran
- 2x [Waveshare 1.28 inç GC9A01 LCD Modül](https://www.waveshare.com/wiki/1.28inch_LCD_Module) (240x240 çözünürlük)
- Raspberry Pi 4 veya Pi 5 (otomatik algılanır)

### Kablolama

![Robot Gözler Bağlantısı](docs/connection.png)

![GPIO Pinout](docs/GPIO.png)

| Kablo Rengi | Fonksiyon | Bağlantı | Raspberry Pi Pin |
|-------------|-----------|----------|------------------|
| Beyaz | GND | Paylaşımlı | Pin 6 / Pin 9 (GND) |
| Mor | VCC (5V) | Paylaşımlı | Pin 2 / Pin 4 (5V) |
| Turuncu | CLK (Saat) | Paylaşımlı | Pin 23 (SCLK) |
| Yeşil | DIN (Veri) | Paylaşımlı | Pin 19 (MOSI) |
| Kahverengi | RST (Reset) | Paylaşımlı | Pin 22 (GPIO 25) |
| Mavi | DC (Veri/Komut) | Paylaşımlı | Pin 18 (GPIO 24) |
| Sarı | CS1 (Seçim) | **AYRI** | Ekran 1 → Pin 24 (CE0 / BCM 8) |
| Sarı | CS2 (Seçim) | **AYRI** | Ekran 2 → Pin 26 (CE1 / BCM 7) |
| Gri | BL (Arka Işık) | Paylaşımlı | Pin 1 / Pin 17 (3.3V) |

> **Not:** CS (Chip Select) dışındaki tüm sinyaller her iki ekran arasında paylaşılmaktadır. Her ekran bağımsız kontrol için kendi CS hattına ihtiyaç duyar.

### Kablo Rengi Eşleştirmesi (Eski ST7789 → Yeni GC9A01)

Önceki 0.96 inç ST7789 kablo setinden yeniden kablolama yapıyorsanız bu eşleştirmeyi kullanın:

| Fonksiyon | Eski Renk | Yeni Renk |
|-----------|-----------|-----------|
| Toprak | Kırmızı | Beyaz |
| Güç (5V) | Siyah | Mor |
| Saat (SCLK) | Sarı | Turuncu |
| Veri (MOSI) | Yeşil | Yeşil |
| Reset | Mavi | Kahverengi |
| Veri / Komut | Beyaz | Mavi |
| Chip Select | Turuncu | Sarı |
| Arka Işık | Mor | Gri |

## Yazılım Kurulumu

### Ön Gereksinimler

1. Raspberry Pi'de SPI'ı etkinleştirin:
   ```bash
   sudo raspi-config
   # Şuraya gidin: Interface Options → SPI → Enable
   ```

2. Çift chip select'i etkinleştirin:
   `/boot/config.txt` dosyasına ekleyin:
   ```
   dtparam=spi=on
   dtoverlay=spi0-2cs
   ```

3. Kullanıcıyı GPIO/SPI gruplarına ekleyin:
   ```bash
   sudo usermod -aG gpio,spi $USER
   ```

4. Pi'yi yeniden başlatın

### Göz Uygulamasını Derleme (Raspberry Pi üzerinde)

```bash
cd rpi_eyes
flutter pub get
flutter build linux --release -t lib/main.dart
```

### Göz Uygulamasını Çalıştırma

```bash
./build/linux/arm64/release/bundle/rpi_eyes
```

VNC/masaüstü modu için (SPI ekranlar olmadan):
```bash
flutter run -d linux
```

### Kontrol Uygulamasını Derleme

**macOS:**
```bash
cd rpi_eyes_control
flutter build macos --release
```

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Kullanım

1. Raspberry Pi üzerinde göz uygulamasını başlatın
2. Telefonunuzda veya bilgisayarınızda kontrol uygulamasını açın
3. Kontrol uygulaması UDP yayını ile göz uygulamasını otomatik olarak keşfedecektir
4. Bağlanmak için dokunun, ardından bakışı kontrol etmek için joystick'i ve duyguları değiştirmek için butonları kullanın

## Ağ Portları

- **WebSocket:** 5050 (göz sunucusu)
- **UDP Keşif:** 5001 (yayın)

## Proje Yapısı

```
eyes/
├── rpi_eyes/                 # Göz görüntüleme uygulaması
│   ├── lib/
│   │   ├── app/              # UI bileşenleri
│   │   ├── drivers/          # SPI/GC9A01 sürücüleri
│   │   ├── models/           # Veri modelleri
│   │   ├── services/         # WebSocket servisleri
│   │   └── main.dart         # Giriş noktası (Pi'de SPI, masaüstünde render)
│   └── ...
├── rpi_eyes_control/         # Kontrol uygulaması
│   ├── lib/
│   │   └── main.dart         # Kontrol uygulaması UI
│   └── ...
└── docs/                     # Dokümantasyon dosyaları
```

## Lisans

Bu proje açık kaynaklıdır ve [MIT Lisansı](LICENSE) altında kullanılabilir.

## Teşekkürler

- Ekran modülü: [Waveshare 1.28 inç GC9A01 LCD Modül](https://www.waveshare.com/wiki/1.28inch_LCD_Module)
- [Flutter](https://flutter.dev) ile geliştirilmiştir
