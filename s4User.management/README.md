Samba4 add user UNIX attributes.
=======================================

Dependencies: openssl, whiptail.

Usage
-------

Update samba4ldb.conf with the correct URL and baseDN.

```
sed -i -e 's/${DOMAINDN}/DC=your,DC=domain,DC=name/' samba4ldb.conf
```

Update UID/GID range.

Optional
---------
Set password in s4menu.sh script and obfuscate using shc or other tool.

```
./shc -f s4menu.sh
```
