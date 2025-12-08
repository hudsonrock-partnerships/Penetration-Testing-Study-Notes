# CTF (Capture The Flag) Guide

A comprehensive guide for competing in CTF competitions with practical techniques, tools, and methodologies.

## Table of Contents

- [Getting Started](#getting-started)
- [CTF Categories](#ctf-categories)
- [Essential Tools Setup](#essential-tools-setup)
- [General CTF Tips](#general-ctf-tips)
- [Resources](#resources)

## Getting Started

### What is CTF?

CTF (Capture The Flag) competitions are cybersecurity challenges where participants solve security-related puzzles to find hidden "flags" (strings of text). There are two main types:

1. **Jeopardy-style**: Solve individual challenges across different categories
2. **Attack-Defense**: Protect your services while attacking opponents' services

### CTF Platforms

- [CTFtime](https://ctftime.org/) - Schedule and rankings of CTF competitions
- [HackTheBox](https://www.hackthebox.com/) - Penetration testing labs
- [TryHackMe](https://tryhackme.com/) - Guided security challenges
- [PicoCTF](https://picoctf.org/) - Beginner-friendly CTF
- [OverTheWire](https://overthewire.org/) - Wargames for learning security
- [Root-Me](https://www.root-me.org/) - Hacking challenges
- [CryptoHack](https://cryptohack.org/) - Cryptography challenges
- [Pwn.College](https://pwn.college/) - Binary exploitation education
- [VulnHub](https://www.vulnhub.com/) - Vulnerable VMs for practice

## CTF Categories

1. [**Web Exploitation**](./web-exploitation.md) - Exploiting web application vulnerabilities
2. [**Cryptography**](./cryptography.md) - Breaking encryption and encoding
3. [**Forensics**](./forensics.md) - Analyzing files, memory dumps, and network captures
4. [**Binary Exploitation (Pwn)**](./binary-exploitation.md) - Exploiting binary vulnerabilities
5. [**Reverse Engineering**](./reverse-engineering.md) - Understanding how programs work
6. [**OSINT**](./osint.md) - Open Source Intelligence gathering
7. [**Steganography**](./steganography.md) - Finding hidden data in files
8. [**Miscellaneous**](./miscellaneous.md) - Other challenges (scripting, logic, etc.)

## Essential Tools Setup

### Docker Setup (Recommended)

Create a CTF environment with all tools pre-installed:

```bash
# Pull a CTF tools container
docker pull ctf/tools

# Or create your own
cat > Dockerfile << 'EOF'
FROM kalilinux/kali-rolling
RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    binwalk foremost exiftool \
    john hashcat hydra \
    nmap nikto sqlmap \
    ghidra radare2 gdb \
    wireshark tshark \
    steghide stegsolve \
    git curl wget netcat \
    && rm -rf /var/lib/apt/lists/*
EOF

docker build -t my-ctf-env .
docker run -it --rm -v $(pwd):/ctf my-ctf-env
```

### Essential Tool Categories

**Analysis & Debugging**

```bash
# Python libraries
pip3 install pwntools requests beautifulsoup4 pycryptodome

# Binary analysis
apt install gdb radare2 ghidra
pip3 install ropper angr
```

**Web Tools**

```bash
# Burp Suite Community (download from portswigger.net)
# OWASP ZAP
apt install zaproxy
# Browser extensions
# - Wappalyzer, FoxyProxy, Cookie-Editor
```

**Crypto Tools**

```bash
pip3 install pycryptodome gmpy2 primefac
apt install hashcat john
```

**Forensics Tools**

```bash
apt install binwalk foremost exiftool volatility
pip3 install scapy
```

**Networking**

```bash
apt install nmap wireshark tshark netcat
```

## General CTF Tips

### 1. Read the Challenge Description Carefully

- Look for hints in the title, description, and tags
- Check file names and metadata
- Note the point value (usually correlates with difficulty)

### 2. Start with What You Know

- Use `file` command to identify file types
- Run `strings` on binaries
- Check for common encodings (base64, hex, rot13)
- Look at file metadata with `exiftool`

### 3. Google is Your Friend

- Search for error messages
- Look up unfamiliar algorithms or techniques
- Find writeups of similar challenges (after the CTF)

### 4. Take Notes

- Document your findings
- Keep track of what you've tried
- Note interesting techniques for future challenges

### 5. Common First Steps by Category

**Web:**

```bash
# View source code
curl -v https://target.com
# Check robots.txt, sitemap.xml
# Test for SQLi: ' OR 1=1--
# Check cookies and JWT tokens
# Use Burp Suite to intercept requests
```

**Crypto:**

```bash
# Identify cipher type
# Check for common weaknesses (small keys, reused nonces)
# Try known-plaintext attacks
# Use online tools: dcode.fr, CyberChef
```

**Forensics:**

```bash
# Check file type and strings
file suspicious_file
strings suspicious_file | grep -i flag
# Extract embedded files
binwalk -e suspicious_file
foremost suspicious_file
# Check metadata
exiftool suspicious_file
```

**Binary/Pwn:**

```bash
# Check protections
checksec binary
# Disassemble
objdump -d binary
radare2 binary
# Find vulnerabilities
# Test with fuzzing input
```

**Reverse Engineering:**

```bash
# Decompile
ghidra binary  # or IDA, Binary Ninja
# Dynamic analysis
ltrace ./binary
strace ./binary
gdb ./binary
```

### 6. Common Flag Formats

- `flag{...}` or `FLAG{...}`
- `CTF{...}`
- `picoCTF{...}`
- Custom format specified in challenge

### 7. When You're Stuck

- Take a break and come back fresh
- Try a different challenge
- Collaborate with teammates
- Use hints if available (but try to minimize)
- Search for writeups after the competition ends

## Quick Reference Commands

```bash
# File analysis
file filename
strings filename
hexdump -C filename
xxd filename
exiftool filename

# Network
nc target.com 1234
nmap -sV -sC target.com
wireshark

# Web
curl -v http://target.com
burpsuite
nikto -h http://target.com

# Encoding/Decoding
echo "base64string" | base64 -d
echo "hexstring" | xxd -r -p

# Hashing
echo -n "password" | md5sum
hashcat -m 0 hash.txt wordlist.txt
john --wordlist=rockyou.txt hash.txt

# Binary
gdb ./binary
objdump -d binary
strings binary | grep flag

# Extraction
binwalk -e file
foremost file
steghide extract -sf image.jpg
```

## Resources

### Learning Platforms

- [CTF101](https://ctf101.org/) - CTF fundamentals
- [PentesterLab](https://pentesterlab.com/) - Web pentesting
- [Nightmare](https://guyinatuxedo.github.io/) - Binary exploitation

### Tools Collections

- [CTF Tools](https://github.com/zardus/ctf-tools) - Installer for CTF tools
- [pwntools](https://github.com/Gallopsled/pwntools) - CTF framework
- [CyberChef](https://gchq.github.io/CyberChef/) - Data analysis and decoding

### Writeups

- [CTFtime Writeups](https://ctftime.org/writeups) - Past CTF solutions
- [GitHub CTF Writeups](https://github.com/topics/ctf-writeups) - Community solutions

### Cheat Sheets

- [HackTricks](https://book.hacktricks.xyz/) - Penetration testing wiki
- [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings) - Useful payloads

### Practice

- Do challenges regularly (even 30 mins/day helps)
- Join a CTF team or find teammates
- Participate in weekly CTFs
- Practice on platforms like HackTheBox and TryHackMe
- Read writeups to learn new techniques

---

**Good luck and happy hacking! 🚩**
