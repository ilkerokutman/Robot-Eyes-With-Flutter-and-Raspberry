# SPI Display Setup Guide

The Robot Eyes app initializes the SPI displays correctly, but Flutter needs a display server to render the UI. This guide explains the issue and provides solutions.

## Problem

- ✅ GPIO/SPI initialization works
- ✅ Display controllers respond to commands
- ❌ Flutter can't render widgets without a display server
- ❌ `RenderRepaintBoundary.toImage()` requires X11/Wayland context

## Solutions

### Option 1: Virtual Framebuffer (Xvfb) - Recommended for Headless Pi

Best for headless Raspberry Pi without physical monitor.

**Install:**
```bash
sudo apt-get update
sudo apt-get install -y xserver-xvfb x11-utils
```

**Run the app:**
```bash
# Terminal 1: Start virtual X11 display
Xvfb :99 -screen 0 1920x1080x24 &

# Terminal 2: Run the app with display set
export DISPLAY=:99
/opt/eyes/rpi_eyes
```

**Or in one command:**
```bash
DISPLAY=:99 Xvfb :99 -screen 0 1920x1080x24 & sleep 1 && /opt/eyes/rpi_eyes
```

### Option 2: Physical Monitor + HDMI

Connect a monitor to the Pi 5's HDMI port. The app will render to the monitor and simultaneously send pixel data to the SPI displays.

**Run the app:**
```bash
/opt/eyes/rpi_eyes
```

The app will:
1. Render Flutter UI to HDMI display
2. Capture rendered pixels
3. Convert to RGB565
4. Send to SPI displays via GPIO/SPI

### Option 3: VNC Remote Display

Access the Pi remotely with a graphical desktop.

**Install VNC server:**
```bash
sudo apt-get install -y tigervnc-standalone-server
```

**Start VNC:**
```bash
vncserver :1 -geometry 1920x1080 -depth 24
```

**Connect from your Mac:**
```bash
open vnc://192.168.0.116:5901
```

**Run the app:**
```bash
export DISPLAY=:1
/opt/eyes/rpi_eyes
```

## How It Works

1. **Flutter renders UI** to the display server (X11/Wayland)
2. **RenderRepaintBoundary captures** the rendered pixels
3. **RGB565Converter converts** RGBA to RGB565 format
4. **SPI driver sends** pixel data to ST7789 controllers
5. **Displays show** the rendered content

## Debugging

### Check if display server is running:
```bash
echo $DISPLAY
# Should output something like :99 or :1
```

### Test X11 connection:
```bash
xdpyinfo
# Should show display info if X11 is working
```

### Check SPI communication:
```bash
# Verify SPI devices exist
ls -la /dev/spidev*

# Check GPIO access
gpioinfo | grep GPIO24
gpioinfo | grep GPIO25
```

### Monitor app output:
```bash
/opt/eyes/rpi_eyes 2>&1 | tee /tmp/rpi_eyes.log
```

## Expected Output

When running with display server:

```
========================================
Robot Eyes v1.0.1
========================================
Detected: Raspberry Pi 5 (GPIO chip 0)
Initializing SPI displays...
Initializing display manager...
Initializing left display (CE0)...
Left display initialized
Initializing right display (CE1)...
Right display initialized
Display manager initialized successfully
```

Then the SPI displays should show the rendered eye animation.

## Troubleshooting

### "Cannot open display" error
- Display server not running
- DISPLAY variable not set
- Solution: Start Xvfb or set DISPLAY correctly

### Displays show only backlight
- Flutter rendering not working
- RenderRepaintBoundary.toImage() returning null
- Solution: Verify display server is running with `echo $DISPLAY`

### SPI communication errors
- GPIO pins not accessible
- SPI device not available
- Solution: Check permissions and device files

### App crashes on startup
- Missing display server
- GPIO initialization failed
- Solution: Check logs with `2>&1 | tee /tmp/rpi_eyes.log`

## Performance Notes

- Xvfb rendering is software-based (slower)
- Physical monitor is faster (hardware accelerated)
- SPI transfer is ~40 Mbps (sufficient for 240x240 @ 60fps)
- Frame rate depends on Flutter rendering + SPI transfer time

## Next Steps

1. Choose a display option (Xvfb recommended for headless)
2. Install required packages
3. Start display server
4. Run `/opt/eyes/rpi_eyes`
5. Verify SPI displays show content

## References

- [Xvfb Documentation](https://www.x.org/releases/X11R7.6/doc/man/man1/Xvfb.1.xhtml)
- [Flutter Linux Desktop](https://docs.flutter.dev/platform-integration/linux/building)
- [ST7789 Display Controller](https://www.lcdwiki.com/0.96inch_IPS_ST7789_Module)
- [Raspberry Pi GPIO](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html)
