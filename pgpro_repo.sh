#!/bin/sh
PG_VER=18

LISTNAME="pgpro_${PG_VER}"
if [ ! -f /etc/apt/sources.list.d/$LISTNAME.list ]; then

. /etc/os-release
verid=${VERSION_ID#p}
ALT_ID=${verid%%.*}
ARCH=$(rpm -q --qf="%{arch}" rpm)

REPO="https://repo.postgrespro.ru/1c/1c-$PG_VER/altlinux/$ALT_ID"
LISTNAME="pgpro_${PG_VER}"

if [ ! -d /etc/pki/$LISTNAME ]; then
     mkdir -p /etc/pki/$LISTNAME
fi

keyfile=/etc/pki/$LISTNAME/RPM-GPG-KEY-POSTGRESPRO

cat > "$keyfile" << KEY-PGPRO
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

mQENBFWdEjABCAC6QeLt0UJUQlDI2Z+R/y1OyOMU+5Te176I0+/Xpc2v5NsucW2M
kLTdOif0iW+q5h1djL+Pc5yu1fojZCvcihhbURnWECF52BmRnOC9jI0eTHq3fcPZ
IE3gqMJSn5sx2kJZ7n8XE0RbQ/hr51BLI+lzeqR3JAKBIqpVDKRrdP9Y1xVR/7Ne
q4FNR+osm6W4sM9G+TA/YADrWX3/TPXA4AN+2uNCNY0wK7em8V0oSZJVpEzvu5EP
djC6GX08XSvhPNo52o3u3tpFWH7ICw2BEYe672bJTjmi8wFgPW04pw49Jpvw4i1R
RhkpQqQ/b9bSveoNpvN32ElAJSaize76+q/TABEBAAG0KlJvYm90IChTaWduaW5n
IHJlcG9zKSA8ZGJhQHBvc3RncmVzcHJvLnJ1PokBOAQTAQIAIgUCVZ0SMAIbAwYL
CQgHAwIGFQgCCQoLBBYCAwECHgECF4AACgkQf5rlpi0t8LQpKQgAuJkOKNdnCSCt
GbNTwAbk414UPYa2B1M1DD6MfcSd6NnJNBVtRoaSWWISQB6gP+/w1jmD8XZbj/oH
5HAHjOyh9Lb3z1xeMIQnBnfGtcqmU5QrF55Yi0H9G0s+fn9oodfNXqAa/zARpBw6
q3LRSBCjT50/XA5G3AzUr7fIDb68FmEOCQukzs0uWBr5fkrRC21b1DcuhzbBay8X
pnlpB+Ma1PTIFgRdRl/KwYTzO80TWFMCeYfXQRh8StuQxRcVCqnv4F6seHqmbL7A
vOZ7GMymsz/IRHGVk4eVC6/94Y3vkV/0eQ+Yom+NtAFnep6G4OhxIeviZ697eFYF
+j4YsyDD+g==
=Q7MS
-----END PGP PUBLIC KEY BLOCK-----
KEY-PGPRO

apt-get install -y apt-https 
echo "rpm $REPO $ARCH pgpro" > "/etc/apt/sources.list.d/$LISTNAME.list"
echo "rpm $REPO noarch pgpro" >> "/etc/apt/sources.list.d/$LISTNAME.list"
chmod 0644 "/etc/apt/sources.list.d/$LISTNAME.list"
apt-get update 
fi
