# Jellyfin LDAP Plugin Setup Guide

**Goal:** Enable Jellyfin to authenticate users against LDAP

**After setup:** You'll be able to log into Jellyfin using your LDAP credentials (username: `admin`, password: `homeserver2025`)

---

## Step 1: Install LDAP Authentication Plugin

### 1.1 Access Jellyfin Admin Dashboard

1. Visit: https://streaming.mykyta-ryasny.dev
2. Log in with Authelia first (username: `admin`, password: `homeserver2025`)
3. Jellyfin will show its own login page
4. Log in with your **current** Jellyfin admin credentials

### 1.2 Install LDAP Plugin

1. Click on the **hamburger menu** (☰) in top left
2. Go to: **Dashboard**
3. Click: **Plugins** (in the left sidebar)
4. Click: **Catalog** tab
5. Scroll down or search for: **"LDAP-Auth Plugin"**
6. Click the **Install** button next to "LDAP-Auth Plugin"
7. Wait for installation to complete
8. **Restart Jellyfin** when prompted:
   - Click **Restart** in the popup, OR
   - Go to Dashboard → Advanced → **Restart**

---

## Step 2: Configure LDAP Plugin

### 2.1 Access LDAP Plugin Settings

1. After Jellyfin restarts, log back in
2. Go to: **Dashboard → Plugins**
3. Click on: **LDAP-Auth Plugin**
4. You'll see the configuration page

### 2.2 Add LDAP Server Configuration

Click **"Add LDAP Server"** and fill in the following:

#### General Settings

| Setting | Value | Notes |
|---------|-------|-------|
| **LDAP Server** | `openldap` | Hostname of LDAP container |
| **LDAP Port** | `389` | Standard LDAP port (not LDAPS) |
| **Secure LDAP** | ❌ Unchecked | We're on internal network |
| **Start TLS** | ❌ Unchecked | No TLS needed internally |
| **Skip SSL/TLS Verification** | ✅ Checked | Skip cert validation |

#### Bind Credentials (Admin User for Queries)

| Setting | Value | Notes |
|---------|-------|-------|
| **LDAP Bind User** | `cn=admin,dc=mykyta-ryasny,dc=dev` | LDAP admin DN |
| **LDAP Bind User Password** | `ZRR+BWr7vErpTSzdaiZgOZEMqNmLJCDQSfi3ptVh/3A=` | From .env file |

#### Base DN and Search

| Setting | Value | Notes |
|---------|-------|-------|
| **LDAP Base DN for searches** | `dc=mykyta-ryasny,dc=dev` | Root of directory |
| **LDAP Search Filter** | `(uid={0})` | Search by username |
| **LDAP Search Attributes** | `uid, cn, mail, displayName` | Attributes to retrieve |

#### Admin Filter (Optional but Recommended)

| Setting | Value | Notes |
|---------|-------|-------|
| **LDAP Admin Base DN** | `ou=groups,dc=mykyta-ryasny,dc=dev` | Where groups are stored |
| **LDAP Admin Filter** | `(memberOf=cn=admins,ou=groups,dc=mykyta-ryasny,dc=dev)` | Make LDAP admins Jellyfin admins |

#### User Creation

| Setting | Value | Notes |
|---------|-------|-------|
| **Create users in Jellyfin library** | ✅ Checked | Auto-create users on first login |
| **Jellyfin user folder** | (leave empty) | Use default folder |

### 2.3 Save Configuration

1. Click **Save** at the bottom of the page
2. You should see: "Settings saved"

---

## Step 3: Test LDAP Authentication

### 3.1 Log Out of Jellyfin

1. Click your user icon in top right
2. Click **Sign out**

### 3.2 Log In with LDAP Credentials

1. On Jellyfin login page, enter:
   - **Username:** `admin`
   - **Password:** `homeserver2025`
2. Click **Sign In**
3. You should be logged in successfully! ✅

### 3.3 Verify User was Created

1. Go to: **Dashboard → Users**
2. You should see your `admin` user listed
3. It should show as an **Administrator** (because of the admin filter)

---

## Step 4: Disable Local Jellyfin Authentication (Optional)

Once LDAP is working, you can disable the local admin user for better security:

1. Go to: **Dashboard → Users**
2. Find your old local admin account (if different from LDAP)
3. You can disable it or keep it as a backup

**Recommendation:** Keep one local admin account as a backup in case LDAP goes down.

---

## Understanding the Configuration

### How LDAP Login Works

```
1. User enters username/password in Jellyfin
   ↓
2. Jellyfin LDAP plugin searches LDAP for user
   Search: (uid=admin) in dc=mykyta-ryasny,dc=dev
   ↓
3. If user found, plugin tries to bind with user's credentials
   Bind DN: uid=admin,ou=users,dc=mykyta-ryasny,dc=dev
   Password: [user's password]
   ↓
4. If bind successful → User authenticated ✅
   ↓
5. Plugin checks admin filter
   Is user in cn=admins group? → Make them Jellyfin admin
   ↓
6. If first login → Create Jellyfin user automatically
```

### What Each Setting Does

**LDAP Server & Port:**
- `openldap:389` - Docker network hostname and standard LDAP port
- No encryption needed (internal network is trusted)

**Bind User:**
- LDAP requires authentication even for searches
- Plugin uses admin credentials to search for users
- This is NOT the user logging in (that happens after search)

**Base DN:**
- Starting point for all LDAP searches
- `dc=mykyta-ryasny,dc=dev` is the root of our directory

**Search Filter:**
- `(uid={0})` - Replace `{0}` with username entered by user
- Example: User enters "admin" → searches for `(uid=admin)`

**Admin Filter:**
- Checks if user is member of admins group in LDAP
- If yes → Make them Jellyfin administrator
- This syncs LDAP permissions with Jellyfin permissions

---

## Troubleshooting

### Problem: "Invalid username or password"

**Possible Causes:**

1. **LDAP plugin not configured correctly**
   ```bash
   # Test LDAP connection from Jellyfin container
   docker exec jellyfin ping openldap
   ```

2. **User doesn't exist in LDAP**
   ```bash
   # Search for user in LDAP
   docker exec openldap ldapsearch -x -H ldap://localhost \
     -b "ou=users,dc=mykyta-ryasny,dc=dev" \
     -D "cn=admin,dc=mykyta-ryasny,dc=dev" \
     -w 'ZRR+BWr7vErpTSzdaiZgOZEMqNmLJCDQSfi3ptVh/3A=' \
     "(uid=admin)"
   ```

3. **Wrong password**
   - Make sure you're using: `homeserver2025`
   - Password is case-sensitive

### Problem: User logs in but isn't an admin

**Fix:** Check the admin filter configuration
- Make sure it's set to: `(memberOf=cn=admins,ou=groups,dc=mykyta-ryasny,dc=dev)`
- Verify user is in admins group:
  ```bash
  docker exec openldap ldapsearch -x -H ldap://localhost \
    -b "cn=admins,ou=groups,dc=mykyta-ryasny,dc=dev" \
    -D "cn=admin,dc=mykyta-ryasny,dc=dev" \
    -w 'ZRR+BWr7vErpTSzdaiZgOZEMqNmLJCDQSfi3ptVh/3A=' \
    member
  ```

### Problem: Jellyfin plugin doesn't connect to LDAP

**Check Jellyfin logs:**
```bash
docker compose logs jellyfin --tail=100 | grep -i ldap
```

**Verify network connectivity:**
```bash
# Jellyfin should be able to reach OpenLDAP
docker exec jellyfin ping -c 3 openldap
```

---

## Adding More Users

Once LDAP is configured, adding users is simple:

### Option 1: Via phpLDAPadmin (Web UI)

1. Visit: https://ldap.mykyta-ryasny.dev
2. Log in with LDAP admin credentials
3. Navigate to: `ou=users,dc=mykyta-ryasny,dc=dev`
4. Click: **Create new entry**
5. Select: **Generic: User Account**
6. Fill in user details (username, email, password)
7. Click: **Create Object**
8. User can now log into Jellyfin!

### Option 2: Via Command Line

```bash
# Create user LDIF file
cat > /tmp/newuser.ldif << 'EOF'
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
userPassword: placeholder
EOF

# Add user to LDAP
docker exec openldap ldapadd -x -H ldap://localhost \
  -D "cn=admin,dc=mykyta-ryasny,dc=dev" \
  -w 'ZRR+BWr7vErpTSzdaiZgOZEMqNmLJCDQSfi3ptVh/3A=' \
  -f /tmp/newuser.ldif

# Set password
docker exec openldap ldappasswd -x -H ldap://localhost \
  -D "cn=admin,dc=mykyta-ryasny,dc=dev" \
  -w 'ZRR+BWr7vErpTSzdaiZgOZEMqNmLJCDQSfi3ptVh/3A=' \
  -s 'johns_password' \
  "uid=john,ou=users,dc=mykyta-ryasny,dc=dev"
```

New user can immediately log into Jellyfin with:
- Username: `john`
- Password: `johns_password`

---

## Next Steps

After Jellyfin LDAP is working:

1. ✅ Test login with LDAP credentials
2. ⏳ Configure Jellyseerr to use Jellyfin authentication (so it also uses LDAP)
3. ⏳ Add more users to LDAP as needed
4. 🔮 Build user management into your custom portal (future)

---

## Summary

**What you've accomplished:**

- ✅ Installed Jellyfin LDAP plugin
- ✅ Configured LDAP server connection
- ✅ Enabled automatic user creation
- ✅ Synced admin permissions (LDAP admins = Jellyfin admins)
- ✅ Tested login with LDAP credentials

**Result:** Jellyfin now uses the same user database as Authelia!

---

## Quick Reference

**LDAP Connection Info:**
- Server: `openldap:389`
- Base DN: `dc=mykyta-ryasny,dc=dev`
- Bind User: `cn=admin,dc=mykyta-ryasny,dc=dev`
- Bind Password: `ZRR+BWr7vErpTSzdaiZgOZEMqNmLJCDQSfi3ptVh/3A=`

**User Login:**
- Username: `admin`
- Password: `homeserver2025`

**Management:**
- phpLDAPadmin: https://ldap.mykyta-ryasny.dev
- Add users in LDAP → They work in Jellyfin automatically!
