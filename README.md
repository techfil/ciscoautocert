# ciscoautocert

This small repository contains the files needed to automate Let's Encrypt certificate renewal on Cisco IOS-XE routers,
as documented in [https://retibus.net/blog/letsencrypt-on-cisco-routers/](https://retibus.net/blog/letsencrypt-on-cisco-routers/).

## Pre-requisites

1. IOS-XE router connected to the Internet and running 17.9 or 17.10 (but this could work easily on other versions);
2. the setup needed for IOS Guest Shell container;
3. a domain where you can add or manipulate A and CNAME records (depending on the type of validation you use in certbot).

## Instructions

* copy the content of the `ios-applet.eem` file and modify the cron entry to suit your needs, then paste it into IOS configuration
* enter into the guestshell
* run `sudo bash` (from now on it's assumed you are always root unless stated otherwise)
* `mkdir /root && cd /root`
* `yum install git python3.9` - (if yum fails with GPG errors, refer to [https://github.com/techfil/ciscoautocert/issues/1#issuecomment-1872160562] for a fix on ARM platforms)
* `git clone https://github.com/techfil/ciscoautocert.git`
* `python3.9 -m venv ciscoautocert`
* `source ciscoautocert/bin/activate`
* `cd ciscoautocert && ./first_run.sh`
* follow the instructions on the screen, especially when you have to create the acme-dns records (otherwise certbot will fail to issue the certificate).
* if all went fine, you will see the pkcs12 bundle in `/flash/guest-share/ciscoautocert.p12`
* exit from the root bash, and run `crontab -e` to add a new guestshell account cron entry:
    ```
    33 3 * * * sudo /home/guestshell/renewcron.sh
    ```

## In case of problems

You can open an issue here on github.
