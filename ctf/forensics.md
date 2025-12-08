# Forensics - CTF Guide

Forensics challenges involve analyzing files, memory dumps, network captures, and other artifacts to find hidden information.

## Table of Contents

- [File Analysis](#file-analysis)
- [Image Forensics](#image-forensics)
- [Audio Forensics](#audio-forensics)
- [Network Forensics](#network-forensics)
- [Memory Forensics](#memory-forensics)
- [Disk Forensics](#disk-forensics)
- [Tools](#tools)

## File Analysis

### Basic File Identification

```bash
# Identify file type
file suspicious_file

# View file header (magic bytes)
xxd suspicious_file | head
hexdump -C suspicious_file | head

# Extract strings
strings suspicious_file
strings -n 10 suspicious_file  # Minimum length 10

# Search for flag pattern
strings suspicious_file | grep -i "flag"
strings suspicious_file | grep -E "flag\{.*\}"

# Check for embedded files
binwalk suspicious_file
binwalk -e suspicious_file  # Extract

# Alternative extraction
foremost -i suspicious_file -o output/
```

### File Metadata

```bash
# EXIF data
exiftool file.jpg
exiftool -a -u file.jpg  # All tags including unknown

# Check for hidden data in metadata
exiftool file.jpg | grep -i "comment\|description\|artist"
```

### File Carving

```bash
# Binwalk - analyze and extract
binwalk file
binwalk -e file  # Extract all
binwalk -D='.*' file  # Extract everything
binwalk --dd='.*' file

# Foremost - recover files
foremost -i image.dd -o output/
foremost -t jpg,png,pdf -i file -o output/

# Scalpel - faster alternative
scalpel -o output/ file

# Photorec - recover files
photorec /d output_dir/ file
```

## Image Forensics

### Steganography Detection

```bash
# Check LSB (Least Significant Bit)
stegsolve image.png  # GUI tool with filters

# zsteg - PNG/BMP analysis
zsteg image.png
zsteg -a image.png  # All tests

# steghide - extract hidden data (requires passphrase)
steghide info image.jpg
steghide extract -sf image.jpg

# stegseek - faster steghide cracker
stegseek image.jpg rockyou.txt

# outguess - another steg tool
outguess -r image.jpg output.txt

# StegCracker - brute force steghide
stegcracker image.jpg wordlist.txt
```

### Image Manipulation Detection

```bash
# Analyze image structure
pngcheck image.png
jpeginfo image.jpg

# Extract PNG chunks
pngcheck -v image.png

# Examine EXIF
exiftool image.jpg

# Convert between formats
convert image.png image.bmp
```

### Common Image Techniques

1. **LSB Steganography**

   - Data hidden in least significant bits
   - Use stegsolve with different planes

2. **PNG Chunks**

   ```bash
   # Extract text chunks
   pngcheck -v file.png | grep -i text

   # Custom chunks might contain data
   # Use hex editor to examine
   ```

3. **Palette Manipulation**

   - Check color palette for patterns
   - Use stegsolve "Image Combiner"

4. **File Concatenation**
   ```bash
   # Files appended to image
   binwalk -e image.jpg
   ```

### Image Analysis Tools

```bash
# ImageMagick
identify -verbose image.jpg
convert image.jpg -depth 1 output.png  # Change bit depth

# GIMP - visual analysis
# Open in layers, adjust levels, channels

# Stegsolve
java -jar stegsolve.jar
# Try all filters and bit planes
```

## Audio Forensics

### Audio Analysis

```bash
# View spectrogra (reveals hidden messages)
sonic-visualiser audio.wav
audacity  # Open and view spectrogram

# Extract data from LSB
stegolsb wavsteg -r -i audio.wav -o output.txt

# Analyze with Python
python3 << EOF
import wave
w = wave.open('audio.wav', 'r')
print(f"Channels: {w.getnchannels()}")
print(f"Sample width: {w.getsampwidth()}")
print(f"Frame rate: {w.getframerate()}")
print(f"Frames: {w.getnframes()}")
EOF
```

### Spectrogram Analysis

Hidden messages often appear in spectrogram view:

- Visual patterns
- Text in frequency domain
- QR codes
- Morse code patterns

**Tools:**

- Audacity (free)
- Sonic Visualiser
- Spectrum analyzer online tools

### DTMF Tones

```bash
# Decode phone dial tones
# Use online DTMF decoder
# Or multimon-ng
multimon-ng -t wav -a DTMF audio.wav
```

## Network Forensics

### PCAP Analysis

```bash
# Open with Wireshark
wireshark capture.pcap

# Command line analysis with tshark
tshark -r capture.pcap

# Statistics
tshark -r capture.pcap -qz io,phs

# Filter by protocol
tshark -r capture.pcap -Y "http"
tshark -r capture.pcap -Y "tcp.port==80"

# Extract HTTP objects
tshark -r capture.pcap --export-objects http,output/

# Follow TCP stream
tshark -r capture.pcap -z follow,tcp,ascii,0

# Extract specific data
tshark -r capture.pcap -Y "http.request.method==POST" -T fields -e http.file_data

# DNS queries
tshark -r capture.pcap -Y "dns.qry.name" -T fields -e dns.qry.name

# Find suspicious traffic
tshark -r capture.pcap -Y "http.request.method==POST" -T fields -e http.host -e http.request.uri
```

### Network Analysis Techniques

1. **Follow Streams**

   - Right-click packet → Follow → TCP/UDP Stream
   - Look for credentials, flags, files

2. **Export Objects**

   - File → Export Objects → HTTP/SMB/TFTP
   - Extract transferred files

3. **Protocol Hierarchy**

   - Statistics → Protocol Hierarchy
   - Identify unusual protocols

4. **Conversations**

   - Statistics → Conversations
   - Find endpoints communicating

5. **Filter Examples**
   ```
   http
   http.request.method == "POST"
   http contains "password"
   tcp.port == 80
   ip.addr == 192.168.1.1
   dns
   ftp
   ```

### USB PCAP Analysis

```bash
# Extract USB keyboard data
tshark -r usb.pcap -Y "usb.capdata" -T fields -e usb.capdata > data.txt

# Parse keyboard data
# Convert HID codes to characters
python3 usb_keyboard_parser.py data.txt
```

## Memory Forensics

### Volatility Framework

```bash
# Identify profile
volatility -f memory.dump imageinfo

# Linux
volatility -f memory.dump --profile=LinuxUbuntu_x64 linux_bash

# Windows processes
volatility -f memory.dump --profile=Win7SP1x64 pslist
volatility -f memory.dump --profile=Win7SP1x64 pstree

# Command history
volatility -f memory.dump --profile=Win7SP1x64 cmdscan
volatility -f memory.dump --profile=Win7SP1x64 consoles

# Network connections
volatility -f memory.dump --profile=Win7SP1x64 netscan

# Files
volatility -f memory.dump --profile=Win7SP1x64 filescan
volatility -f memory.dump --profile=Win7SP1x64 dumpfiles -Q 0x... -D output/

# Registry
volatility -f memory.dump --profile=Win7SP1x64 hivelist
volatility -f memory.dump --profile=Win7SP1x64 printkey -K "Software\\Microsoft\\Windows\\CurrentVersion\\Run"

# Passwords
volatility -f memory.dump --profile=Win7SP1x64 hashdump

# Clipboard
volatility -f memory.dump --profile=Win7SP1x64 clipboard
```

### Volatility 3

```bash
# Faster and easier
vol -f memory.dump windows.info
vol -f memory.dump windows.pslist
vol -f memory.dump windows.pstree
vol -f memory.dump windows.cmdline
vol -f memory.dump windows.netscan
vol -f memory.dump windows.filescan
```

## Disk Forensics

### Disk Image Analysis

```bash
# Mount disk image
sudo mount -o loop,ro disk.img /mnt/disk

# Analyze with Autopsy
autopsy  # Web-based GUI

# Sleuth Kit commands
mmls disk.img  # List partitions
fls disk.img  # List files
icat disk.img 123  # Extract file by inode

# Search for deleted files
fls -r -d disk.img

# Timeline
fls -r -m / disk.img > timeline.csv
```

### File System Analysis

```bash
# TestDisk - recover partitions
testdisk disk.img

# PhotoRec - recover files
photorec disk.img

# Strings on disk image
strings disk.img | grep -i "flag"
```

### Partition Analysis

```bash
# List partitions
fdisk -l disk.img
parted disk.img print

# Calculate offset for mounting
# offset = start_sector * sector_size
sudo mount -o loop,ro,offset=2048 disk.img /mnt
```

## Tools

### Essential Forensics Tools

```bash
# Install on Kali Linux
sudo apt update
sudo apt install -y \
    binwalk foremost exiftool \
    steghide stegosuite \
    wireshark tshark \
    volatility3 \
    autopsy sleuthkit \
    testdisk photorec \
    audacity sonic-visualiser

# Python tools
pip3 install pillow
pip3 install stegano
pip3 install scipy numpy matplotlib  # Audio analysis
```

### Specialized Tools

```bash
# zsteg - PNG/BMP steganography
gem install zsteg

# stegseek - fast steghide cracker
sudo apt install stegseek

# pngcheck
sudo apt install pngcheck

# outguess
sudo apt install outguess

# sonic-visualiser
sudo apt install sonic-visualiser
```

### Online Tools

- **CyberChef** - https://gchq.github.io/CyberChef/
- **Forensically** - https://29a.ch/photo-forensics/
- **EXIF Viewer** - http://exif.regex.info/
- **Spectral Audio Analyzer** - https://academo.org/demos/spectrum-analyzer/

## Common Techniques

### 1. Always Start with File Identification

```bash
file unknown_file
strings unknown_file | head -20
```

### 2. Check for Multiple Files

```bash
binwalk unknown_file
# Files often concatenated
```

### 3. Examine Metadata

```bash
exiftool file
# Check all fields, especially comments
```

### 4. Try Extraction Tools

```bash
binwalk -e file
foremost -i file -o output/
```

### 5. For Images, Try All Steganography Tools

```bash
strings image.jpg | grep flag
steghide info image.jpg
zsteg image.png
stegsolve  # GUI with filters
```

### 6. For Audio, Check Spectrogram

- Open in Audacity
- Spectrogram view
- Look for visual patterns

### 7. For PCAP, Follow Streams

- HTTP objects
- TCP streams
- Look for file transfers

### 8. Don't Trust File Extensions

```bash
# File might be renamed
file suspicious.txt  # Might actually be a zip
```

## CTF-Specific Tips

### Hidden Data Locations

1. **Image Files**

   - EXIF metadata
   - LSB of pixels
   - Custom PNG chunks
   - Appended data after EOF
   - Palette
   - Alpha channel

2. **Audio Files**

   - Spectrogram
   - LSB of samples
   - Morse code in tones
   - DTMF tones
   - Phase encoding

3. **Archives**

   - Encrypted zip (weak passwords)
   - Multiple files with parts
   - Steg in images inside archive

4. **PDF Files**
   - Embedded objects
   - Commented out text
   - Hidden layers
   - JavaScript code

### Quick Wins

```bash
# Strings with context
strings -n 8 file | grep -C 3 -i "flag\|ctf\|password"

# Multiple extraction attempts
binwalk -e file && foremost -i file -o out/

# Check everything
exiftool file && file file && xxd file | head

# For images
zsteg -a image.png
steghide info image.jpg
```

### When Stuck

1. Look at challenge name/description for hints
2. Try reversing or rotating data
3. Check for alternate data streams (NTFS)
4. Look for null bytes or padding
5. Try XOR with common keys
6. Search for file signatures in hex
7. Google the format/technique mentioned

## Practice Resources

- **PicoCTF** - Beginner-friendly forensics
- **HackTheBox** - Forensics challenges
- **Root-Me** - Steganography section
- **OverTheWire** - Krypton and Bandit have some forensics

## Quick Command Reference

```bash
# File analysis
file, strings, binwalk, foremost, exiftool

# Images
steghide, zsteg, stegsolve, exiftool

# Audio
audacity, sonic-visualiser, sox

# Network
wireshark, tshark

# Memory
volatility, vol

# Disk
autopsy, testdisk, photorec

# Hex
xxd, hexdump, hexedit

# Archives
unzip, tar, 7z, unrar
```

Remember: Forensics is about being thorough and methodical. Check everything!
