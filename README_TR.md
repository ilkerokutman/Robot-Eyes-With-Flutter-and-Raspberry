# Robot Eyes

[Click here for English](README.md)

Raspberry Pi için ST7789 SPI ekranlarla Flutter tabanlı robot göz görüntüleme sistemi.

## Demo Videoları

[![Demo Video 1](https://img.youtube.com/vi/yt5mXC8gClE/0.jpg)](https://youtube.com/shorts/yt5mXC8gClE)

[![Demo Video 2](https://img.youtube.com/vi/3ZRi2_EnEjg/0.jpg)](https://youtube.com/shorts/3ZRi2_EnEjg)

## Genel Bakış

Bu proje iki Flutter uygulamasından oluşmaktadır:

- **rpi_eyes** - Raspberry Pi üzerinde çalışan ve çift ST7789 SPI ekranlara animasyonlu robot gözleri renderlayan göz görüntüleme uygulaması
- **rpi_eyes_control** - WebSocket üzerinden göz uygulamasına bağlanarak duyguları ve bakış yönünü kontrol eden kontrol uygulaması (masaüstü/mobil)

## Özellikler

- 9 duygu durumu: idle (boşta), curious (meraklı), happy (mutlu), angry (kızgın), frightened (korkmuş), sad (üzgün), joyful (neşeli), bored (sıkılmış), friendly (arkadaş canlısı)
- Joystick arayüzü ile yumuşak bakış kontrolü
- Asenkron göz kırpma animasyonu
- Kontrol uygulaması ve göz uygulaması arasında WebSocket iletişimi
- Otomatik bağlantı için UDP yayın keşfi
- Çapraz platform kontrol uygulaması (macOS, iOS, Android)

## Donanım Gereksinimleri

### Ekran
- 2x [0.96 inç IPS ST7789 Modül](https://www.lcdwiki.com/0.96inch_IPS_ST7789_Module) (240x240 çözünürlük)
- Raspberry Pi (Pi 4/5 üzerinde test edilmiştir)

### Kablolama

![Robot Gözler Bağlantısı](docs/connection.png)

![GPIO Pinout](docs/GPIO.png)

| Kablo Rengi | Fonksiyon | Bağlantı | Raspberry Pi Pin |
|-------------|-----------|----------|------------------|
| Sarı | SCL (Saat) | Paylaşımlı | Pin 23 (SCLK) |
| Yeşil | SDA (Veri) | Paylaşımlı | Pin 19 (MOSI) |
| Mavi | RES (Reset) | Paylaşımlı | Pin 22 (GPIO 25) |
| Beyaz | DC (Veri/Komut) | Paylaşımlı | Pin 18 (GPIO 24) |
| Kırmızı | GND | Paylaşımlı | Pin 6 (GND) |
| Siyah | VCC | Paylaşımlı | Pin 2 (5V) |
| Mor | BLK | Paylaşımlı | Pin 1 (3.3V) |
| Turuncu | CS (Seçim) | **AYRI** | Ekran 1 → Pin 24 (CE0) / Ekran 2 → Pin 26 (CE1) |

> **Not:** CS (Chip Select) dışındaki tüm sinyaller her iki ekran arasında paylaşılmaktadır. Her ekran bağımsız kontrol için kendi CS hattına ihtiyaç duyar.

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
flutter build linux --release -t lib/main_spi.dart
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
│   │   ├── drivers/          # SPI/ST7789 sürücüleri
│   │   ├── models/           # Veri modelleri
│   │   ├── services/         # WebSocket servisleri
│   │   ├── main.dart         # Masaüstü giriş noktası
│   │   └── main_spi.dart     # SPI ekran giriş noktası
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

- Ekran modülü: [0.96 inç IPS ST7789 Modül](https://www.lcdwiki.com/0.96inch_IPS_ST7789_Module)
- [Flutter](https://flutter.dev) ile geliştirilmiştir
