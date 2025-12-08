# Automation Scripts

Collection of practical automation scripts for penetration testing and bug bounty hunting.

## Available Scripts

### 1. Full Reconnaissance Pipeline

**Script:** `full-recon.sh`

Automated reconnaissance pipeline that performs:

- Subdomain enumeration (passive & active)
- Live host detection
- Port scanning
- Screenshot capture
- Vulnerability scanning with Nuclei
- Exposed file detection
- Summary report generation

**Usage:**

```bash
./full-recon.sh target.com
```

**Prerequisites:**

```bash
# Install required tools
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/tomnomnom/assetfinder@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install -v github.com/sensepost/gowitness@latest
go install -v github.com/owasp-amass/amass/v4/...@master

# Optional
go install -v github.com/PentestPad/subzy@latest
```

**Output:**

- `subdomains_all.txt` - All discovered subdomains
- `subdomains_live.txt` - Live hosts with HTTP/HTTPS
- `subdomains_live_detailed.json` - Detailed host info (status, title, tech)
- `ports.txt` - Open ports found
- `nuclei_findings.txt` - Vulnerability findings
- `nuclei_findings.json` - Detailed vulnerability data
- `screenshots/` - Web application screenshots
- `report.md` - Markdown summary report
- `recon.log` - Complete execution log

### 2. Content Discovery

**Script:** `content-discovery.sh`

Discovers hidden endpoints, directories, and files on web applications.

**Usage:**

```bash
./content-discovery.sh https://target.com
```

Features:

- Multiple wordlist support
- Parameter discovery
- API endpoint enumeration
- Technology-specific wordlists
- Historical URL gathering (wayback, gau)

## Quick Start

1. **Clone and setup:**

```bash
cd scripts
chmod +x *.sh
```

2. **Run full reconnaissance:**

```bash
./full-recon.sh example.com
```

3. **Review output:**

```bash
cd example.com_recon_*
cat report.md
```

## Tips

### Rate Limiting

All scripts implement rate limiting to avoid:

- Getting blocked by WAF/IPS
- Overloading target servers
- API rate limit violations

Adjust rates in scripts if needed.

### Continuous Monitoring

For bug bounty programs, set up cron jobs:

```bash
# Daily reconnaissance
0 2 * * * /path/to/full-recon.sh target.com

# Weekly deep scan
0 3 * * 0 /path/to/full-recon.sh target.com --deep
```

### Combining with Manual Testing

These scripts provide initial reconnaissance. Always follow up with:

1. Manual verification of findings
2. Deep testing of interesting endpoints
3. Custom payload testing
4. Business logic testing

### Performance Optimization

For faster scans:

- Use VPS with good bandwidth
- Increase thread counts (carefully)
- Use multiple tools in parallel
- Cache DNS responses

## Integration

### Burp Suite Integration

Send all discovered URLs to Burp:

```bash
cat subdomains_live.txt | while read url; do
    curl -k -x http://127.0.0.1:8080 "$url" -o /dev/null 2>/dev/null
done
```

### Slack/Discord Notifications

Add webhook notifications to scripts:

```bash
# At end of script
curl -X POST -H 'Content-type: application/json' \
  --data "{\"text\":\"Recon complete for $TARGET\"}" \
  https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### Database Storage

Store results in database for historical tracking:

```bash
# Example with SQLite
sqlite3 recon.db "CREATE TABLE IF NOT EXISTS scans (date TEXT, target TEXT, findings INTEGER);"
sqlite3 recon.db "INSERT INTO scans VALUES ('$(date)', '$TARGET', '$FINDING_COUNT');"
```

## Troubleshooting

### Tools Not Found

If tools aren't in PATH:

```bash
export PATH=$PATH:$HOME/go/bin
```

Add to `~/.bashrc` or `~/.zshrc` for persistence.

### Permission Denied

```bash
chmod +x script.sh
```

### Rate Limiting Issues

If getting blocked:

1. Reduce threads/rate in scripts
2. Add delays between requests
3. Use proxies/VPN
4. Rotate user agents

## Security Considerations

- **Authorization:** Only scan targets you have permission to test
- **Rate Limiting:** Respect target infrastructure
- **Data Handling:** Protect sensitive data discovered
- **Reporting:** Follow responsible disclosure
- **Legal:** Ensure you have written authorization

## Contributing

To add new scripts:

1. Follow existing script structure
2. Include error handling
3. Add logging
4. Document usage
5. Test thoroughly

## Resources

- **Tool Documentation**

  - [ProjectDiscovery Tools](https://docs.projectdiscovery.io/)
  - [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)

- **Wordlists**

  - [SecLists](https://github.com/danielmiessler/SecLists)
  - [Assetnote Wordlists](https://wordlists.assetnote.io/)
  - [OneListForAll](https://github.com/six2dez/OneListForAll)

- **Methodologies**
  - [OWASP WSTG](https://owasp.org/www-project-web-security-testing-guide/)
  - [Bug Bounty Playbook](https://github.com/EdOverflow/bugbounty-cheatsheet)
