Samba4 sudoers and openssh-lpk schema.
=======================================

Add sudoers and openssh-lpk schema to Samba4 DC.

Usage
-------

```
sed -i -e 's/${DOMAINDN}/CN=Common_Name,DC=your,DC=domain,DC=name/' sudo.*.ldif

ldbmodify -H /usr/local/samba/private/sam.ldb sudo.Container.ldif
ldbmodify -H /usr/local/samba/private/sam.ldb sudo.Defaults.ldif
ldbmodify -H /usr/local/samba/private/sam.ldb sudo.AdminUser.ldif
```

