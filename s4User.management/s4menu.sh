#!/bin/bash
#----------------------------------------------------------------------
# Description:
# Author: manyax <manyax@manayx.net>
# Created at: Wed Jan 16 09:20:47 UTC 2019
# Computer: gw103.manyax.net
# System: Linux 3.10.0-957.1.3.el7.x86_64 on x86_64
#
# Copyright (c) 2019 manyax All rights reserved.
#
#Sets UID, GID, linux home directory and ldapPublicKey for a s4 user.
#
#----------------------------------------------------------------------

source ./samba4ldb.conf
#Create password using: 
#echo "secretpassword" | openssl aes-256-cbc -a -salt
#Copy the hash to PwdHash and comment out Password to enable password protect.
#
#Password="secretpassword"
#
PwdHash="U2FsdGVkX18ZgPyFvuGJ/a6NFniHYR7R2zbI5g6PJ30="

selectMenu() {
	mainMenu=$(
	whiptail --backtitle "Samba4 UNIX user management" --title "Samba4 user management" --menu "Make your choice" 16 60 9 \
			"1)" "UNIX user attributes."   \
			"2)" "User SSH public-key."  \
			"3)" "Exit."		3>&2 2>&1 1>&3
	)
	case $mainMenu in
			"1)")
				UnixAttrMenu
			;;
			"2)")
				SSHattrMenu
			;;
			"3)") exit
			;;
	esac
}


UnixAttrMenu() {
	mainMenu=$(
	whiptail --backtitle "Samba4 UNIX user management" --title "Samba4 user management" --menu "Make your choice" 16 60 9 \
			"1)" "Add UNIX user attributes."   \
			"2)" "Update UNIX user attributes."  \
			"3)" "Delete Unix user attributes." \
			"4)" "Show User attributes." \
			"5)" "Exit."		3>&2 2>&1 1>&3
	)
	case $mainMenu in
			"1)")
				action=add
				ValidateUserInput $action
			;;
			"2)")
				action=replace
				ValidateUserInput $action	
			;;
			
			"3)")
				action=delete
				ValidateUserInput $action		
			;;
			"4)")
				act=Posix
				ShowRecords	$act
			;;			
			"5)") exit
			;;
	esac
}

SSHattrMenu() {
	mainMenu=$(
	whiptail --backtitle "Samba4 ldapPublicKey management" --title "Samba4 ldapPublicKey" --menu "Make your choice" 16 100 9 \
			"1)" "Add user SSH public-key."   \
            "2)" "Add multiple SSH publickeys to user."   \
			"3)" "Update user SSH public-key."  \
			"4)" "Delete user SSH public-key." \
			"5)" "Show user ldapPublicKey." \
			"6)" "Exit."		3>&2 2>&1 1>&3
	)
	case $mainMenu in
			"1)")
				action=add
				ValidateSSHInput $action
			;;
			"2)")
				action=append
				ValidateSSHInput $action	
			;;		
			"3)")
				action=replace
				ValidateSSHInput $action	
			;;		
			"4)")
				action=delete
				ValidateSSHInput $action		
			;;
			"5)")
			    act=PublicKey
				ShowRecords $act
			;;			
			"6)") exit
			;;
	esac
}
	
main (){
if [ "$Password" = "" ]; then
 selectMenu
else
 GetUserPassword
fi	
}

check_root() {
if ! [ $(id -u) = 0 ]; then
 echo "You must be root to do this." 1>&2
 exit 100
fi
}

GetUserPassword() {
GetPw=$(whiptail --backtitle "Password" --title "Master Password" --passwordbox "Enter your password and choose Ok to continue." 10 60 3>&1 1>&2 2>&3)
if [ "`echo "$PwdHash" | openssl aes-256-cbc -a -d -salt -pass pass:$GetPw 2>&1`" = "$Password" ]; then
 selectMenu
else
 if whiptail --yesno "Wrong password!!!\n\nWant to retry?" 10 80; then
  GetUserPassword
 else 
  exit 0
 fi
  exit 0
fi
}

ValidateUserInput() {
user=$(whiptail --backtitle "Samba4 user management" --inputbox "Valid USER: " 8 46 3>&1 1>&2 2>&3)
exitstatus=$?;
if [ $exitstatus = 1 ]; then 
 exit 1;
fi
LdbSearch=$(ldbsearch -H "$url" -b "$basedn" sAMAccountName displayName mail uidNumber)
if [ "$user" = "" ]; then
 if whiptail --yesno "No username supplied...FAIL\n\nWant to retry?" 10 80; then
  ValidateUserInput
 else 
  exit 100
 fi
elif [ -z $(echo "$LdbSearch" | grep -w "sAMAccountName: $user" | awk '{print $2}') ]; then
 if whiptail --title "ERROR: $user" --yesno "User $user does not exist\n\nWant to retry?" 10 80; then
  ValidateUserInput
 else 
  exit 100
 fi
else
 if [ "$action" = "add" ]; then
  if [ $(echo "$LdbSearch" | awk 'BEGIN{RS="#"} /\<'$user'\>/ { printf "#" $0 }' | grep uidNumber: | awk '{print $2}') ]; then
   uidNo=$(echo "$LdbSearch" | awk 'BEGIN{RS="#"} /\<'$user'\>/ { printf "#" $0 }' | grep uidNumber: | awk '{print $2}')
   if whiptail  --title "ERROR: User $user has UNIX attributes set." --yesno "User $user has UID: $uidNo set.\nUse update.\n\nReturn to user menu?" 10 60; then
    UnixAttrMenu
   else 
    exit 100
   fi
  fi
 elif [ "$action" = "replace" ]; then
  if [ -z $(echo "$LdbSearch" | awk 'BEGIN{RS="#"} /\<'$user'\>/ { printf "#" $0 }' | grep uidNumber: | awk '{print $2}') ]; then
   if whiptail --title "ERROR: $user has no UID" --yesno "User $user has no Unix attributes set!\n\nReturn to main menu?" 15 60; then
    selectMenu
   else 
    exit 100
   fi
  fi   
 elif [ "$action" = "delete" ]; then
  if [ -z $(echo "$LdbSearch" | awk 'BEGIN{RS="#"} /\<'$user'\>/ { printf "#" $0 }' | grep uidNumber: | awk '{print $2}') ]; then
   if whiptail --title "ERROR: $user has no UID" --yesno "User $user has no Unix attributes set!\n\nReturn to main menu?" 15 60; then
    selectMenu
   else 
    exit 100
   fi   
  else
   if whiptail --title "${action^} $user UNIX attributes" --yesno "${action^} UNIX attributes for $user\n\nAre you sure?" 10 80; then
    #Delete Validation ended
    s4ModUserAttr $user $userID $action   
   else 
    if whiptail --yesno "Want to return to main menu?" 10 80; then
     selectMenu
    else 
     exit 100
    fi
   fi
  fi
 fi  
 userID=$(whiptail --inputbox  "UID: " 8 46 3>&1 1>&2 2>&3) 
 exitstatus=$?;
 if [ $exitstatus = 1 ]; then 
  exit 1;
 fi 
 if [ "$userID" = "" ]; then
  if whiptail --yesno "Not enough arguments supplied...FAIL\n\nWant to retry?" 10 80; then
   ValidateUserInput
  else 
   exit 100
  fi
 elif ! [[ $userID =~ ^[0-9]+$ ]]; then
  if whiptail --yesno "UID number not valid...FAIL\n\nWant to retry?" 10 80; then
   ValidateUserInput
  else 
   exit 100
  fi	   
 elif ! [[ $userID -ge $uid_range_min && $userID -le $uid_range_max ]]; then
  if whiptail --yesno "UID number not in range\nRange is $uid_range_min - $uid_range_max\n\nWant to retry?" 10 80; then
   ValidateUserInput
  else 
   exit 100
  fi
 elif [ $(echo "$LdbSearch" | grep -w "uidNumber: $userID" | awk '{print $2}') ]; then
  uidName=$(echo "$LdbSearch" | awk 'BEGIN{RS="#"} /\<uidNumber: '$userID'\>/ { printf "#" $0 }' | grep displayName: |sed 's/^\displayName: //')
  uidN=$(echo "$LdbSearch" | awk 'BEGIN{RS="#"} /\<uidNumber: '$userID'\>/ { printf "#" $0 }' | grep sAMAccountName: |awk '{print $2}')
  uidE=$(echo "$LdbSearch" | awk 'BEGIN{RS="#"} /\<uidNumber: '$userID'\>/ { printf "#" $0 }' | grep mail: |sed 's/^\mail: //')
  if whiptail  --title "UID $userID already in use" --yesno "ERROR: UID $userID belongs to $uidN\n\nDisplay name: $uidName\nEmail: $uidE \n\nWant to retry?" 15 60; then
   ValidateUserInput
  else
   exit 100
  fi   
 else
  if whiptail --title "${action^} $user UNIX attributes" --yesno "${action^} UNIX attributes for $user UID:$userID GID:$userID\n\nIs the information correct?" 10 80; then
   #Validation ended
   s4ModUserAttr $user $userID $action
  else 
   if whiptail --yesno "Want to return to main menu?" 10 80; then
    selectMenu
   else 
    exit 100
   fi
  fi 
 fi
fi
}

 
ValidateSSHInput() {
user=$(whiptail --backtitle "Samba4 ldapPublicKey management" --title "${action^} user ldapPublicKey" --inputbox "Valid USER: " 8 46 3>&1 1>&2 2>&3)
exitstatus=$?;
if [ $exitstatus = 1 ]; then 
 exit 1;
fi
LdbSearch=$(ldbsearch -H "$url" -b "$basedn" sAMAccountName uidNumber sshPublicKey)
if [ "$user" = "" ]; then
 if whiptail --yesno "No username supplied...FAIL\n\nWant to retry?" 10 80; then
  ValidateSSHInput
 else 
  exit 100
 fi
elif [ -z $(echo "$LdbSearch" | grep -w "sAMAccountName: $user" | awk '{print $2}') ]; then
 if whiptail --title "ERROR: $user" --yesno "User $user does not exist\n\nWant to retry?" 10 80; then
  ValidateSSHInput
 else 
  exit 100
 fi
elif [ -z $(echo "$LdbSearch" | awk 'BEGIN{RS="#"} /\<'$user'\>/ { printf "#" $0 }' | grep uidNumber: | awk '{print $2}') ]; then
 if whiptail --title "ERROR: $user has no PosixAccount" --yesno "User $user has no Unix attributes set!\nAdd UID and GID first.\nReturn to main menu?" 15 60; then
  selectMenu
 else 
  exit 100
 fi
else
 if [ "$action" = "add" ]; then
  if [ $(echo "$LdbSearch" | awk 'f && !NF{exit} /\<sAMAccountName: '$user'\>/ {f=1} f'| grep -m1 sshPublicKey: | awk '{print $2}') ]; then
   PresenKey=$(echo "$LdbSearch" | awk 'f && !NF{exit} /\<sAMAccountName: '$user'\>/ {f=1} f'| sed -ne '/sshPublicKey:/,$p' | sed 's/sshPublicKey: \s*//'|tr -d '\n')  
   if whiptail --title "ERORR: User $user has a key set!!!" --yesno "\n\nKey: $PresenKey\n\n\nUse update or add multiple!\n\nReturn to user menu?" 30 80; then
    SSHattrMenu
   else 
    exit 100
   fi
  else 
   PubKey=$(whiptail --title "${action^} $user SSH publickey" --inputbox  "\n\nEnter SSH Public key:\n(ssh-rsa key user@host)\n" 20 40 3>&1 1>&2 2>&3)
   exitstatus=$?;
   if [ $exitstatus = 1 ]; then 
    exit 1;
   fi
   if [ "$PubKey" = "" ]; then
    if whiptail --yesno "Not enough arguments supplied...FAIL\n\nWant to retry?" 10 80; then
     ValidateSSHInput
    else 
     exit 100
    fi
   fi	
  fi
 elif [[ "$action" = "replace" || "$action" = "append" ]]; then
  if [ -z $(echo "$LdbSearch" | awk 'f && !NF{exit} /\<sAMAccountName: '$user'\>/ {f=1} f'| grep -m1 sshPublicKey: | awk '{print $2}') ]; then
   if whiptail --title "ERORR: User $user has no key set!" --yesno "User $user has no SSH public key set! Use add!\n\nReturn to select menu?" 10 80; then
    SSHattrMenu
   else 
    exit 100
   fi
  else
   PubKey=$(whiptail --title "${action^} $user SSH publickey" --inputbox  "\n\nEnter SSH Public key:\n(ssh-rsa key user@host)\n" 20 40 3>&1 1>&2 2>&3)
   exitstatus=$?;
   if [ $exitstatus = 1 ]; then 
    exit 1;
   fi
   if [ "$PubKey" = "" ]; then
    if whiptail --yesno "Not enough arguments supplied...FAIL\n\nWant to retry?" 10 80; then
     ValidateSSHInput
    else 
     exit 100
    fi
   fi	   
  fi
 elif [ "$action" = "delete" ]; then
  if [ -z $(echo "$LdbSearch" | awk 'BEGIN{RS="#"} /\<'$user'\>/ { printf "#" $0 }' | grep -m1 sshPublicKey | awk '{print $2}') ]; then
   if whiptail --title "ERORR: No ssh keys found" --yesno "User $user has no ldapPublicKey set!\n\nReturn to select menu?" 10 80; then
    selectMenu
   else 
    exit 100
   fi
  fi
 fi 
if whiptail --title "${action^} $user ldapPublicKey" --yesno "${action^} ldapPublicKey for $user\n\nAre you sure?" 10 80; then
 #Delete Validation ended
 s4ModSSHAttr $user $action   
 else 
  if whiptail --yesno "Want to return to main menu?" 10 80; then
   selectMenu
  else 
   exit 100
  fi
 fi
fi
}

ShowRecords(){
user=$(whiptail --backtitle "Samba4 user management" --title "Show user records" --inputbox "Valid USER: " 8 46 3>&1 1>&2 2>&3)
exitstatus=$?;
if [ $exitstatus = 1 ]; then 
 exit 1;
fi
LdbSearch=$(ldbsearch -H "$url" -b "$basedn" sAMAccountName displayName mail uidNumber gidNumber sshPublicKey)
if [ "$user" = "" ]; then
 if whiptail --yesno "No username supplied...FAIL\n\nWant to retry?" 10 60; then
  ShowRecords
 else 
  exit 100
 fi
elif [ -z $(echo "$LdbSearch" | grep -w "sAMAccountName: $user" | awk '{print $2}') ]; then
 if whiptail --title "ERROR: $user" --yesno "User $user does not exist\n\nWant to retry?" 10 60; then
  ShowRecords
 else 
  exit 100
 fi
elif [ -z $(echo "$LdbSearch" | awk 'BEGIN{RS="#"} /\<'$user'\>/ { printf "#" $0 }' | grep uidNumber: | awk '{print $2}') ]; then
 if whiptail --title "ERROR: $user has no PosixAccount" --yesno "User $user has no Unix attributes set!\n\nWant to retry?" 15 60; then
  ShowRecords
 else 
  exit 100
 fi
else
 if [ "$act" = "Posix" ]; then
  disN=$(echo "$LdbSearch" | awk 'BEGIN{RS="#"} /\<'$user'\>/ { printf "#" $0 }' | grep displayName: |sed 's/^\displayName: //')
  uidN=$(echo "$LdbSearch" | awk 'BEGIN{RS="#"} /\<'$user'\>/ { printf "#" $0 }' | grep uidNumber: |awk '{print $2}')
  gidN=$(echo "$LdbSearch" | awk 'BEGIN{RS="#"} /\<'$user'\>/ { printf "#" $0 }' | grep gidNumber: |awk '{print $2}')
  uidE=$(echo "$LdbSearch" | awk 'BEGIN{RS="#"} /\<'$user'\>/ { printf "#" $0 }' | grep mail: |sed 's/^\mail: //')
  whiptail  --title "$user Records" --msgbox "Display name: $disN\nEmail: $uidE \nUserID: $uidN\nGroupID: $gidN" 15 60
  exitstatus=$?; 
  if [ $exitstatus = 1 ]; then 
   exit 1; 
  else 
   UnixAttrMenu  
  fi
 elif [ "$act" = "PublicKey" ]; then 
  if [ $(echo "$LdbSearch" | awk 'f && !NF{exit} /\<sAMAccountName: '$user'\>/ {f=1} f'| grep -m1 sshPublicKey: | awk '{print $2}') ]; then
   PresenKey=$(echo "$LdbSearch" | awk 'f && !NF{exit} /\<sAMAccountName: '$user'\>/ {f=1} f'| sed -ne '/sshPublicKey:/,$p' | sed 's/sshPublicKey: \s*//')  
   whiptail --title "User $user ldapPublicKey" --msgbox "Key:\n$PresenKey\n" 10 60
   if [ $exitstatus = 1 ]; then 
    exit 1; 
   else 
    SSHattrMenu  
   fi
  else 
   if whiptail --title "User $user ldapPublicKey" --yesno "User $user has no ldapPublicKey set!\n\nReturn to select menu?" 10 60; then
    SSHattrMenu
   else 
    exit 100
   fi
  fi
 else 
  echo "ERROR: No action was selected!"
  exit 100
 fi 
fi 
}

s4ModUserAttr() {
if [ "$action" = "add" ]; then
 #echo $user $action
modUID="dn: CN=$user,$basedn
changetype: modify
$action: objectclass
objectclass: posixaccount
-
$action: uidnumber
uidnumber: $userID
-
$action: gidnumber
gidnumber: $userID
-
$action:unixhomedirectory
unixhomedirectory: /home/$user
-
$action: loginshell
loginshell: /bin/bash"

modMsg="${action^} UNIX attributes UID:$userID GID:$userID to $user"

elif [ "$action" = "replace" ]; then
modUID="dn: CN=$user,$basedn
changetype: modify
-
$action: uidnumber
uidnumber: $userID
-
$action: gidnumber
gidnumber: $userID"

modMsg="${action^} UNIX attributes UID:$userID GID:$userID to $user"

elif [ "$action" = "delete" ]; then
modUID="dn: CN=$user,$basedn
changetype: modify
-
$action: uidnumber
-
$action: gidnumber
-
$action:unixhomedirectory
-
$action: loginshell
-
$action: objectclass
objectclass: posixaccount"

modMsg="${action^} $user UNIX attributes"

else 
 echo "ERROR: No action was selected!"
 exit 100
fi

if [ $Debug = "1" ]; then
 echo "$modUID" > debug-S4edit.txt
else
 echo "$modUID" | ldbmodify --url=$url -b dc=$basedn
fi

whiptail --title "${action^} $user UNIX attributes" --msgbox "$modMsg" 10 80

if whiptail --yesno "Want to return to main menu?" 10 80; then
 selectMenu
else 
  exit 100
fi  
}

s4ModSSHAttr() {
# CheckSSHExists $user $PubKey $action
if [ "$action" = "add" ]; then
modSSHKey="dn: CN=$user,$basedn
changetype: modify
$action: objectClass
objectclass: ldapPublicKey
-
$action: sshPublicKey
sshPublicKey: $PubKey"

modMsg="${action^}ed ldapPublicKey \nUSER: $user\nkey: $PubKey\n"

elif [ "$action" = "append" ]; then
modSSHKey="dn: CN=$user,$basedn
changetype: modify
-
add: sshPublicKey
sshPublicKey: $PubKey"

modMsg="${action^}ed ldapPublicKey \nUSER: $user\nkey: $PubKey\n"

elif [ "$action" = "replace" ]; then
deleteSSHKey="dn: CN=$user,$basedn
changetype: modify
-
delete: sshPublicKey"

modSSHKey="dn: CN=$user,$basedn
changetype: modify
-
$action: sshPublicKey
sshPublicKey: $PubKey"

modMsg="All keys were deleted and ${action^}ed \nUSER: $user\nkey: $PubKey\n"

elif [ "$action" = "delete" ]; then
modSSHKey="dn: CN=$user,$basedn
changetype: modify
-
$action: sshPublicKey
-
$action: objectClass
objectclass: ldapPublicKey"

modMsg="${action^}ed ldapPublicKey USER: $user"
		
else 
 echo "ERROR: No action was selected!"
 exit 100
fi

if [ $Debug = "1" ]; then
  if [ "$action" = "replace" ]; then
   echo "$deleteSSHKey" > debug-S4edit.txt
   echo "$modSSHKey" >> debug-S4edit.txt
  else 
   echo "$modSSHKey" > debug-S4edit.txt
  fi	
else
  if [ "$action" = "replace" ];	then
   echo "$deleteSSHKey" | ldbmodify --url=$url -b dc=$based
   echo "$modSSHKey" | ldbmodify --url=$url -b dc=$based
  else
   echo "$modSSHKey" | ldbmodify --url=$url -b dc=$basedn
  fi
fi

whiptail --title "${action^}ed $user ldapPublicKey" --msgbox "$modMsg" 10 80
if whiptail --yesno "Want to return to main menu?" 10 80; then
 selectMenu
else 
 exit 100
fi
}

main
