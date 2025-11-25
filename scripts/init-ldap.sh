#!/bin/bash
# LDAP Initialization Script
# This script initializes the LDAP directory structure and creates the admin user

set -e

echo "=========================================="
echo "LDAP Directory Initialization"
echo "=========================================="
echo ""

# Check if OpenLDAP is running
if ! docker compose --profile all ps openldap | grep -q "Up"; then
    echo "❌ Error: OpenLDAP container is not running"
    echo "Start it with: docker compose --profile all up -d openldap"
    exit 1
fi

echo "✅ OpenLDAP is running"
echo ""

# Load LDAP admin password from .env
LDAP_ADMIN_PASSWORD=$(grep "^LDAP_ADMIN_PASSWORD=" /opt/homeserver/.env | cut -d= -f2)

if [ -z "$LDAP_ADMIN_PASSWORD" ]; then
    echo "❌ Error: LDAP_ADMIN_PASSWORD not found in .env"
    exit 1
fi

echo "✅ LDAP admin password loaded from .env"
echo ""

# Copy LDIF file into container
echo "📋 Copying LDIF file to container..."
docker cp /opt/homeserver/services/auth/ldap/init.ldif openldap:/tmp/init.ldif
echo "✅ LDIF file copied"
echo ""

# Check if directory structure already exists
echo "🔍 Checking if LDAP is already initialized..."
if docker exec openldap ldapsearch -x -H ldap://localhost -b "ou=users,dc=mykyta-ryasny,dc=dev" -D "cn=admin,dc=mykyta-ryasny,dc=dev" -w "$LDAP_ADMIN_PASSWORD" 2>/dev/null | grep -q "ou=users"; then
    echo "⚠️  LDAP directory already initialized!"
    echo ""
    read -p "Do you want to reinitialize (this will delete existing users)? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping initialization."
        exit 0
    fi

    # Delete existing structure
    echo "🗑️  Deleting existing structure..."
    docker exec openldap ldapdelete -x -H ldap://localhost -D "cn=admin,dc=mykyta-ryasny,dc=dev" -w "$LDAP_ADMIN_PASSWORD" -r "ou=users,dc=mykyta-ryasny,dc=dev" 2>/dev/null || true
    docker exec openldap ldapdelete -x -H ldap://localhost -D "cn=admin,dc=mykyta-ryasny,dc=dev" -w "$LDAP_ADMIN_PASSWORD" -r "ou=groups,dc=mykyta-ryasny,dc=dev" 2>/dev/null || true
    echo "✅ Existing structure deleted"
    echo ""
fi

# Add directory structure
echo "📁 Creating directory structure..."
if docker exec openldap ldapadd -x -H ldap://localhost -D "cn=admin,dc=mykyta-ryasny,dc=dev" -w "$LDAP_ADMIN_PASSWORD" -f /tmp/init.ldif; then
    echo "✅ Directory structure created successfully!"
    echo ""
else
    echo "❌ Error creating directory structure"
    exit 1
fi

# Prompt for admin password
echo "=========================================="
echo "Set Admin User Password"
echo "=========================================="
echo ""
echo "Please enter a password for the admin user (uid=admin)"
echo "This will be used to log into:"
echo "  - Authelia (SSO portal)"
echo "  - Jellyfin (media server)"
echo "  - Jellyseerr (request management)"
echo ""

read -sp "Enter admin password: " ADMIN_PASSWORD
echo ""
read -sp "Confirm admin password: " ADMIN_PASSWORD_CONFIRM
echo ""

if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
    echo "❌ Passwords do not match"
    exit 1
fi

if [ -z "$ADMIN_PASSWORD" ]; then
    echo "❌ Password cannot be empty"
    exit 1
fi

# Set admin password
echo ""
echo "🔐 Setting admin password..."
if docker exec openldap ldappasswd -x -H ldap://localhost -D "cn=admin,dc=mykyta-ryasny,dc=dev" -w "$LDAP_ADMIN_PASSWORD" -s "$ADMIN_PASSWORD" "uid=admin,ou=users,dc=mykyta-ryasny,dc=dev"; then
    echo "✅ Admin password set successfully!"
    echo ""
else
    echo "❌ Error setting admin password"
    exit 1
fi

# Verify the structure
echo "=========================================="
echo "Verification"
echo "=========================================="
echo ""

echo "📋 Organizational Units:"
docker exec openldap ldapsearch -x -H ldap://localhost -b "dc=mykyta-ryasny,dc=dev" -D "cn=admin,dc=mykyta-ryasny,dc=dev" -w "$LDAP_ADMIN_PASSWORD" -LLL "(objectClass=organizationalUnit)" dn
echo ""

echo "👥 Groups:"
docker exec openldap ldapsearch -x -H ldap://localhost -b "ou=groups,dc=mykyta-ryasny,dc=dev" -D "cn=admin,dc=mykyta-ryasny,dc=dev" -w "$LDAP_ADMIN_PASSWORD" -LLL "(objectClass=groupOfNames)" cn
echo ""

echo "👤 Users:"
docker exec openldap ldapsearch -x -H ldap://localhost -b "ou=users,dc=mykyta-ryasny,dc=dev" -D "cn=admin,dc=mykyta-ryasny,dc=dev" -w "$LDAP_ADMIN_PASSWORD" -LLL "(objectClass=inetOrgPerson)" uid cn mail
echo ""

echo "=========================================="
echo "✅ LDAP Initialization Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Configure Authelia to use LDAP backend"
echo "2. Install Jellyfin LDAP plugin"
echo "3. Configure Jellyseerr to use Jellyfin authentication"
echo ""
echo "Access phpLDAPadmin to manage users:"
echo "  https://ldap.mykyta-ryasny.dev"
echo "  Login DN: cn=admin,dc=mykyta-ryasny,dc=dev"
echo "  Password: (from .env - LDAP_ADMIN_PASSWORD)"
echo ""
