# Miscellaneous CTF Challenges

This category covers challenges that don't fit into other categories: programming, logic puzzles, trivia, networking, and more.

## Table of Contents

- [Programming Challenges](#programming-challenges)
- [Networking](#networking)
- [Scripting & Automation](#scripting--automation)
- [Logic Puzzles](#logic-puzzles)
- [Esoteric Programming Languages](#esoteric-programming-languages)
- [QR Codes & Barcodes](#qr-codes--barcodes)
- [Base Conversions](#base-conversions)

## Programming Challenges

### Common Patterns

1. **Socket Programming** - Connect to server, solve challenges
2. **Algorithmic** - Implement specific algorithm
3. **Parsing** - Parse and process data
4. **Timing** - Race conditions, time-sensitive operations

### Socket Communication

```python
#!/usr/bin/env python3
from pwn import *

# Connect
conn = remote('target.com', 1234)

# Receive prompt
data = conn.recvuntil(b':')
print(data.decode())

# Send response
conn.sendline(b'answer')

# Loop for multiple challenges
while True:
    try:
        # Receive challenge
        challenge = conn.recvline().strip()

        # Solve
        answer = solve(challenge)

        # Send answer
        conn.sendline(str(answer).encode())

    except:
        break

# Get flag
conn.interactive()
```

**Alternative with raw sockets:**

```python
import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(('target.com', 1234))

data = s.recv(1024)
print(data.decode())

s.send(b'answer\n')
s.close()
```

### Common Algorithms

**Math Operations:**

```python
# Fibonacci
def fib(n):
    if n <= 1:
        return n
    return fib(n-1) + fib(n-2)

# Prime check
def is_prime(n):
    if n < 2:
        return False
    for i in range(2, int(n**0.5) + 1):
        if n % i == 0:
            return False
    return True

# Factorial
def factorial(n):
    return 1 if n <= 1 else n * factorial(n-1)

# GCD
import math
math.gcd(a, b)
```

**String Operations:**

```python
# Reverse
s[::-1]

# Sort
''.join(sorted(s))

# Count characters
from collections import Counter
Counter(s)

# Anagram check
sorted(s1) == sorted(s2)
```

## Networking

### Packet Analysis

```bash
# Capture packets
tcpdump -i eth0 -w capture.pcap

# Analyze with Wireshark
wireshark capture.pcap

# Filter specific traffic
tshark -r capture.pcap -Y "tcp.port==80"

# Extract files
tshark -r capture.pcap --export-objects http,output/
```

### Network Services

```bash
# Test connection
nc target.com 1234
telnet target.com 1234

# HTTP requests
curl -v http://target.com
curl -X POST -d "data=value" http://target.com

# With headers
curl -H "Authorization: Bearer token" http://target.com

# Follow redirects
curl -L http://target.com
```

### DNS

```bash
# DNS lookup
dig example.com
nslookup example.com

# Specific records
dig example.com TXT
dig example.com MX

# DNS tunneling detection
# Look for unusual patterns in DNS queries
```

### Port Knocking

Sequence of connection attempts to specific ports.

```bash
# Knock sequence: 7000, 8000, 9000
nc -z target.com 7000
nc -z target.com 8000
nc -z target.com 9000

# Then access actual service
nc target.com 22
```

## Scripting & Automation

### Python Quick Snippets

```python
# Read file
with open('file.txt') as f:
    data = f.read()

# HTTP request
import requests
r = requests.get('http://target.com')
r = requests.post('http://target.com', data={'key': 'value'})

# JSON
import json
data = json.loads(json_string)
json_string = json.dumps(data)

# Regex
import re
matches = re.findall(r'flag{.*?}', text)

# Base64
import base64
encoded = base64.b64encode(b'data')
decoded = base64.b64decode(encoded)

# Execute command
import subprocess
result = subprocess.run(['ls', '-la'], capture_output=True, text=True)
print(result.stdout)
```

### Bash Automation

```bash
#!/bin/bash

# Loop over lines
while IFS= read -r line; do
    echo "Processing: $line"
done < input.txt

# Network automation
for port in {1..1000}; do
    nc -zv target.com $port 2>&1 | grep succeeded
done

# Parallel execution
cat urls.txt | xargs -P 10 -I {} curl {}

# Time-based
for i in {1..100}; do
    echo "Attempt $i"
    curl http://target.com/flag
    sleep 1
done
```

## Logic Puzzles

### Common Types

**Sudoku:**

```python
# Use constraint satisfaction solvers
# Or implement backtracking

def solve_sudoku(board):
    # Backtracking algorithm
    pass
```

**Graph Problems:**

```python
# Shortest path (Dijkstra, BFS)
from collections import deque

def bfs(graph, start, end):
    queue = deque([(start, [start])])
    visited = set()

    while queue:
        node, path = queue.popleft()
        if node == end:
            return path
        if node in visited:
            continue
        visited.add(node)

        for neighbor in graph[node]:
            queue.append((neighbor, path + [neighbor]))
```

**Logic Grid Puzzles:**

- Use constraint programming
- Or brute force with backtracking

### Constraint Satisfaction

```python
from constraint import *

problem = Problem()
problem.addVariable('var1', range(10))
problem.addVariable('var2', range(10))
problem.addConstraint(lambda a, b: a != b, ('var1', 'var2'))

solutions = problem.getSolutions()
```

## Esoteric Programming Languages

### Brainfuck

Only 8 commands: `>`, `<`, `+`, `-`, `.`, `,`, `[`, `]`

```bash
# Online interpreter
https://copy.sh/brainfuck/

# Example: Print 'A' (ASCII 65)
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ .
```

**Common patterns:**

```brainfuck
# Print 'H' (72)
++++++++[>+++++++++<-]>.

# Print "Hello World"
++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>.
```

### Whitespace

Uses only spaces, tabs, and newlines.

```bash
# Interpreter
https://vii5ard.github.io/whitespace/

# Or
python whitespace.py program.ws
```

### Piet

Programs are images where pixels represent commands.

```bash
# Interpreter
npiet program.png

# Online
https://www.bertnase.de/npiet/npiet-execute.php
```

### Malbolge

Intentionally difficult language.

```bash
# Online interpreter
http://www.malbolge.doleczek.pl/
```

### JSFuck

JavaScript using only 6 characters: `[]()!+`

```javascript
// Example
[][
  (![] + [])[+[]] +
    ([![]] + [][[]])[+!+[] + [+[]]] +
    (![] + [])[!+[] + !+[]] +
    (!![] + [])[+[]] +
    (!![] + [])[!+[] + !+[] + !+[]] +
    (!![] + [])[+!+[]]
];
```

**Online tools:**

- http://www.jsfuck.com/
- Use console to evaluate

## QR Codes & Barcodes

### QR Code

```bash
# Decode QR from image
zbarimg qrcode.png

# Or online
https://zxing.org/w/decode.jspx

# Generate QR code
qrencode -o output.png "text to encode"

# Python
pip install qrcode pillow
python3 << EOF
import qrcode
img = qrcode.make('flag{example}')
img.save('qr.png')
EOF

# Decode with Python
pip install pyzbar pillow
python3 << EOF
from pyzbar.pyzbar import decode
from PIL import Image
data = decode(Image.open('qr.png'))
print(data[0].data.decode())
EOF
```

### Barcode

```bash
# Decode barcode
zbarimg barcode.png

# Various formats:
# - UPC, EAN, Code 39, Code 128, QR, Data Matrix, etc.
```

### Damaged QR Codes

```python
# QR codes have error correction
# Can work even if partially damaged
# Try:
# 1. Clean up the image
# 2. Increase contrast
# 3. Reconstruct damaged parts
# 4. Try multiple decoders
```

## Base Conversions

### Number Systems

```python
# Binary to Decimal
int('1010', 2)  # 10

# Decimal to Binary
bin(10)  # '0b1010'
format(10, 'b')  # '1010'

# Hexadecimal
int('A', 16)  # 10
hex(10)  # '0xa'

# Octal
int('12', 8)  # 10
oct(10)  # '0o12'

# Any base
int('102', 3)  # Ternary: 11
```

### String Encodings

```python
# ASCII
chr(65)  # 'A'
ord('A')  # 65

# Binary string to text
binary = '01001000 01100101 01101100 01101100 01101111'
text = ''.join(chr(int(b, 2)) for b in binary.split())
# 'Hello'

# Hex string to text
hex_str = '48656c6c6f'
text = bytes.fromhex(hex_str).decode()
# 'Hello'

# Text to hex
'Hello'.encode().hex()
# '48656c6c6f'
```

## Common Misc Challenge Types

### 1. Speed Challenges

```python
# Server gives multiple challenges quickly
# Must automate response

from pwn import *

conn = remote('target.com', 1234)
for _ in range(100):
    challenge = conn.recvline()
    answer = solve(challenge)
    conn.sendline(answer)
flag = conn.recvline()
```

### 2. Encoding Chains

```python
# Data encoded multiple times
# Base64 → Hex → ROT13 → etc.

import base64
import codecs

data = "RmxhZ3toM3N0ZWRfZW5jb2Rpbmd9"
data = base64.b64decode(data)
data = bytes.fromhex(data.decode())
data = codecs.decode(data.decode(), 'rot_13')
```

### 3. Rate Limiting Bypass

```python
# Use multiple IPs or sessions
import requests
from concurrent.futures import ThreadPoolExecutor

def try_guess(password):
    r = requests.post('http://target.com/login',
                     data={'pass': password})
    return password if 'success' in r.text else None

with ThreadPoolExecutor(max_workers=10) as executor:
    results = executor.map(try_guess, wordlist)
```

### 4. Time-based Challenges

```python
# Must complete within time limit
import time

start = time.time()
# ... solve challenge ...
elapsed = time.time() - start
print(f"Completed in {elapsed} seconds")
```

## Tools

```bash
# General
python3, bash, nc, curl

# Network
wireshark, tshark, nmap, nc

# Decoding
CyberChef, base64, xxd

# QR/Barcode
zbar, qrencode, python-qrcode

# Esolangs
brainfuck interpreter, whitespace interpreter

# Automation
pwntools, requests, selenium
```

## Practice Resources

- **Advent of Code** - https://adventofcode.com/ (Programming puzzles)
- **Project Euler** - https://projecteuler.net/ (Math problems)
- **HackerRank** - https://www.hackerrank.com/ (Algorithms)
- **LeetCode** - https://leetcode.com/ (Data structures)

## Tips

1. **Automate everything** - If it's repetitive, script it
2. **Read the problem carefully** - Details matter
3. **Start simple** - Test with small examples first
4. **Use libraries** - Don't reinvent the wheel
5. **Time management** - Don't spend too long on one challenge
6. **Pattern recognition** - Look for common patterns
7. **Test incrementally** - Make sure each step works

## Quick Reference

```python
# Pwntools
from pwn import *
conn = remote('host', port)
conn.sendline(b'data')
conn.recvline()

# Requests
import requests
r = requests.get('http://url')
r = requests.post('http://url', data={})

# Encoding
import base64
base64.b64encode(b'data')
bytes.fromhex('48656c6c6f')

# Math
import math
math.gcd(a, b)
pow(base, exp, mod)

# Regex
import re
re.findall(r'pattern', text)
```

Remember: Misc challenges are diverse - be ready for anything!
