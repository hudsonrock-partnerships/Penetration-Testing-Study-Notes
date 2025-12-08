# Reverse Engineering - CTF Guide

Reverse engineering involves analyzing compiled programs to understand their functionality without source code.

## Table of Contents

- [Getting Started](#getting-started)
- [Static Analysis](#static-analysis)
- [Dynamic Analysis](#dynamic-analysis)
- [Tools](#tools)
- [Common Techniques](#common-techniques)
- [Platform-Specific](#platform-specific)

## Getting Started

### Basic Workflow

1. **Identify the binary** - File type, architecture, protections
2. **Static analysis** - Disassemble, decompile, analyze code
3. **Dynamic analysis** - Run, debug, trace execution
4. **Understand logic** - Find the check, flag generation, or vulnerability
5. **Extract/bypass** - Get the flag

### Initial Analysis

```bash
# File type and info
file binary
strings binary | grep -i flag

# Check architecture and properties
rabin2 -I binary

# Check for packing/obfuscation
upx -d binary  # Try to unpack if UPX
```

## Static Analysis

### Disassembly Tools

#### Radare2

```bash
# Open binary
r2 binary

# Analyze
aaa  # Analyze all
afl  # List functions
pdf @main  # Disassemble main
VV  # Visual graph mode

# Search
/ flag  # Search for string
/c printf  # Search for code
/R pop rdi  # Search for ROP gadgets

# Helpful commands
ii  # List imports
iz  # List strings
iS  # List sections
```

#### Objdump

```bash
# Disassemble
objdump -d binary

# Disassemble specific function
objdump -d binary | grep -A 50 '<main>'

# All headers
objdump -x binary

# Dynamic symbols
objdump -T binary
```

#### GDB Disassembly

```bash
gdb binary
disassemble main
disass /r main  # With raw bytes
set disassembly-flavor intel
```

### Decompilers

#### Ghidra

```bash
# Free NSA tool, very powerful
# Download from https://ghidra-sre.org/

# Features:
# - Decompilation to C-like code
# - Symbol renaming
# - Function signatures
# - Cross-references
# - Scripting support
```

**Ghidra workflow:**

1. Create new project
2. Import binary
3. Analyze (accept defaults)
4. Navigate to main() or entry point
5. Read decompiled code
6. Rename variables for clarity
7. Follow function calls

#### Binary Ninja

```bash
# Commercial tool with free Cloud version
# https://cloud.binary.ninja/

# Features:
# - Clean UI
# - Good decompiler
# - IL (Intermediate Language) views
```

#### IDA Pro / IDA Free

```bash
# Industry standard (expensive)
# IDA Free: https://hex-rays.com/ida-free/

# Features:
# - Excellent disassembler
# - Decompiler (Pro only)
# - Extensible with Python
```

### Reading Assembly

#### x86-64 Basics

```asm
; Common instructions
mov rax, rbx    ; Move data
add rax, 5      ; Add
sub rax, 5      ; Subtract
xor rax, rax    ; XOR (often used to zero register)
push rax        ; Push to stack
pop rax         ; Pop from stack
call func       ; Call function
ret             ; Return from function
jmp addr        ; Unconditional jump
je addr         ; Jump if equal
jne addr        ; Jump if not equal
cmp rax, rbx    ; Compare (sets flags)
test rax, rax   ; Test (AND without storing, sets flags)

; Registers (x86-64)
rax, rbx, rcx, rdx  ; General purpose
rsi, rdi            ; Source/Destination index
rsp, rbp            ; Stack/Base pointer
rip                 ; Instruction pointer
```

#### ARM Basics

```asm
; Common instructions
mov r0, r1      ; Move
add r0, r1, #5  ; Add
sub r0, r1, #5  ; Subtract
ldr r0, [r1]    ; Load from memory
str r0, [r1]    ; Store to memory
bl func         ; Branch with link (call)
bx lr           ; Branch to link register (return)
cmp r0, r1      ; Compare
beq label       ; Branch if equal
```

## Dynamic Analysis

### Debugging with GDB

```bash
# Start GDB
gdb ./binary

# Set Intel syntax
set disassembly-flavor intel

# Set breakpoints
break main
break *0x400000
break strcmp

# Run
run arg1 arg2
run < input.txt

# Stepping
step (s)     # Step into
next (n)     # Step over
finish       # Step out
continue (c) # Continue execution

# Examine memory
x/s $rdi            # String at RDI
x/20x $rsp          # 20 hex values from stack
x/20i $rip          # 20 instructions from current
x/gx 0x400000       # Examine as 64-bit value

# Registers
info registers
print $rax
set $rax = 0x1337

# Stack
backtrace (bt)
frame 0

# Memory mappings
info proc mappings  # or vmmap with pwndbg
```

### GDB with Pwndbg/GEF

Enhanced GDB with better visualization:

```bash
# Pwndbg commands
context         # Show context (regs, stack, code)
telescope $rsp  # Dereference pointers
vmmap          # Memory map
search flag     # Search memory
checksec       # Check protections
cyclic 100     # Pattern generation
cyclic -l addr # Find pattern offset
```

### Ltrace & Strace

```bash
# Library call tracing
ltrace ./binary
ltrace -s 100 ./binary  # String length

# System call tracing
strace ./binary
strace -e trace=open,read ./binary  # Specific syscalls

# Follow forks
strace -f ./binary
```

### Frida (Dynamic Instrumentation)

```javascript
// Attach to process
frida -l script.js ./binary

// script.js - Hook function
Interceptor.attach(Module.findExportByName(null, "strcmp"), {
  onEnter: function(args) {
    console.log("strcmp called");
    console.log("Arg1: " + Memory.readUtf8String(args[0]));
    console.log("Arg2: " + Memory.readUtf8String(args[1]));
  },
  onLeave: function(retval) {
    console.log("Return: " + retval);
    retval.replace(0);  // Make it always return 0 (equal)
  }
});
```

## Tools

### Essential RE Tools

```bash
# Static analysis
ghidra          # Decompiler (NSA)
radare2 (r2)    # Disassembler
objdump         # Binutils disassembler
strings         # Extract strings

# Decompilers
ghidra
ida-free
binary ninja cloud

# Dynamic analysis
gdb + pwndbg    # Debugger
ltrace          # Library trace
strace          # System call trace
frida           # Dynamic instrumentation

# Hex editors
hexedit
xxd
hex-editor (GUI)

# Python libraries
pip3 install capstone  # Disassembler
pip3 install keystone  # Assembler
pip3 install unicorn   # Emulator
```

### Platform-Specific Tools

```bash
# .NET
dnSpy          # .NET decompiler
ilspy          # Alternative

# Java
jd-gui         # Java decompiler
jadx           # Android/Java decompiler

# Python
uncompyle6     # Decompile .pyc
pycdc          # Alternative

# Android
apktool        # APK unpacker
jadx           # Decompiler
androguard     # Analysis

# iOS
class-dump     # Dump class info
Hopper         # Disassembler
```

## Common Techniques

### 1. String Analysis

```bash
# Find interesting strings
strings binary | grep -i "password\|flag\|key"

# In radare2
iz | grep flag

# In Ghidra
Window → Defined Strings
```

### 2. Function Identification

Look for common patterns:

```c
// Main function characteristics
// - Called from _start or __libc_start_main
// - Usually 2-3 arguments
// - First real code after library init

// Input functions
scanf, gets, read, fgets, recv

// Output functions
printf, puts, write, send

// Crypto functions
MD5_Init, SHA256, AES_encrypt

// String comparison
strcmp, strncmp, memcmp
```

### 3. Control Flow Analysis

```bash
# In Ghidra/IDA
# Look at function graph
# Identify loops, conditionals
# Find the "good" vs "bad" branches

# Common patterns
if (input == expected) {
    printf("Correct!");
} else {
    printf("Wrong!");
}

# Just patch the jump!
# Change je to jmp, or jne to nop
```

### 4. Patching Binaries

```bash
# Using radare2
r2 -w binary    # Write mode
s 0x400000      # Seek to address
wx 9090         # Write NOPs
wa jmp 0x400500 # Write assembly

# Using Python
with open('binary', 'r+b') as f:
    f.seek(0x1234)
    f.write(b'\x90\x90')  # NOP NOP

# Using hex editor
hexedit binary
# Navigate and modify bytes
```

### 5. Anti-Debugging Detection

```c
// Common anti-debug techniques

// ptrace check (Linux)
if (ptrace(PTRACE_TRACEME, 0, 1, 0) < 0) {
    // Being debugged
}

// Timing checks
start = time();
// Some code
if (time() - start > threshold) {
    // Being debugged
}

// Bypass: Patch the check or modify return values
```

### 6. Obfuscation Techniques

```bash
# String obfuscation
# - XOR encoding
# - Base64
# - Stack strings (built character by character)

# Control flow obfuscation
# - Fake branches
# - Opaque predicates
# - Control flow flattening

# Packing
# - UPX, custom packers
# - Try: upx -d binary
```

## Platform-Specific

### Windows PE Analysis

```bash
# PE header info
pecheck binary.exe
pefile binary.exe

# Imports/Exports
objdump -p binary.exe

# Strings
strings binary.exe
strings -el binary.exe  # UTF-16LE
```

**Common Windows API:**

```c
// Input
GetUserInput, ReadConsoleA

// Output
MessageBoxA, WriteConsoleA

// Crypto
CryptEncrypt, CryptDecrypt

// Registry
RegOpenKeyA, RegQueryValueA

// File
CreateFileA, ReadFile, WriteFile
```

### Android APK

```bash
# Unpack APK
apktool d app.apk

# Decompile to Java
jadx app.apk

# Convert dex to jar
d2j-dex2jar classes.dex

# Decompile jar
jd-gui classes-dex2jar.jar

# Main code location
# app.apk/smali/ (bytecode)
# app.apk/res/ (resources)
# app.apk/AndroidManifest.xml
```

### Python Bytecode

```bash
# Decompile .pyc
uncompyle6 script.pyc

# Or
pycdc script.pyc

# Or disassemble
python3 -m dis script.pyc
```

### .NET Applications

```bash
# Decompile with dnSpy
# Download from https://github.com/dnSpy/dnSpy

# Or ilspy
ilspycmd binary.exe

# Resulting C# code is usually very readable
```

### Java

```bash
# Decompile class files
jd-gui app.jar

# Or
jadx app.jar

# Or manually
javap -c MyClass.class  # Disassemble
```

## CTF-Specific Strategies

### 1. Quick Wins

```bash
# Check strings first
strings binary | grep -i "flag{\\|ctf{"

# Look for debug symbols
nm binary | grep -i flag

# Check for easy patches
# Find the comparison, patch the jump
```

### 2. Common CTF Patterns

```c
// Password check
if (strcmp(input, password) == 0)

// Serial/Key validation
if (validate_key(input))

// License check
if (check_license(name, serial))

// Flag generation
generate_flag(input)
```

### 3. When Stuck

1. **Run the binary** - See what it does
2. **Trace it** - ltrace to see library calls
3. **Find strings** - Look for hints
4. **Find main** - Start reading from entry point
5. **Graph it** - Use Ghidra's function graph
6. **Rename** - Rename variables to understand logic
7. **Emulate** - Write Python to replicate logic
8. **Patch** - Sometimes easier to patch than fully understand

### 4. Common Flag Formats

```python
# Flag might be:
# 1. Hardcoded string
# 2. Generated from input
# 3. Decrypted from ciphertext
# 4. Built from multiple pieces

# Look for:
# - String operations (strcat, sprintf)
# - Crypto functions
# - XOR operations
# - Base64 encoding
```

## Practice Resources

- **Crackmes.one** - https://crackmes.one/
- **Reversing.kr** - http://reversing.kr/
- **Root-Me** - https://www.root-me.org/
- **HackTheBox** - Reversing challenges
- **Microcorruption** - https://microcorruption.com/ (embedded)

## Quick Reference

```bash
# Analysis
file, strings, nm, objdump, readelf, rabin2

# Disassembly
r2, ghidra, ida, objdump

# Debugging
gdb, ltrace, strace

# Decompilers (by platform)
Windows: ghidra, ida
.NET: dnSpy, ilspy
Java: jd-gui, jadx
Python: uncompyle6, pycdc
Android: jadx, apktool

# Patching
r2 -w, hexedit, python

# Hex
xxd, hexdump, hexedit
```

**Radare2 essentials:**

```bash
aaa         # Analyze
afl         # List functions
pdf @main   # Disassemble main
VV          # Visual graph
/ flag      # Search
```

**GDB essentials:**

```bash
break main
run
disass
x/20x $rsp
info reg
continue
```

Remember: Reverse engineering is a skill that improves with practice. Start simple and work your way up!
