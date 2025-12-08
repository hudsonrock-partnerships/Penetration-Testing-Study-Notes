#!/bin/bash

# Full Recon Pipeline Script
# Automates subdomain enumeration, live host detection, port scanning, and vulnerability scanning
# Usage: ./full-recon.sh target.com

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if target provided
if [ $# -eq 0 ]; then
    echo -e "${RED}[!] Usage: $0 target.com${NC}"
    exit 1
fi

TARGET=$1
OUTPUT_DIR="${TARGET}_recon_$(date +%Y%m%d_%H%M%S)"

# Create output directory
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

echo -e "${GREEN}[+] Starting reconnaissance for ${TARGET}${NC}"
echo -e "${GREEN}[+] Output directory: ${OUTPUT_DIR}${NC}"

# Log file
LOG_FILE="recon.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print section header
print_section() {
    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}[*] $1${NC}"
    echo -e "${YELLOW}========================================${NC}"
}

# ==============================
# 1. SUBDOMAIN ENUMERATION
# ==============================
print_section "Phase 1: Subdomain Enumeration"

# Passive enumeration
if command_exists subfinder; then
    echo "[*] Running subfinder..."
    subfinder -d "$TARGET" -all -silent -o subdomains_subfinder.txt
fi

if command_exists assetfinder; then
    echo "[*] Running assetfinder..."
    assetfinder --subs-only "$TARGET" > subdomains_assetfinder.txt
fi

# Certificate transparency
echo "[*] Checking crt.sh..."
curl -s "https://crt.sh/?q=%.$TARGET&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u > subdomains_crtsh.txt 2>/dev/null || true

# Amass passive
if command_exists amass; then
    echo "[*] Running amass passive..."
    amass enum -passive -d "$TARGET" -o subdomains_amass.txt -timeout 10
fi

# Combine all results
echo "[*] Combining results..."
cat subdomains_*.txt 2>/dev/null | sort -u > subdomains_all.txt

SUBDOMAIN_COUNT=$(wc -l < subdomains_all.txt)
echo -e "${GREEN}[+] Found ${SUBDOMAIN_COUNT} unique subdomains${NC}"

# ==============================
# 2. LIVE HOST DETECTION
# ==============================
print_section "Phase 2: Live Host Detection"

if command_exists httpx; then
    echo "[*] Checking live hosts with httpx..."
    httpx -l subdomains_all.txt \
        -silent \
        -title \
        -tech-detect \
        -status-code \
        -ip \
        -cname \
        -mc 200,201,202,203,204,301,302,307,308,401,403,405,500 \
        -json \
        -o subdomains_live_detailed.json

    # Extract URLs
    cat subdomains_live_detailed.json | jq -r '.url' > subdomains_live.txt

    LIVE_COUNT=$(wc -l < subdomains_live.txt)
    echo -e "${GREEN}[+] Found ${LIVE_COUNT} live hosts${NC}"

    # Categorize by status
    cat subdomains_live_detailed.json | jq -r 'select(.["status_code"] == 200) | .url' > subdomains_200.txt
    cat subdomains_live_detailed.json | jq -r 'select(.["status_code"] == 403) | .url' > subdomains_403.txt
    cat subdomains_live_detailed.json | jq -r 'select(.["status_code"] == 401) | .url' > subdomains_401.txt
else
    echo -e "${RED}[!] httpx not found, skipping live host detection${NC}"
fi

# ==============================
# 3. PORT SCANNING
# ==============================
print_section "Phase 3: Port Scanning"

if command_exists naabu && [ -f subdomains_live.txt ]; then
    echo "[*] Scanning top 1000 ports with naabu..."
    naabu -l subdomains_live.txt -top-ports 1000 -silent -o ports.txt -rate 1000

    PORT_COUNT=$(wc -l < ports.txt)
    echo -e "${GREEN}[+] Found ${PORT_COUNT} open ports${NC}"
else
    echo -e "${RED}[!] naabu not found or no live hosts, skipping port scan${NC}"
fi

# ==============================
# 4. SCREENSHOT CAPTURE
# ==============================
print_section "Phase 4: Screenshot Capture"

if command_exists gowitness && [ -f subdomains_live.txt ]; then
    echo "[*] Capturing screenshots with gowitness..."
    mkdir -p screenshots
    gowitness file -f subdomains_live.txt --screenshot-path screenshots --timeout 15 2>/dev/null || true
    echo -e "${GREEN}[+] Screenshots saved in screenshots/${NC}"
else
    echo -e "${YELLOW}[!] gowitness not found or no live hosts, skipping screenshots${NC}"
fi

# ==============================
# 5. VULNERABILITY SCANNING
# ==============================
print_section "Phase 5: Vulnerability Scanning with Nuclei"

if command_exists nuclei && [ -f subdomains_live.txt ]; then
    echo "[*] Running nuclei vulnerability scan..."

    # Update templates
    echo "[*] Updating nuclei templates..."
    nuclei -update-templates -silent

    # Run scan
    nuclei -l subdomains_live.txt \
        -severity critical,high,medium \
        -silent \
        -o nuclei_findings.txt \
        -json \
        -je nuclei_findings.json \
        -rate-limit 100 \
        -bulk-size 25 \
        -c 10

    # Check if findings exist
    if [ -f nuclei_findings.txt ] && [ -s nuclei_findings.txt ]; then
        NUCLEI_COUNT=$(wc -l < nuclei_findings.txt)
        echo -e "${GREEN}[+] Found ${NUCLEI_COUNT} potential vulnerabilities${NC}"

        # Categorize by severity
        if [ -f nuclei_findings.json ]; then
            cat nuclei_findings.json | jq -r 'select(.info.severity == "critical")' > nuclei_critical.json 2>/dev/null || true
            cat nuclei_findings.json | jq -r 'select(.info.severity == "high")' > nuclei_high.json 2>/dev/null || true
        fi
    else
        echo "[*] No vulnerabilities found"
    fi
else
    echo -e "${YELLOW}[!] nuclei not found or no live hosts, skipping vulnerability scan${NC}"
fi

# ==============================
# 6. ADDITIONAL CHECKS
# ==============================
print_section "Phase 6: Additional Security Checks"

if [ -f subdomains_live.txt ]; then
    # Check for exposed git
    echo "[*] Checking for exposed .git directories..."
    while IFS= read -r url; do
        if curl -s "${url}/.git/HEAD" | grep -q "ref:"; then
            echo "[GIT] ${url}/.git/" >> exposed_git.txt
        fi
    done < subdomains_live.txt

    # Check for common files
    echo "[*] Checking for common exposed files..."
    for file in ".env" ".env.local" ".env.production" "config.php" "wp-config.php" ".aws/credentials"; do
        while IFS= read -r url; do
            status=$(curl -s -o /dev/null -w "%{http_code}" "${url}/${file}")
            if [ "$status" = "200" ]; then
                echo "[EXPOSED] ${url}/${file}" >> exposed_files.txt
            fi
        done < subdomains_live.txt
    done

    # Check for subdomain takeover
    if command_exists subzy; then
        echo "[*] Checking for subdomain takeovers..."
        subzy run --targets subdomains_all.txt --timeout 20 --output takeovers.txt 2>/dev/null || true
    fi
fi

# ==============================
# 7. GENERATE SUMMARY REPORT
# ==============================
print_section "Phase 7: Generating Summary Report"

REPORT="report.md"

cat > "$REPORT" << EOF
# Reconnaissance Report for ${TARGET}
Generated: $(date)

## Summary

- **Total Subdomains Found:** ${SUBDOMAIN_COUNT:-0}
- **Live Hosts:** ${LIVE_COUNT:-0}
- **Open Ports:** ${PORT_COUNT:-0}
- **Potential Vulnerabilities:** ${NUCLEI_COUNT:-0}

## Subdomains

### Live Hosts (HTTP 200)
$(if [ -f subdomains_200.txt ]; then cat subdomains_200.txt | head -20; echo "..."; fi)

### Authentication Required (401/403)
$(if [ -f subdomains_401.txt ]; then cat subdomains_401.txt | head -10; fi)
$(if [ -f subdomains_403.txt ]; then cat subdomains_403.txt | head -10; fi)

## Open Ports
$(if [ -f ports.txt ]; then cat ports.txt | head -20; echo "..."; fi)

## Vulnerabilities

### Critical
$(if [ -f nuclei_critical.json ] && [ -s nuclei_critical.json ]; then cat nuclei_critical.json | jq -r '.info.name' | head -10; else echo "None found"; fi)

### High
$(if [ -f nuclei_high.json ] && [ -s nuclei_high.json ]; then cat nuclei_high.json | jq -r '.info.name' | head -10; else echo "None found"; fi)

## Exposed Resources

### Exposed Git Repositories
$(if [ -f exposed_git.txt ]; then cat exposed_git.txt; else echo "None found"; fi)

### Exposed Configuration Files
$(if [ -f exposed_files.txt ]; then cat exposed_files.txt; else echo "None found"; fi)

### Potential Subdomain Takeovers
$(if [ -f takeovers.txt ]; then cat takeovers.txt; else echo "None found"; fi)

## Files Generated

- \`subdomains_all.txt\` - All discovered subdomains
- \`subdomains_live.txt\` - Live hosts
- \`subdomains_live_detailed.json\` - Detailed host information
- \`ports.txt\` - Open ports
- \`nuclei_findings.txt\` - Vulnerability findings
- \`screenshots/\` - Web application screenshots
- \`recon.log\` - Full execution log

## Next Steps

1. Review high/critical vulnerabilities in \`nuclei_findings.json\`
2. Investigate exposed git repositories and configuration files
3. Check subdomain takeover possibilities
4. Manual testing of authentication endpoints (401/403)
5. Review screenshots for interesting targets

EOF

echo -e "${GREEN}[+] Report generated: ${REPORT}${NC}"

# ==============================
# COMPLETION
# ==============================
print_section "Reconnaissance Complete!"

echo -e "${GREEN}"
echo "Total Time: $SECONDS seconds"
echo "Output Directory: $(pwd)"
echo ""
echo "Key Files:"
echo "  - subdomains_live.txt      (${LIVE_COUNT:-0} live hosts)"
echo "  - ports.txt                (${PORT_COUNT:-0} open ports)"
echo "  - nuclei_findings.txt      (${NUCLEI_COUNT:-0} findings)"
echo "  - report.md                (Summary report)"
echo "  - screenshots/             (Web screenshots)"
echo ""
echo "Review the report.md file for a comprehensive summary"
echo -e "${NC}"
