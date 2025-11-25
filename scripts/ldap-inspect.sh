#!/bin/bash
# LDAP Inspection Script
# View the complete LDAP directory structure and understand permissions

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "LDAP Directory Inspector"
echo "=========================================="
echo ""

# Load LDAP admin password from .env
LDAP_ADMIN_PASSWORD=$(grep "^LDAP_ADMIN_PASSWORD=" /opt/homeserver/.env | cut -d= -f2)

if [ -z "$LDAP_ADMIN_PASSWORD" ]; then
    echo "❌ Error: LDAP_ADMIN_PASSWORD not found in .env"
    exit 1
fi

# Check if OpenLDAP is running
if ! docker compose --profile all ps openldap | grep -q "Up"; then
    echo "❌ Error: OpenLDAP container is not running"
    echo "Start it with: docker compose --profile all up -d openldap"
    exit 1
fi

echo -e "${GREEN}✅ OpenLDAP is running${NC}"
echo ""

# Function to run ldapsearch
ldap_search() {
    docker exec openldap ldapsearch -x -H ldap://localhost \
        -D "cn=admin,dc=mykyta-ryasny,dc=dev" \
        -w "$LDAP_ADMIN_PASSWORD" \
        -LLL "$@"
}

echo "=========================================="
echo "1. DIRECTORY TREE STRUCTURE"
echo "=========================================="
echo ""
echo -e "${BLUE}Base DN: dc=mykyta-ryasny,dc=dev${NC}"
ldap_search -b "dc=mykyta-ryasny,dc=dev" -s one dn | grep "^dn:" || echo "No entries found"
echo ""

echo "=========================================="
echo "2. ORGANIZATIONAL UNITS (OUs)"
echo "=========================================="
echo ""
ldap_search -b "dc=mykyta-ryasny,dc=dev" "(objectClass=organizationalUnit)" dn description || echo "No OUs found"
echo ""

echo "=========================================="
echo "3. GROUPS"
echo "=========================================="
echo ""
echo -e "${YELLOW}Groups define permissions and access levels${NC}"
echo ""
ldap_search -b "ou=groups,dc=mykyta-ryasny,dc=dev" "(objectClass=groupOfNames)" dn cn description member || echo "No groups found"
echo ""

echo "=========================================="
echo "4. USERS"
echo "=========================================="
echo ""
echo -e "${YELLOW}Users authenticate with these credentials${NC}"
echo ""
ldap_search -b "ou=users,dc=mykyta-ryasny,dc=dev" "(objectClass=inetOrgPerson)" \
    dn uid cn givenName sn mail uidNumber gidNumber || echo "No users found"
echo ""

echo "=========================================="
echo "5. GROUP MEMBERSHIPS"
echo "=========================================="
echo ""
echo -e "${YELLOW}Which users belong to which groups${NC}"
echo ""

# Get all groups and their members
for group in $(ldap_search -b "ou=groups,dc=mykyta-ryasny,dc=dev" "(objectClass=groupOfNames)" dn | grep "^dn:" | cut -d: -f2 | tr -d ' '); do
    group_name=$(echo "$group" | cut -d, -f1 | cut -d= -f2)
    echo -e "${GREEN}Group: $group_name${NC}"
    ldap_search -b "$group" member | grep "^member:" | cut -d: -f2 | sed 's/uid=\([^,]*\).*/  - \1/' || echo "  No members"
    echo ""
done

echo "=========================================="
echo "6. LDAP SCHEMA ATTRIBUTES"
echo "=========================================="
echo ""
echo -e "${YELLOW}Available attributes for users:${NC}"
echo ""
echo "Standard Attributes:"
echo "  - uid: Username (for login)"
echo "  - cn: Common Name (full name)"
echo "  - givenName: First name"
echo "  - sn: Surname (last name)"
echo "  - mail: Email address"
echo "  - userPassword: Hashed password"
echo "  - uidNumber: Unix user ID"
echo "  - gidNumber: Unix group ID"
echo "  - homeDirectory: Home directory path"
echo "  - loginShell: Default shell"
echo ""
echo "Custom Attributes (can be added):"
echo "  - telephoneNumber: Phone number"
echo "  - mobile: Mobile number"
echo "  - displayName: Display name"
echo "  - jpegPhoto: Profile picture"
echo "  - description: User description"
echo ""

echo "=========================================="
echo "7. SERVICES USING LDAP"
echo "=========================================="
echo ""
echo -e "${GREEN}Current Integration:${NC}"
echo "  ⏳ Authelia - Not configured yet (uses file-based auth)"
echo "  ⏳ Jellyfin - LDAP plugin not installed"
echo "  ⏳ Jellyseerr - Uses Jellyfin auth (will work after Jellyfin LDAP)"
echo ""
echo -e "${GREEN}Future Integration Options:${NC}"
echo "  📱 Custom Portal - REST API for user management"
echo "  🔐 Password Reset - Self-service password changes"
echo "  👥 User Registration - Allow users to sign up"
echo "  📊 User Analytics - Track user activity across services"
echo ""

echo "=========================================="
echo "8. PERMISSION MODEL"
echo "=========================================="
echo ""
echo -e "${YELLOW}How permissions work:${NC}"
echo ""
echo "Group-based Access Control (recommended):"
echo "  1. Create groups (admins, family, friends)"
echo "  2. Add users to groups"
echo "  3. Configure services to check group membership"
echo ""
echo "Example in Authelia configuration:"
echo "  access_control:"
echo "    rules:"
echo "      - domain: admin.example.com"
echo "        policy: one_factor"
echo "        subject:"
echo "          - \"group:admins\"  # Only admins can access"
echo ""
echo "      - domain: media.example.com"
echo "        policy: one_factor"
echo "        subject:"
echo "          - \"group:family\"  # Family can access media"
echo ""

echo "=========================================="
echo "9. MANAGEMENT INTERFACES"
echo "=========================================="
echo ""
echo -e "${GREEN}Web Interface (phpLDAPadmin):${NC}"
echo "  URL: https://ldap.mykyta-ryasny.dev"
echo "  Login DN: cn=admin,dc=mykyta-ryasny,dc=dev"
echo "  Password: (from .env - LDAP_ADMIN_PASSWORD)"
echo ""
echo -e "${GREEN}Command Line:${NC}"
echo "  View all users:"
echo "    docker exec openldap ldapsearch -x -H ldap://localhost \\"
echo "      -D \"cn=admin,dc=mykyta-ryasny,dc=dev\" \\"
echo "      -w \"\$LDAP_ADMIN_PASSWORD\" \\"
echo "      -b \"ou=users,dc=mykyta-ryasny,dc=dev\" \\"
echo "      \"(objectClass=inetOrgPerson)\""
echo ""
echo "  Add a new user:"
echo "    docker exec openldap ldapadd -x -H ldap://localhost \\"
echo "      -D \"cn=admin,dc=mykyta-ryasny,dc=dev\" \\"
echo "      -w \"\$LDAP_ADMIN_PASSWORD\" \\"
echo "      -f /tmp/newuser.ldif"
echo ""
echo -e "${GREEN}API Integration (Future):${NC}"
echo "  Libraries:"
echo "    - Python: python-ldap, ldap3"
echo "    - Node.js: ldapjs"
echo "    - Go: go-ldap"
echo ""
echo "  Your portal can:"
echo "    - Create users programmatically"
echo "    - Update user attributes"
echo "    - Manage group memberships"
echo "    - Search/filter users"
echo "    - Change passwords"
echo ""

echo "=========================================="
echo "10. NEXT STEPS"
echo "=========================================="
echo ""
echo "To enable unified authentication:"
echo ""
echo "1. ✅ Initialize LDAP (run init-ldap.sh)"
echo "2. ⏳ Configure Authelia to use LDAP backend"
echo "3. ⏳ Install Jellyfin LDAP plugin"
echo "4. ⏳ Configure Jellyseerr to use Jellyfin auth"
echo "5. 🔮 Build user management into your portal (future)"
echo ""
