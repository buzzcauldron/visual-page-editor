%define name visual-page-editor
%define version 1.0.0
%define release 1
%define nwjs_version %{?nwjs_version}%{!?nwjs_version:0.44.4}

Summary: Visual editor for Page XML files
Name: %{name}
Version: %{version}
Release: %{release}%{?dist}
License: MIT
Group: Applications/Text
Source0: %{name}-%{version}.tar.gz
URL: https://github.com/buzzcauldron/visual-page-editor
BuildArch: x86_64
BuildRequires: curl, tar, gzip
Requires: perl

%description
Visual Page Editor is a modern visual editor for Page XML files, based on
NW.js. It provides an intuitive graphical interface for editing document
layout annotations and text regions.

This package includes a bundled NW.js runtime, so no external dependencies
are required.

%prep
%setup -q -n %{name}-%{version}

# Download NW.js if not present
if [ ! -d "nwjs" ] || [ ! -f "nwjs/nw" ]; then
    echo "Downloading NW.js v%{nwjs_version}..."
    curl -fLSs -o nwjs-sdk-linux-x64.tar.gz \
        "https://dl.nwjs.io/v%{nwjs_version}/nwjs-sdk-v%{nwjs_version}-linux-x64.tar.gz"
    tar -xzf nwjs-sdk-linux-x64.tar.gz
    mv nwjs-sdk-v%{nwjs_version}-linux-x64 nwjs
    rm -f nwjs-sdk-linux-x64.tar.gz
fi

%build
# No build step needed - this is a packaged application

%install
rm -rf %{buildroot}

# Install application files
mkdir -p %{buildroot}/usr/share/%{name}
cp -r html css js examples plugins xsd xslt package.json LICENSE.md README.md %{buildroot}/usr/share/%{name}/

# Install NW.js runtime
mkdir -p %{buildroot}/usr/lib64/%{name}
cp -r nwjs %{buildroot}/usr/lib64/%{name}/

# Install launcher script
mkdir -p %{buildroot}/usr/bin
install -m 755 bin/visual-page-editor %{buildroot}/usr/bin/%{name}

# Update launcher to check for bundled NW.js first
sed -i 's|^  nw=\$(which nw);$|  # Check for bundled NW.js first\n  nw="/usr/lib64/%{name}/nwjs/nw"\n  [ ! -f "$nw" ] \&\& nw=$(which nw);|' %{buildroot}/usr/bin/%{name}

# Install documentation
mkdir -p %{buildroot}/usr/share/doc/%{name}
cp README.md BUILD.md PACKAGING.md LICENSE.md %{buildroot}/usr/share/doc/%{name}/ 2>/dev/null || true

%files
%defattr(-,root,root,-)
/usr/share/%{name}
/usr/lib64/%{name}/nwjs
/usr/bin/%{name}
/usr/share/doc/%{name}

%changelog
* Tue Jan 14 2025 buzzcauldron <buzzcauldron@users.noreply.github.com> - 1.0.0-1
- Initial RPM package release
- Includes bundled NW.js v%{nwjs_version}

