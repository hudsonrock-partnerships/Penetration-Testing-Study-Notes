# Cryptography - CTF Guide

Cryptography challenges involve breaking encryption schemes, analyzing ciphers, and finding weaknesses in implementations.

## Table of Contents

- [Common Ciphers](#common-ciphers)
- [Encoding vs Encryption](#encoding-vs-encryption)
- [Hashing](#hashing)
- [Modern Cryptography](#modern-cryptography)
- [Tools](#tools)
- [Common Attacks](#common-attacks)

## Common Ciphers

### Classical Ciphers

#### Caesar Cipher (ROT)

Shift each letter by a fixed number.

```python
# ROT13 (shift by 13)
import codecs
text = "Uryyb Jbeyq"
print(codecs.decode(text, 'rot_13'))  # Hello World

# Try all rotations
def caesar_bruteforce(ciphertext):
    for shift in range(26):
        plaintext = ""
        for char in ciphertext:
            if char.isalpha():
                shifted = ord(char) - shift
                if char.isupper():
                    if shifted < ord('A'):
                        shifted += 26
                else:
                    if shifted < ord('a'):
                        shifted += 26
                plaintext += chr(shifted)
            else:
                plaintext += char
        print(f"Shift {shift}: {plaintext}")
```

**Online Tool:** https://www.dcode.fr/caesar-cipher

#### Substitution Cipher

Replace each letter with another letter.

```bash
# Frequency analysis helps
# Most common English letters: E T A O I N S H R D L U
```

**Online Tool:** https://www.dcode.fr/monoalphabetic-substitution

#### Vigenère Cipher

Uses a keyword to shift letters.

```python
# Decrypt with key
def vigenere_decrypt(ciphertext, key):
    plaintext = ""
    key_length = len(key)
    for i, char in enumerate(ciphertext):
        if char.isalpha():
            shift = ord(key[i % key_length].upper()) - ord('A')
            if char.isupper():
                plaintext += chr((ord(char) - ord('A') - shift) % 26 + ord('A'))
            else:
                plaintext += chr((ord(char) - ord('a') - shift) % 26 + ord('a'))
        else:
            plaintext += char
    return plaintext
```

**Online Tool:** https://www.dcode.fr/vigenere-cipher

#### Atbash Cipher

A ↔ Z, B ↔ Y, etc.

```python
def atbash(text):
    result = ""
    for char in text:
        if char.isalpha():
            if char.isupper():
                result += chr(ord('Z') - (ord(char) - ord('A')))
            else:
                result += chr(ord('z') - (ord(char) - ord('a')))
        else:
            result += char
    return result
```

#### Rail Fence Cipher

Write text in zigzag pattern.

**Online Tool:** https://www.dcode.fr/rail-fence-cipher

## Encoding vs Encryption

### Base64

```bash
# Encode
echo -n "Hello World" | base64
# SGVsbG8gV29ybGQ=

# Decode
echo "SGVsbG8gV29ybGQ=" | base64 -d
# Hello World

# Sometimes multiple layers
echo "flag" | base64 | base64 | base64
```

### Hexadecimal

```bash
# Decode hex
echo "48656c6c6f" | xxd -r -p
# Hello

# Encode to hex
echo -n "Hello" | xxd -p
```

### Binary

```python
# Binary to text
binary = "01001000 01100101 01101100 01101100 01101111"
text = ''.join(chr(int(b, 2)) for b in binary.split())
print(text)  # Hello

# Text to binary
text = "Hello"
binary = ' '.join(format(ord(c), '08b') for c in text)
print(binary)
```

### URL Encoding

```bash
# Decode
python3 -c "import urllib.parse; print(urllib.parse.unquote('%48%65%6c%6c%6f'))"
# Hello
```

### ASCII Values

```python
# ASCII to text
ascii_values = [72, 101, 108, 108, 111]
text = ''.join(chr(i) for i in ascii_values)
print(text)  # Hello
```

## Hashing

### Common Hash Types

```bash
# Identify hash type
# MD5: 32 characters (e.g., 5d41402abc4b2a76b9719d911017c592)
# SHA-1: 40 characters
# SHA-256: 64 characters
# SHA-512: 128 characters

# Crack hashes
# Online: https://crackstation.net/
# Online: https://hashes.com/

# Using hashcat
hashcat -m 0 hash.txt rockyou.txt  # MD5
hashcat -m 100 hash.txt rockyou.txt  # SHA1
hashcat -m 1400 hash.txt rockyou.txt  # SHA256

# Using john
john --wordlist=rockyou.txt --format=Raw-MD5 hash.txt
```

### Hash Length Extension Attack

If a system uses `H(secret || data)` for authentication:

```python
# Using hashpump tool
hashpump -s <original_hash> -d <original_data> -a <data_to_append> -k <key_length>
```

## Modern Cryptography

### RSA

**Common Attacks:**

1. **Small Exponent (e=3)**

```python
import gmpy2

# If c^3 is close to n, take cube root
c = 12345678901234567890
n = 98765432109876543210
e = 3

# Try small multiple of n
for k in range(100):
    m, exact = gmpy2.iroot(c + k * n, e)
    if exact:
        print(f"Found message: {m}")
        print(f"Text: {bytes.fromhex(hex(m)[2:])}")
        break
```

2. **Common Modulus Attack**

```python
# If same message encrypted with different e but same n
# Can recover plaintext without private key
```

3. **Wiener's Attack** (small private exponent)

```python
# Use online tools or wiener attack script
```

4. **Factoring Small n**

```bash
# Online factorization
# http://factordb.com/

# Using msieve
msieve -v <n_value>

# Using yafu
yafu "factor(<n_value>)"
```

**RSA Decryption (if you have d):**

```python
from Crypto.Util.number import long_to_bytes

c = 12345678901234567890  # Ciphertext
n = 98765432109876543210  # Modulus
d = 12345678901234567890  # Private exponent

m = pow(c, d, n)
print(long_to_bytes(m))
```

### AES

**Modes of Operation:**

- **ECB** (Electronic Codebook) - Insecure, same plaintext → same ciphertext
- **CBC** (Cipher Block Chaining) - Vulnerable to padding oracle
- **CTR** (Counter) - Stream cipher mode
- **GCM** (Galois/Counter Mode) - Authenticated encryption

**ECB Detection:**

```python
# If you see repeating blocks, it's likely ECB
from Crypto.Cipher import AES
# Exploit by detecting patterns
```

**Padding Oracle Attack:**

```python
# If server reveals padding errors
# Can decrypt ciphertext byte by byte
# Tool: PadBuster
```

### XOR

**Properties:**

- A ⊕ A = 0
- A ⊕ 0 = A
- A ⊕ B ⊕ B = A

**Single-byte XOR Bruteforce:**

```python
def xor_bruteforce(ciphertext):
    for key in range(256):
        plaintext = ''.join(chr(b ^ key) for b in ciphertext)
        if all(32 <= ord(c) <= 126 for c in plaintext):
            print(f"Key {key}: {plaintext}")

# From hex
ct = bytes.fromhex("1c0111001f010100061a024b53535009181c")
xor_bruteforce(ct)
```

**Known Plaintext Attack:**

```python
# If you know plaintext and ciphertext
# Key = plaintext XOR ciphertext
plaintext = b"flag{"
ciphertext = bytes.fromhex("1c0111001f")
key = bytes(p ^ c for p, c in zip(plaintext, ciphertext))
print(key)
```

**Repeating Key XOR:**

```python
def repeating_xor_decrypt(ciphertext, key):
    plaintext = b''
    for i, byte in enumerate(ciphertext):
        plaintext += bytes([byte ^ key[i % len(key)]])
    return plaintext

# Break with known plaintext
# If plaintext starts with "flag{" or "CTF{"
```

## Tools

### Online Tools

- **CyberChef** - https://gchq.github.io/CyberChef/

  - Swiss army knife for encoding/decoding
  - Can chain operations

- **dCode** - https://www.dcode.fr/

  - Cipher identification and decryption
  - Classical ciphers

- **CrackStation** - https://crackstation.net/

  - Hash cracking

- **FactorDB** - http://factordb.com/

  - Integer factorization database

- **RsaCtfTool** - https://github.com/Ganapati/RsaCtfTool
  - Automated RSA attack tool

### Command Line Tools

```bash
# OpenSSL
openssl rsautl -decrypt -inkey private.pem -in encrypted.txt

# Python libraries
pip3 install pycryptodome  # Modern crypto
pip3 install gmpy2  # Big integer math
pip3 install primefac  # Prime factorization

# Hashcat
hashcat -m <mode> hash.txt wordlist.txt

# John the Ripper
john --wordlist=rockyou.txt hash.txt

# RsaCtfTool
python3 RsaCtfTool.py -n <n> -e <e> --uncipher <c>
```

### Python Scripts

```python
from Crypto.Util.number import *
from Crypto.Cipher import AES
from gmpy2 import *
import base64

# RSA basics
p, q = 61, 53
n = p * q
phi = (p - 1) * (q - 1)
e = 17
d = inverse(e, phi)

# Encrypt
m = bytes_to_long(b"Hello")
c = pow(m, e, n)

# Decrypt
m = pow(c, d, n)
print(long_to_bytes(m))

# AES
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad

key = b'Sixteen byte key'
cipher = AES.new(key, AES.MODE_ECB)

# Encrypt
plaintext = pad(b"Hello World", 16)
ciphertext = cipher.encrypt(plaintext)

# Decrypt
plaintext = unpad(cipher.decrypt(ciphertext), 16)
```

## Common Attacks

### 1. Frequency Analysis

For substitution ciphers, analyze letter frequency:

```
English: E T A O I N S H R D L U (most common)
```

### 2. Known Plaintext

If you know part of the plaintext:

- XOR: key = plaintext ⊕ ciphertext
- Can help determine encryption method

### 3. Chosen Plaintext

If you can encrypt arbitrary text:

- ECB block reordering
- Bit flipping in CBC mode

### 4. Padding Oracle

If server reveals padding errors:

- Decrypt entire ciphertext
- Use PadBuster tool

### 5. Timing Attacks

If decryption time varies:

- Can reveal information about key

### 6. Weak Random Number Generators

- Predict future values
- Recover seed

## Common CTF Patterns

### 1. Identify the Cipher

```bash
# Look for patterns
# Base64: ends with = or ==
# Hex: only 0-9, a-f
# Binary: only 0 and 1
# Caesar: recognizable after rotation
```

### 2. Try Everything

```bash
# Decode base64 multiple times
# Try all Caesar rotations
# Check for XOR with common keys
```

### 3. Look for Hints

- Challenge name or description
- File names
- Comments in source code

### 4. Use Automated Tools

```bash
# CyberChef - try automatic detection
# dCode - cipher identifier
# RsaCtfTool - for RSA challenges
```

## Practice Resources

- **CryptoHack** - https://cryptohack.org/
- **CryptoPals** - https://cryptopals.com/
- **OverTheWire Krypton** - https://overthewire.org/wargames/krypton/
- **MysteryTwister C3** - https://www.mysterytwisterc3.org/

## Quick Reference

```python
# Common operations
import base64
import codecs
from Crypto.Util.number import *

# Base64
base64.b64encode(b"text")
base64.b64decode(b"dGV4dA==")

# Hex
bytes.fromhex("48656c6c6f")
b"Hello".hex()

# ROT13
codecs.decode("text", 'rot_13')

# Long to bytes (RSA)
long_to_bytes(12345)
bytes_to_long(b"Hello")

# XOR
a ^ b

# Power mod (RSA)
pow(base, exponent, modulus)
```

Remember: In CTF, if standard crypto looks too strong, look for implementation weaknesses!
