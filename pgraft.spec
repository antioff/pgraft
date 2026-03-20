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

