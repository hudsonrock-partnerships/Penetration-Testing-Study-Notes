# Steganography - CTF Guide

Steganography is the practice of hiding data within other data (images, audio, text, etc.).

## Table of Contents

- [Image Steganography](#image-steganography)
- [Audio Steganography](#audio-steganography)
- [Text Steganography](#text-steganography)
- [Other Formats](#other-formats)
- [Tools](#tools)

## Image Steganography

### Initial Analysis

```bash
# Always start with basics
file image.png
exiftool image.png
strings image.png | grep -i flag

# Check for appended data
binwalk image.png
binwalk -e image.png  # Extract

# Look at hex
xxd image.png | head
xxd image.png | tail
```

### LSB (Least Significant Bit) Steganography

Data hidden in the least significant bits of pixels.

```bash
# zsteg - PNG/BMP analysis
zsteg image.png
zsteg -a image.png  # All checks
zsteg -E 'b1,rgb,lsb,xy' image.png  # Extract specific

# stegsolve - Visual analysis
java -jar stegsolve.jar
# Try all bit planes (Red/Green/Blue 0-7)
# Look for patterns in LSB

# Python script for LSB extraction
python3 << EOF
from PIL import Image
img = Image.open('image.png')
pixels = img.load()
bits = ''
for y in range(img.height):
    for x in range(img.width):
        bits += str(pixels[x,y][0] & 1)  # Red LSB
data = ''.join(chr(int(bits[i:i+8], 2)) for i in range(0, len(bits), 8))
print(data)
EOF
```

### Steghide (JPG/BMP/WAV/AU)

```bash
# Check if steghide was used
steghide info image.jpg

# Extract (will prompt for passphrase)
steghide extract -sf image.jpg

# Crack passphrase
stegseek image.jpg rockyou.txt

# Or
stegcracker image.jpg wordlist.txt
```

### PNG Chunks

PNG files contain "chunks" - some standard, some custom.

```bash
# List chunks
pngcheck -v image.png

# Look for:
# - tEXt, zTXt, iTXt chunks (text)
# - Custom chunks (might contain data)

# Extract chunks manually
# Use hex editor or Python:
python3 << EOF
with open('image.png', 'rb') as f:
    data = f.read()
    # PNG signature: 89 50 4E 47 0D 0A 1A 0A
    # Then chunks: [length][type][data][CRC]
EOF

# Online tool
http://www.libpng.org/pub/png/apps/pngcheck.html
```

### Color Palette

Some images hide data in color palette indices.

```bash
# View with stegsolve
# File → File Format
# Check "Color map"

# Or imagemagick
convert image.png image.txt
# Look for patterns in palette
```

### Image XOR

```bash
# If you have two similar images
# XOR them to see differences
python3 << EOF
from PIL import Image
import numpy as np

img1 = np.array(Image.open('image1.png'))
img2 = np.array(Image.open('image2.png'))
result = np.bitwise_xor(img1, img2)
Image.fromarray(result).save('xor_result.png')
EOF
```

### Outguess

```bash
# Check for outguess steganography
outguess -r image.jpg output.txt

# If protected by key
outguess -k "key" -r image.jpg output.txt
```

### OpenStego

```bash
# Java-based tool
# Download from https://www.openstego.com/

# Extract
java -jar openstego.jar extract -sf image.png -xf output.txt
```

### Image Filters

Use stegsolve to try different filters:

- Red/Green/Blue plane 0-7
- Alpha plane
- XOR combinations
- Random color maps

Sometimes the flag is visible in a specific bit plane.

## Audio Steganography

### Spectrogram Analysis

Hidden data often visible in spectrogram view.

```bash
# Audacity (GUI)
audacity audio.wav
# View → Spectrogram

# Sonic Visualiser
sonic-visualiser audio.wav

# Command line
sox audio.wav -n spectrogram -o spectrogram.png
```

**Look for:**

- Text in frequency domain
- Images/QR codes
- Morse code patterns
- SSTV signals

### LSB in Audio

```bash
# Extract LSB from audio file
python3 << EOF
import wave
import struct

with wave.open('audio.wav', 'rb') as audio:
    frames = audio.readframes(audio.getnframes())
    data = struct.unpack(f'{len(frames)}B', frames)
    lsb = ''.join(str(b & 1) for b in data)
    # Convert bits to text
    text = ''.join(chr(int(lsb[i:i+8], 2)) for i in range(0, len(lsb), 8))
    print(text)
EOF
```

### DTMF Tones

Phone dial tones encode numbers.

```bash
# Decode DTMF
multimon-ng -t wav -a DTMF audio.wav

# Online tool
https://unframework.github.io/dtmf-detect/
```

### SSTV (Slow Scan Television)

Radio image transmission protocol.

```bash
# Decode SSTV
qsstv  # GUI tool
# or
robot36 -d audio.wav > image.png

# Online decoder
https://www.sstvdecoder.com/
```

### Morse Code

```bash
# If audio contains beeps
# Listen and decode manually
# Or use CW decoder

# Online tools
https://morsecode.world/international/decoder/audio-decoder-adaptive.html
```

## Text Steganography

### Whitespace Steganography

Data hidden in spaces and tabs.

```bash
# Visualize whitespace
cat -A file.txt

# Extract with stegsnow
stegsnow -C file.txt

# Or manually
python3 << EOF
with open('file.txt', 'r') as f:
    text = f.read()
    # Spaces → 0, Tabs → 1
    binary = text.replace(' ', '0').replace('\t', '1')
    # Convert to text
EOF
```

### Zero-Width Characters

```bash
# Unicode zero-width characters
# U+200B (Zero Width Space)
# U+200C (Zero Width Non-Joiner)
# U+200D (Zero Width Joiner)
# U+FEFF (Zero Width No-Break Space)

# Detect
python3 << EOF
text = open('file.txt', 'r', encoding='utf-8').read()
hidden = ''.join(c for c in text if c in '\u200b\u200c\u200d\ufeff')
print(f"Found {len(hidden)} hidden characters")
# Decode based on mapping
EOF

# Online tool
https://330k.github.io/misc_tools/unicode_steganography.html
```

### Case Encoding

```bash
# Capital/lowercase used to encode bits
# Capital = 1, lowercase = 0 (or vice versa)

python3 << EOF
text = "ThIs Is A sEcReT"
binary = ''.join('1' if c.isupper() else '0' for c in text if c.isalpha())
decoded = ''.join(chr(int(binary[i:i+8], 2)) for i in range(0, len(binary), 8))
print(decoded)
EOF
```

### Bacon Cipher

Uses two different typefaces (A and B).

```bash
# Online decoder
https://www.dcode.fr/bacon-cipher

# Pattern: AAAAA=A, AAAAB=B, AAABA=C, etc.
```

## Other Formats

### PDF Files

```bash
# Extract text
pdftotext file.pdf

# Extract metadata
exiftool file.pdf

# Extract embedded files
binwalk -e file.pdf
pdfdetach -list file.pdf
pdfdetach -save 1 -o output file.pdf

# Check for hidden layers
# Open in PDF reader and check layers panel

# Check for white text on white background
# Select all text in PDF reader
```

### ZIP Archives

```bash
# Hidden files (check actual vs listed)
unzip -l archive.zip
unzip archive.zip

# Steganography in ZIP
# Data can be hidden in:
# - File comments
# - Archive comment
# - Extra fields
# - Between files (gap)

# Extract comment
unzip -z archive.zip

# Check for weak encryption
fcrackzip -u -D -p rockyou.txt archive.zip
```

### Word Documents (DOCX)

```bash
# DOCX is a ZIP file
unzip document.docx -d extracted/

# Check:
# - document.xml (hidden text)
# - Comments
# - Track changes
# - Embedded objects

# Look for custom XML parts
```

### GIF Files

```bash
# GIF is made of frames
# Data might be in:
# - One specific frame
# - Comment extension
# - Application extension

# Extract frames
convert animation.gif frame%d.png

# Check each frame
```

### Video Files

```bash
# Extract frames
ffmpeg -i video.mp4 frame%d.png

# Extract audio
ffmpeg -i video.mp4 -vn audio.wav

# Analyze audio spectrogram
# Check frames for QR codes or text
```

## Tools

### Image Tools

```bash
# Essential
zsteg           # PNG/BMP LSB
steghide        # JPG/BMP/WAV/AU
stegsolve       # Visual analysis
stegseek        # Fast steghide cracker

# Advanced
outguess        # Statistical stego
openstego       # Java-based
exiftool        # Metadata
binwalk         # Embedded files

# Install
sudo apt install steghide exiftool binwalk
gem install zsteg
# stegsolve: Download jar from github
# stegseek: Download from releases
```

### Audio Tools

```bash
# Spectrogram viewers
audacity
sonic-visualiser

# Processing
sox             # Audio processor
multimon-ng     # DTMF decoder
qsstv           # SSTV decoder

# Install
sudo apt install audacity sonic-visualiser sox multimon-ng
```

### Python Libraries

```python
# PIL/Pillow - Image processing
from PIL import Image

# numpy - Array operations
import numpy as np

# wave - Audio processing
import wave

# stegano - Python stego library
pip install stegano
from stegano import lsb
secret = lsb.reveal("image.png")
```

## Common CTF Techniques

### 1. Always Start Basic

```bash
file image.png
strings image.png | grep flag
exiftool image.png
binwalk image.png
```

### 2. Try All LSB Tools

```bash
zsteg -a image.png
stegsolve  # GUI - try all planes
steghide extract -sf image.jpg
```

### 3. Check Multiple Channels

For images:

- Red LSB
- Green LSB
- Blue LSB
- Alpha channel
- All channels combined

### 4. Look for Visual Clues

- Slight color differences
- Patterns in noise
- Unusual file size
- Multiple similar images (XOR them)

### 5. Audio → Spectrogram

If you get audio, ALWAYS check spectrogram:

```bash
audacity audio.wav
# View → Spectrogram
```

### 6. Check File Concatenation

```bash
# Files might be appended
binwalk file
# Extract all
binwalk -e file
```

## Quick Workflow

```bash
# 1. Identify file type
file mysterious_file

# 2. Basic checks
strings mysterious_file | grep -i flag
exiftool mysterious_file

# 3. Check for hidden files
binwalk mysterious_file
foremost mysterious_file

# 4. Type-specific tools
# If image:
zsteg -a image.png
steghide info image.jpg
stegsolve (GUI)

# If audio:
audacity audio.wav  # Check spectrogram
sox audio.wav -n spectrogram -o spec.png

# If text:
cat -A file.txt  # Show whitespace
```

## Practice Resources

- **Steganography Online** - https://stylesuxx.github.io/steganography/
- **CTF Steganography** - Various CTF platforms
- **Steghide Practice** - https://www.aperisolve.fr/

## Tips

1. **Try everything** - Don't assume one method
2. **Look for hints** - Challenge description often hints at method
3. **Check metadata** - Always run exiftool
4. **Visual inspection** - Sometimes you can see patterns
5. **Layer analysis** - Try all bit planes in stegsolve
6. **Passwords** - Common passwords: "password", "flag", challenge name
7. **File size** - Unusually large? Probably has hidden data

Remember: Steganography in CTFs is about knowing the tools and trying them all!
