#!/bin/bash

# Setup minimal X11 display server on Raspberry Pi for headless Flutter rendering
# This allows Flutter to render widgets even without a physical monitor

set -e

echo "Setting up minimal X11 display server for Flutter rendering..."

# Install required packages
echo "Installing X11 and display server packages..."
sudo apt-get update
sudo apt-get install -y xserver-xvfb x11-utils

# Create a simple X11 startup script
echo "Creating X11 startup script..."
cat > /tmp/start-x11.sh << 'EOF'
#!/bin/bash
# Start Xvfb (virtual framebuffer) on display :99
Xvfb :99 -screen 0 1920x1080x24 &
export DISPLAY=:99
sleep 2
echo "X11 display :99 started"
EOF

chmod +x /tmp/start-x11.sh

echo ""
echo "✓ X11 setup complete!"
echo ""
echo "To run the app with X11 display:"
echo "  1. Start X11: Xvfb :99 -screen 0 1920x1080x24 &"
echo "  2. Set display: export DISPLAY=:99"
echo "  3. Run app: /opt/eyes/rpi_eyes"
echo ""
echo "Or use the convenience script:"
echo "  bash /tmp/start-x11.sh && /opt/eyes/rpi_eyes"
echo ""
