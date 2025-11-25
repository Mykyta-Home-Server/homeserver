# LDAP Integration Guide - Unified Authentication

**Goal:** Use the same username and password across Authelia, Jellyfin, and Jellyseerr

**How it works:**
```
LDAP (User Database)
  ↓
  ├─→ Authelia (SSO login)
  ├─→ Jellyfin (Media server)
  └─→ Jellyseerr (Uses Jellyfin auth → LDAP)
```

---

## Step 1: Initialize LDAP Directory

**What this does:** Creates the user database structure and your admin user

```bash
/opt/homeserver/scripts/init-ldap.sh
```

This creates:
- Your admin user: `uid=admin`
- Groups: `admins`, `family`
- Password: You choose (will be used everywhere)

---

## Step 2: Configure Authelia to Use LDAP

**File:** `/opt/homeserver/services/auth/authelia/configuration.yml`

**What to change:**

### Before (File-based authentication):
```yaml
authentication_backend:
  password_reset:
    disable: false
  refresh_interval: 5m

  file:
    path: /config/users_database.yml
    password:
      algorithm: argon2id
```

### After (LDAP authentication):
```yaml
authentication_backend:
  password_reset:
    disable: false
  refresh_interval: 5m

  # LDAP backend - single source of truth for users
  ldap:
    implementation: custom
    address: 'ldap://openldap:389'
    timeout: 5s
    start_tls: false

    # Base DN for LDAP queries
    base_dn: 'dc=mykyta-ryasny,dc=dev'

    # Admin credentials for Authelia to query LDAP
    user: 'cn=admin,dc=mykyta-ryasny,dc=dev'
    password: 'ZRR+BWr7vErpTSzdaiZgOZEMqNmLJCDQSfi3ptVh/3A='

    # Where to find users
    additional_users_dn: 'ou=users'

    # User search filter - allows login by username OR email
    users_filter: '(&(|({username_attribute}={input})({mail_attribute}={input}))(objectClass=inetOrgPerson))'
    username_attribute: 'uid'
    mail_attribute: 'mail'
    display_name_attribute: 'cn'

    # Where to find groups
    additional_groups_dn: 'ou=groups'

    # Group membership filter
    groups_filter: '(&(member={dn})(objectClass=groupOfNames))'
    group_name_attribute: 'cn'
```

**Then restart Authelia:**
```bash
docker compose --profile all restart authelia
```

---

## Step 3: Configure Jellyfin LDAP Plugin

### 3.1 Install LDAP Plugin in Jellyfin

1. Visit https://streaming.mykyta-ryasny.dev
2. Log in with your **current** Jellyfin admin credentials
3. Navigate to: **Dashboard → Plugins → Catalog**
4. Search for: **"LDAP Authentication"**
5. Click **Install**
6. **Restart Jellyfin** when prompted

### 3.2 Configure LDAP Plugin

1. Go to: **Dashboard → Plugins → LDAP Authentication**
2. Click **Add LDAP Server**
3. Fill in:

   - **LDAP Server:** `openldap`
   - **LDAP Port:** `389`
   - **Secure LDAP:** ❌ Unchecked
   - **Start TLS:** ❌ Unchecked
   - **Skip SSL/TLS Verification:** ✅ Checked

   **Bind User:**
   - **LDAP Bind User:** `cn=admin,dc=mykyta-ryasny,dc=dev`
   - **LDAP Bind User Password:** `ZRR+BWr7vErpTSzdaiZgOZEMqNmLJCDQSfi3ptVh/3A=`

   **Base DN:**
   - **LDAP Base DN for searches:** `dc=mykyta-ryasny,dc=dev`

   **Search:**
   - **LDAP Search Filter:** `(uid={0})`
   - **LDAP Search Attributes:** `uid, cn, mail, displayName`

   **Admin Filter (Optional):**
   - **LDAP Admin Base DN:** `ou=groups,dc=mykyta-ryasny,dc=dev`
   - **LDAP Admin Filter:** `(memberOf=cn=admins,ou=groups,dc=mykyta-ryasny,dc=dev)`

   **User Creation:**
   - **Create users in Jellyfin library:** ✅ Checked
   - **Jellyfin user folder:** Leave empty (use default)

4. Click **Save**

### 3.3 Test Jellyfin LDAP Login

1. Log out of Jellyfin
2. Try logging in with:
   - **Username:** `admin` (your LDAP username)
   - **Password:** (the password you set in init-ldap.sh)
3. Should log in successfully!

---

## Step 4: Configure Jellyseerr to Use Jellyfin Auth

Jellyseerr doesn't support LDAP directly, but it can authenticate via Jellyfin.

### 4.1 Enable Jellyfin Authentication in Jellyseerr

1. Visit https://requests.mykyta-ryasny.dev
2. Log in with your **current** Jellyseerr admin credentials
3. Go to: **Settings → General → Authentication**
4. Enable: **"Enable Jellyfin sign-in"**
5. Configure:
   - **Jellyfin URL:** `http://jellyfin:8096`
   - **Jellyfin Authentication:** ✅ Enabled
6. Save settings

### 4.2 Test Jellyseerr Login

1. Log out of Jellyseerr
2. Click **"Sign in with Jellyfin"**
3. Use your LDAP credentials:
   - **Username:** `admin`
   - **Password:** (your LDAP password)
4. Should authenticate via Jellyfin → LDAP!

---

## Step 5: Verification

After completing all steps, test the complete flow:

### Test 1: Authelia LDAP Login
```bash
# Visit any protected service (e.g., qBittorrent)
# URL: https://torrent.mykyta-ryasny.dev
# Should redirect to Authelia
# Login with: admin / [your LDAP password]
# Should work!
```

### Test 2: Jellyfin Direct LDAP Login
```bash
# Visit Jellyfin directly
# URL: https://streaming.mykyta-ryasny.dev
# After Authelia, Jellyfin will show login
# Login with: admin / [your LDAP password]
# Should work!
```

### Test 3: Jellyseerr via Jellyfin Auth
```bash
# Visit Jellyseerr
# URL: https://requests.mykyta-ryasny.dev
# Click "Sign in with Jellyfin"
# Login with: admin / [your LDAP password]
# Should work!
```

---

## Understanding the Flow

### Without LDAP (Current):
```
Service A: username1/password1 (stored in Service A)
Service B: username2/password2 (stored in Service B)
Service C: username3/password3 (stored in Service C)
```

### With LDAP (After configuration):
```
LDAP: admin/password (stored once in LDAP)
  ↓
Service A: Checks LDAP → Finds admin → Allows login
Service B: Checks LDAP → Finds admin → Allows login
Service C: Checks LDAP → Finds admin → Allows login
```

---

## Adding New Users

Once LDAP is configured, add users in one place:

### Via phpLDAPadmin Web UI:
1. Visit https://ldap.mykyta-ryasny.dev
2. Log in with admin credentials
3. Navigate to `ou=users`
4. Click "Create new entry"
5. Fill in user details
6. User automatically works in Authelia, Jellyfin, Jellyseerr!

### Via Command Line:
```bash
# Create user LDIF file
cat > /tmp/newuser.ldif << EOF
dn: uid=john,ou=users,dc=mykyta-ryasny,dc=dev
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: john
cn: John Doe
sn: Doe
givenName: John
mail: john@example.com
uidNumber: 1001
gidNumber: 501
homeDirectory: /home/john
loginShell: /bin/bash
userPassword: {SSHA}placeholder
EOF

# Add user to LDAP
docker exec openldap ldapadd -x -H ldap://localhost \
  -D "cn=admin,dc=mykyta-ryasny,dc=dev" \
  -w "$LDAP_ADMIN_PASSWORD" \
  -f /tmp/newuser.ldif

# Set password
docker exec openldap ldappasswd -x -H ldap://localhost \
  -D "cn=admin,dc=mykyta-ryasny,dc=dev" \
  -w "$LDAP_ADMIN_PASSWORD" \
  -s "johns_password" \
  "uid=john,ou=users,dc=mykyta-ryasny,dc=dev"

# Add to family group
cat > /tmp/addmember.ldif << EOF
dn: cn=family,ou=groups,dc=mykyta-ryasny,dc=dev
changetype: modify
add: member
member: uid=john,ou=users,dc=mykyta-ryasny,dc=dev
EOF

docker exec openldap ldapmodify -x -H ldap://localhost \
  -D "cn=admin,dc=mykyta-ryasny,dc=dev" \
  -w "$LDAP_ADMIN_PASSWORD" \
  -f /tmp/addmember.ldif
```

---

## Future: Custom Portal Integration

You can build user management into your Angular portal:

**Backend API (Python/Node.js):**
```python
# Example: Python Flask API for LDAP user management
from flask import Flask, request, jsonify
import ldap3

app = Flask(__name__)

LDAP_SERVER = 'ldap://openldap:389'
LDAP_ADMIN_DN = 'cn=admin,dc=mykyta-ryasny,dc=dev'
LDAP_ADMIN_PASSWORD = 'your_ldap_admin_password'

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.json

    # Connect to LDAP
    server = ldap3.Server(LDAP_SERVER)
    conn = ldap3.Connection(server, LDAP_ADMIN_DN, LDAP_ADMIN_PASSWORD, auto_bind=True)

    # Create user entry
    user_dn = f"uid={data['username']},ou=users,dc=mykyta-ryasny,dc=dev"
    attributes = {
        'objectClass': ['inetOrgPerson', 'posixAccount', 'shadowAccount'],
        'uid': data['username'],
        'cn': data['full_name'],
        'sn': data['last_name'],
        'givenName': data['first_name'],
        'mail': data['email'],
        'uidNumber': data['uid_number'],
        'gidNumber': '501',  # family group
        'homeDirectory': f"/home/{data['username']}",
        'loginShell': '/bin/bash',
        'userPassword': data['password']  # Will be hashed by LDAP
    }

    conn.add(user_dn, attributes=attributes)

    return jsonify({'success': True, 'message': 'User created'})
```

**Frontend (Angular):**
```typescript
// User creation form
createUser(userData: any) {
  this.http.post('http://your-api:5000/api/users', userData)
    .subscribe(
      response => console.log('User created!'),
      error => console.error('Error creating user')
    );
}
```

---

## Troubleshooting

### Authelia can't connect to LDAP
```bash
# Check Authelia logs
docker compose logs authelia --tail=100 | grep -i ldap

# Test LDAP connectivity from Authelia container
docker exec authelia ping openldap
```

### Jellyfin LDAP plugin not working
```bash
# Check Jellyfin logs
docker compose logs jellyfin --tail=100 | grep -i ldap

# Verify LDAP connectivity
docker exec jellyfin ping openldap

# Test LDAP search manually
docker exec openldap ldapsearch -x -H ldap://localhost \
  -b "ou=users,dc=mykyta-ryasny,dc=dev" \
  -D "cn=admin,dc=mykyta-ryasny,dc=dev" \
  -w "$LDAP_ADMIN_PASSWORD" \
  "(uid=admin)"
```

### Jellyseerr won't authenticate
```bash
# Make sure Jellyfin LDAP is working first
# Jellyseerr → Jellyfin → LDAP (chain dependency)

# Check Jellyseerr logs
docker compose logs jellyseerr --tail=100

# Verify Jellyfin auth is enabled in Jellyseerr settings
```

---

## Summary

**What you're setting up:**

1. ✅ LDAP directory with your users
2. ✅ Authelia authenticates against LDAP
3. ✅ Jellyfin authenticates against LDAP (via plugin)
4. ✅ Jellyseerr authenticates via Jellyfin (which uses LDAP)

**Result:** One username/password (`admin` / your chosen password) works everywhere!

**Management:** Add users once in LDAP → they work in all services automatically.
