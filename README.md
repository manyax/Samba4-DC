Samba4 sudoers and openssh-lpk schema.
=======================================

Add sudoers and openssh-lpk schema to Samba4 DC.

Usage
-------

1. Schema SSHPubKey
-------------------

```
sed -i -e 's/${DOMAINDN}/DC=your,DC=domain,DC=name/' schema.SSHPubKey/*.ldif

ldbmodify -H /var/lib/samba/private/sam.ldb schema.SSHPubKey/001-schema.SSHPubKeyAttribs.ldif --option="dsdb:schema update allowed"=true
ldbmodify -H /var/lib/samba/private/sam.ldb schema.SSHPubKey/002-schema.SSHPubKeyClass.ldif --option="dsdb:schema update allowed"=true
ldbmodify -H /var/lib/samba/private/sam.ldb schema.SSHPubKey/003-schema.SSHPubKeyUserClass.ldif --option="dsdb:schema update allowed"=true
```

2. Schema Sudoers
-----------------

```
sed -i -e 's/${DOMAINDN}/DC=your,DC=domain,DC=name/' schema.Sudoers/*.ldif

ldbmodify -H /var/lib/samba/private/sam.ldb schema.Sudoers/001-schema.SudoersAttribs.ldif --option="dsdb:schema update allowed"=true
ldbmodify -H /var/lib/samba/private/sam.ldb schema.Sudoers/002-schema.SudoersClass.ldif --option="dsdb:schema update allowed"=true
```

Option 2.
---------
Add 'dsdb:schema update allowed = true' to the DCs smb.conf, restart samba.
```
ldapmodify  -f schema.ldif -D 'user@DOMAIN' -W -H ldaps://localhost
```
Remove the line you added to smb.conf and restart samba again.

