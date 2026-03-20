#!/bin/sh
git init
git branch -M main
git clone https://github.com/pgElephant/pgraft.git
rm -Rf pgraft/.git
git add -A
git commit -m "clone upstream"
git remote add origin git@github.com:antioff/pgraft.git
git push -u origin main
git branch upstream
git merge -s ours upstream
git checkout upstream
git push --set-upstream origin upstream
git checkout main

ln -s pgraft/README.md ./
mkdir .gear

###########
cat > ".gear/rules" << \EOF
#pgver postgresql17 postgresql18 postgrespro-1c-18 etc
specsubst: pgver
tar: v@version@:pgraft
diff: v@version@:pgraft pgraft
EOF
##########
cat > "pgraft.spec" << \EOF
%set_verify_elf_method rpath=relaxed
%define PG_VER @pgver@
%define PG_NUM %(echo %PG_VER | tail -c 3)
%define PG_PREFIX %([[ %PG_VER =~ "pro" ]] && echo "/opt/pgpro/1c-%PG_NUM" || echo "%_usr")
%define PG_LIB %([[ %PG_VER =~ "pro" ]] && echo "%PG_PREFIX/lib" || echo "%_libdir/pgsql")
%define PG_DATADIR %([[ %PG_VER =~ "pro" ]] && echo "%PG_PREFIX/share" || echo "%_datadir/pgsql")
%define sname pgraft

Name:           %PG_VER-%sname
Summary:        Raft consensus extension for PostgreSQL %PG_VER
Version:        1.0.0
Release:        alt1
Packager:       antioff <nobody@altlinux.org>
License:        MIT
URL:            https://github.com/pgelephant/pgraft
Group:          Databases

Source0: %sname-%version.tar
Patch0: %sname-%version-%release.patch

BuildRequires:  golang
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  libjson-c-devel
BuildRequires:  %([[ %PG_VER =~ "pro" ]] && echo "%PG_VER-devel" || echo "%PG_VER-server-devel")

Requires:	libjson-c5
Requires:       %PG_VER-server

%description
pgraft is a PostgreSQL extension implementing Raft consensus for automatic
leader election, log replication, and split-brain prevention.

Features:
- Automatic leader election using Raft consensus
- Fast failover detection (2-second timeout)
- Split-brain prevention via quorum
- Key-value store with strong consistency
- Background worker for Raft processing
- Integration with pgbalancer for automatic failover

%prep
%setup -q -n %sname-%version
%autopatch -p1

%build
export GOROOT=/usr/lib/golang
export GOPROXY="https://proxy.golang.org,direct"
export GOPATH=/usr/src/go
export CGO_ENABLED=1
export GOCACHE=%{_builddir}/go-cache

mkdir -p ${GOCACHE}
cd src
go build -buildmode=c-shared -o pgraft_go.so pgraft_go.go
cd ..

make USE_PGXS=1 PG_CONFIG=%PG_PREFIX/bin/pg_config

%install
rm -rf %{buildroot}
install -d -m 700 %buildroot%_sharedstatedir/%sname

make DESTDIR=%{buildroot} USE_PGXS=1 PG_CONFIG=%PG_PREFIX/bin/pg_config install


%clean
rm -rf %{buildroot}

%post
echo "pgraft %{version} installed for PostgreSQL %PG_VER"
echo "Enable with: psql -c 'CREATE EXTENSION pgraft;'"

%files
%doc README.md
%PG_LIB
%PG_DATADIR
%_sharedstatedir/%sname

%changelog
* Wed Feb 04 2026 antioff <nobody@altlinux.org> 1.0.0-alt1
- Initial

* Thu Oct 24 2024 pgElephant Team <team@pgelephant.org> - 1.0.0-1
- Initial release
- Raft consensus implementation
- Automatic leader election
- Fast failover (2s timeout)
- Integration with pgbalancer

EOF
#########

cat > "pgpro_repo.sh" << \EOF
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
EOF

############
chmod +x pgpro_repo.sh
############
cat > "update.sh" << \EOF
#!/bin/sh
git add -A
git commit -m "Update"
git checkout upstream
rm -Rf pgraft
git clone https://github.com/pgElephant/pgraft.git

cd pgraft
OrigTAG=$(git describe --tags --abbrev=0)
rm -Rf .git

echo "Enter version " $OrigTAG " : "
read TAG
git tag $TAG 
git add -A
git commit -m "Update upstream"
git push
git push origin $TAG 
cd ../

git checkout main
git merge upstream -m "Merge with upstream $TAG"
cd pgraft/src/
rm -Rf vendor
go mod tidy -v
go mod vendor -v
cd ../../

git tag -d $(git tag -l "postgres*")
git push origin --delete $(git ls-remote --refs origin postgres* | cut -d$'\t' -f2)

gear-store-tags -ac
git add -A
git commit -m "Update Vendor $TAG"
gear-create-tag -n "postgrespro-1c-18" -s pgver=postgrespro-1c-18
gear-create-tag -n "postgresql17" -s pgver=postgresql17
git push
git push origin --tags

EOF
############
chmod +x update.sh

git add -A
git commit -m "Init gear"

./update.sh
git push



