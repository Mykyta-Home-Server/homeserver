---
title: LDAP Guide
description: OpenLDAP user and group management
---

Unified authentication with OpenLDAP across all services.

## Architecture

```
LDAP (OpenLDAP)
  ├─→ Authelia (SSO for protected services)
  ├─→ Jellyfin (direct LDAP auth via plugin)
  └─→ Jellyseerr (via Jellyfin)
```

## Directory Structure

```
dc=mykyta-ryasny,dc=dev
├── ou=users
│   └── uid=admin
└── ou=groups
    ├── cn=admins
    └── cn=family
```

## Managing Users

Access phpLDAPadmin at: `https://ldap.mykyta-ryasny.dev`

### Add User via CLI

```bash
docker exec -it openldap ldapadd -x -D "cn=admin,dc=mykyta-ryasny,dc=dev" -W << 'EOF'
dn: uid=newuser,ou=users,dc=mykyta-ryasny,dc=dev
objectClass: inetOrgPerson
objectClass: posixAccount
uid: newuser
cn: New User
sn: User
mail: newuser@example.com
uidNumber: 1001
gidNumber: 1001
homeDirectory: /home/newuser
userPassword: {SSHA}hashed_password
EOF
```

### Add User to Group

```bash
docker exec -it openldap ldapmodify -x -D "cn=admin,dc=mykyta-ryasny,dc=dev" -W << 'EOF'
dn: cn=family,ou=groups,dc=mykyta-ryasny,dc=dev
changetype: modify
add: member
member: uid=newuser,ou=users,dc=mykyta-ryasny,dc=dev
EOF
```

## Authelia Integration

Authelia config (`configuration.yml`):

```yaml
authentication_backend:
  ldap:
    address: ldap://openldap:389
    base_dn: dc=mykyta-ryasny,dc=dev
    users_filter: (&(|({username_attribute}={input}))(objectClass=inetOrgPerson))
    groups_filter: (&(member={dn})(objectClass=groupOfNames))
```

## Jellyfin Integration

1. Install LDAP-Auth plugin
2. Configure:
   - **Server**: `ldap://openldap:389`
   - **Base DN**: `dc=mykyta-ryasny,dc=dev`
   - **Username Attribute**: `uid`
   - **Admin Filter**: `(memberOf=cn=admins,ou=groups,dc=mykyta-ryasny,dc=dev)`

## Access Control

| Group | Services |
|-------|----------|
| `admins` | All services (Grafana, Radarr, Sonarr, etc.) |
| `family` | Jellyfin, Jellyseerr |
