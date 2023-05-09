#!/bin/bash

cd $RENEWED_LINEAGE
if [ -f privkey.pem ] && [ -f fullchain.pem ]; then
   cat privkey.pem fullchain.pem > /root/combined.pem
   cd /root/
   openssl pkcs12 -export -in combined.pem -name CISCOAUTOCERT -passout pass:cisco -out /root/ciscoautocert.p12
   mv ciscoautocert.p12 /bootflash/guest-share/
   rm /root/combined.pem
   echo "Certificate in $RENEWED_LINEAGE was renewed, and is ready to be imported into IOS-XE at $(date)." >> /home/guestshell/ciscoautocert.log
   exit 0
else
   echo "Failure: I did not find the certificate files, something went wrong with Certbot. Aborting." >> /home/guestshell/ciscoautocert.log
   exit 1
fi
