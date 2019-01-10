Samba4 sudoers and openssh-lpk schema.
=======================================

Add sudoers and openssh-lpk schema to Samba4 DC.

Usage
-------

```
sed -i -e 's/${DOMAINDN}/DC=your,DC=domain,DC=name/' *.ldif'

Option 1.
ldbmodify -H /var/lib/samba/private/sam.ldb schema.sudoers.ldif --option="dsdb:schema update allowed"=true
ldbmodify -H /var/lib/samba/private/sam.ldb schema.SSHpubkey.ldif --option="dsdb:schema update allowed"=true

Option 2.
Add 'dsdb:schema update allowed = true' to the DCs smb.conf, restart samba.

ldapmodify  -f schema.sudoers.ldif -D 'user@DOMAIN' -W -H ldaps://localhost
ldapmodify  -f schema.SSHpubkey.ldif -D 'user@DOMAIN' -W -H ldaps://localhost

Remove the line you added to smb.conf and restart samba again. 
```
