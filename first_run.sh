#!/bin/bash

if [[ ! -e first_run.sh ]]; then
   echo 'Please cd into the script folder before running it. Aborting.'
   exit 1
fi
if [[ ! -e renewcron.template ]]; then
   echo 'Important files are missing. Redeploy the script following the instructions on retibus.net - aborting.'
   exit 1
fi
if [ ! -v VIRTUAL_ENV ]; then
    echo "We are not in a virtual env. Aborting."
    exit 1
fi
cp acme-dns-client/acme-dns-client /bin/
MYIP=$(curl -s ifconfig.me)
MYLOC=$PWD

echo What is the FQDN of this router?
read -p "Fully qualified Domain Name: " MYFQDN
read -r -p "Hostname to use will be $MYFQDN, proceed? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo "Let's proceed"
else
    echo "No action."
    exit
fi

acme-dns-client register --dangerous -d $MYFQDN -allow %MYIP/32

which certbot > /dev/null 2>&1

if [ $? -eq 0 ]
then
  echo "Success: I found certbot in the path and can proceed..."
else
  echo "I did not find certbot :( " >&2
  echo "Trying to install certbot..."
  python -m pip install --upgrade pip
  pip install certbot
  which certbot > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo 'Certbot was successfully installed, proceeding...'
  else
    echo 'There was a problem installing certbot. Aborting.'
    exit 1
  fi
fi

certbot certonly --manual --preferred-challenges dns --manual-auth-hook 'acme-dns-client' -d $MYFQDN --key-type rsa --config-dir /root/certbot-config/ --work-dir /root/certbot-work/ --logs-dir /root/certbot-logs/
cd /root/certbot-config/live/$MYFQDN/

if [ -f privkey.pem ] && [ -f fullchain.pem ]; then
   cat privkey.pem fullchain.pem > /root/combined.pem
   cd /root/
   openssl pkcs12 -export -in combined.pem -name CISCOAUTOCERT -passout pass:cisco -out /root/ciscoautocert.p12
   mv ciscoautocert.p12 /bootflash/guest-share/
   rm /root/combined.pem
   echo 'Certificate ready for import on IOS-XE.'
   echo '***************************************'
   echo ''
   echo 'Run the crontab -e command to add `sudo /home/guestshell/renewcron.sh` as an entry if you want the certificate to be automatically renewed.'
   echo ''
   echo 'Verify that /home/guestshell/renewcron.sh contains the correct path to where you deployed ciscoautocert (usually /root/ciscoautocert/).'
   echo '***************************************'
   cd $MYLOC
   cp renew-hook.sh /root/
   sed "s|ENVPATHHERE|$VIRTUAL_ENV|g" renewcron.template > /home/guestshell/renewcron.sh
   chown guestshell /home/guestshell/renewcron.sh
   chmod ug+x /home/guestshell/renewcron.sh
   exit 0
else
   echo "Failure: I did not find the certificate files, something went wrong with Certbot. Aborting." >&2
   exit 1
fi
