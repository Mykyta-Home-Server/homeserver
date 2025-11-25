# LDAP Setup Guide - Unified Authentication

**Last Updated:** 2025-11-25
**Status:** 🚧 In Progress - OpenLDAP and phpLDAPadmin Running

---

## What We've Completed

✅ **OpenLDAP container** running
✅ **phpLDAPadmin container** running
✅ **Caddy configuration** for https://ldap.mykyta-ryasny.dev
✅ **Cloudflare Tunnel** configured for ldap subdomain
✅ **Authelia access control** - ldap.mykyta-ryasny.dev requires admin group
✅ **LDAP credentials** stored in `.env` file

---

## Access phpLDAPadmin

1. Visit https://ldap.mykyta-ryasny.dev
2. Log in with **Authelia** first (your current credentials)
3. You'll see the phpLDAPadmin interface
4. **Login to phpLDAPadmin:**
   - **Login DN:** `cn=admin,dc=mykyta-ryasny,dc=dev`
   - **Password:** (from `.env` - `LDAP_ADMIN_PASSWORD`)

---

## Next Steps - Complete LDAP Setup

The LDAP server is running but needs to be initialized with:
1. Organizational Units (OUs) for users and groups
2. Group entries (admins, family, friends)
3. User entries

I'll create a script to do this, or you can follow the manual steps below.

---

## Manual Setup via phpLDAPadmin

### Step 1: Create Organizational Units

1. Log in to https://ldap.mykyta-ryasny.dev
2. Click on `dc=mykyta-ryasny,dc=dev` in the tree
3. Click **"Create new entry here"**
4. Select **"Generic: Organizational Unit"**
5. Name it: `users`
6. Click **Create Object** → **Commit**
7. Repeat for `groups`

Result: You'll have:
- `ou=users,dc=mykyta-ryasny,dc=dev`
- `ou=groups,dc=mykyta-ryasny,dc=dev`

### Step 2: Create Groups

**Create "admins" group:**
1. Click on `ou=groups,dc=mykyta-ryasny,dc=dev`
2. Click **"Create new entry here"**
3. Select **"Generic: Posix Group"**
4. **Group name:** `admins`
5. **GID:** `500`
6. Click **Create Object** → **Commit**

**Create "family" group:**
1. Same steps, use name `family` and GID `501`

### Step 3: Create Your Admin User

1. Click on `ou=users,dc=mykyta-ryasny,dc=dev`
2. Click **"Create new entry here"**
3. Select **"Generic: User Account"**
4. Fill in:
   - **User ID:** `admin` (your username)
   - **Common Name:** `Mykyta Ryasny`
   - **GID Number:** `500` (admins group)
   - **Home Directory:** `/home/admin`
   - **Login Shell:** `/bin/bash`
   - **Password:** (enter your password - it will be hashed)
5. Click **Create Object** → **Commit**

### Step 4: Add User to Groups

1. Click on the user you just created
2. Scroll to **`memberOf`** or **`memberUid`**
3. Add the user to the `admins` group

---

## Automated Setup Script

Alternatively, use this automated script:

```bash
# Save LDAP admin password for this session
export LDAP_ADMIN_PASSWORD="ZRR+BWr7vErpTSzdaiZgOZEMqNmLJCDQSfi3ptVh/3A="

# Initialize LDAP structure
docker exec openldap bash -c "cat > /tmp/init.ldif << 'EOF'
# Create Organizational Units
dn: ou=users,dc=mykyta-ryasny,dc=dev
objectClass: organizationalUnit
ou: users

dn: ou=groups,dc=mykyta-ryasny,dc=dev
objectClass: organizationalUnit
ou: groups

# Create Groups
dn: cn=admins,ou=groups,dc=mykyta-ryasny,dc=dev
objectClass: posixGroup
cn: admins
gidNumber: 500

dn: cn=family,ou=groups,dc=mykyta-ryasny,dc=dev
objectClass: posixGroup
cn: family
gidNumber: 501

# Create Admin User
dn: uid=admin,ou=users,dc=mykyta-ryasny,dc=dev
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: admin
cn: Mykyta Ryasny
sn: Ryasny
givenName: Mykyta
mail: MykytaRyasny@gmail.com
uidNumber: 1000
gidNumber: 500
homeDirectory: /home/admin
loginShell: /bin/bash
userPassword: {SSHA}replacethiswithactualpasswordhash
EOF
"

# Apply the LDIF (without password for now)
# We'll set the password separately
docker exec openldap ldapadd -x -D "cn=admin,dc=mykyta-ryasny,dc=dev" -w "$LDAP_ADMIN_PASSWORD" -f /tmp/init.ldif

# Set admin user password
docker exec openldap ldappasswd -x -D "cn=admin,dc=mykyta-ryasny,dc=dev" -w "$LDAP_ADMIN_PASSWORD" -s "YOUR_PASSWORD_HERE" "uid=admin,ou=users,dc=mykyta-ryasny,dc=dev"
```

---

## Configure Authelia to Use LDAP

Once LDAP is initialized with users, update Authelia configuration:

**File:** `/opt/homeserver/services/auth/authelia/configuration.yml`

Replace the file-based authentication section with LDAP:

```yaml
authentication_backend:
  password_reset:
    disable: false  # Can enable with SMTP later

  refresh_interval: 5m

  # LDAP backend
  ldap:
    implementation: custom
    address: 'ldap://openldap:389'
    timeout: 5s
    start_tls: false

    # Base DN
    base_dn: 'dc=mykyta-ryasny,dc=dev'

    # Admin user for Authelia to query LDAP
    user: 'cn=admin,dc=mykyta-ryasny,dc=dev'
    password: 'ZRR+BWr7vErpTSzdaiZgOZEMqNmLJCDQSfi3ptVh/3A='

    # User search configuration
    users_filter: '(&(|({username_attribute}={input})({mail_attribute}={input}))(objectClass=inetOrgPerson))'
    username_attribute: 'uid'
    mail_attribute: 'mail'
    display_name_attribute: 'cn'

    # Group search configuration
    groups_filter: '(&(member={dn})(objectClass=groupOfNames))'
    group_name_attribute: 'cn'

    # Additional users DN
    additional_users_dn: 'ou=users'

    # Additional groups DN
    additional_groups_dn: 'ou=groups'
```

**Important:** Remove or comment out the `file:` section when you enable LDAP.

Restart Authelia after changing:
```bash
docker compose --profile all restart authelia
```

---

## Configure Jellyfin LDAP Plugin

1. **Access Jellyfin**
   - Go to https://streaming.mykyta-ryasny.dev
   - Log in with admin credentials

2. **Install LDAP Plugin**
   - Dashboard → Plugins → Catalog
   - Search for "LDAP Authentication"
   - Click Install
   - Restart Jellyfin

3. **Configure LDAP Plugin**
   - Dashboard → Plugins → LDAP Authentication
   - **LDAP Server:** `openldap`
   - **LDAP Port:** `389`
   - **LDAP Base DN:** `dc=mykyta-ryasny,dc=dev`
   - **LDAP Bind User:** `cn=admin,dc=mykyta-ryasny,dc=dev`
   - **LDAP Bind Password:** (LDAP admin password from `.env`)
   - **LDAP User DN:** `ou=users,dc=mykyta-ryasny,dc=dev`
   - **LDAP Search Attributes:** `uid, cn, mail`
   - **LDAP Admin Filter:** `(memberOf=cn=admins,ou=groups,dc=mykyta-ryasny,dc=dev)`
   - Save

4. **Test LDAP Login**
   - Log out of Jellyfin
   - Log in with your LDAP username/password
   - Should work!

---

## Testing Unified Authentication

After completing the setup:

1. **Test Authelia with LDAP**
   - Visit https://auth.mykyta-ryasny.dev
   - Log in with LDAP credentials (uid=admin, your password)
   - Should work

2. **Test Jellyfin with LDAP**
   - Visit https://streaming.mykyta-ryasny.dev
   - Authelia login (LDAP credentials)
   - Jellyfin login (same LDAP credentials)
   - Should use same password for both

3. **Add a New User**
   - Add user to LDAP via phpLDAPadmin
   - User automatically works in both Authelia and Jellyfin
   - No need to create user twice!

---

## Advantages of LDAP Setup

✅ **Single User Database** - Users defined once in LDAP
✅ **Unified Credentials** - Same username/password everywhere
✅ **Centralized Management** - Add/remove users in one place
✅ **Works with All Clients** - Jellyfin mobile apps, Chromecast, etc.
✅ **Enterprise-Grade** - Industry-standard authentication
✅ **Easy User Management** - Web UI (phpLDAPadmin) for admins

---

## LDAP Credentials Reference

**LDAP Admin DN:** `cn=admin,dc=mykyta-ryasny,dc=dev`
**LDAP Admin Password:** (stored in `/opt/homeserver/.env` as `LDAP_ADMIN_PASSWORD`)
**LDAP Base DN:** `dc=mykyta-ryasny,dc=dev`
**LDAP Users DN:** `ou=users,dc=mykyta-ryasny,dc=dev`
**LDAP Groups DN:** `ou=groups,dc=mykyta-ryasny,dc=dev`

---

## Troubleshooting

### Can't Access phpLDAPadmin

```bash
# Check containers are running
docker compose --profile all ps | grep -E "openldap|phpldapadmin"

# Check logs
docker compose logs openldap --tail=50
docker compose logs phpldapadmin --tail=50
```

### LDAP Login Fails

```bash
# Test LDAP connection
docker exec openldap ldapsearch -x -H ldap://localhost -b "dc=mykyta-ryasny,dc=dev" -D "cn=admin,dc=mykyta-ryasny,dc=dev" -w "LDAP_ADMIN_PASSWORD"
```

### Authelia Won't Connect to LDAP

```bash
# Check Authelia can reach OpenLDAP
docker exec authelia ping openldap

# Check Authelia logs
docker compose logs authelia --tail=100 | grep -i ldap
```

---

## Current Status Summary

✅ OpenLDAP installed and running
✅ phpLDAPadmin installed and accessible at https://ldap.mykyta-ryasny.dev
⚠️ LDAP directory needs initialization (users, groups, OUs)
⏳ Authelia still using file-based auth (needs LDAP config)
⏳ Jellyfin needs LDAP plugin installation

**Next Action:** Initialize LDAP directory structure using the script or manual steps above.

---

## Related Files

- [OpenLDAP Compose Config](../compose/ldap.yml)
- [Authelia Configuration](../services/auth/authelia/configuration.yml)
- [Environment Variables](../.env)
- [Caddy LDAP Site Config](../services/proxy/caddy/sites/ldap.Caddyfile)
