%define name visual-page-editor
%define version 1.0.0
%define release 1
%{!?nwjs_version:%define nwjs_version 0.44.4}
%define debug_package %{nil}

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
Requires: perl(Cwd)

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
    echo "==> Downloading NW.js v%{nwjs_version}..."
    if ! curl -fLSs -o nwjs-sdk-linux-x64.tar.gz \
        "https://dl.nwjs.io/v%{nwjs_version}/nwjs-sdk-v%{nwjs_version}-linux-x64.tar.gz"; then
        echo "Error: Failed to download NW.js v%{nwjs_version}" >&2
        exit 1
    fi
    if ! tar -xzf nwjs-sdk-linux-x64.tar.gz; then
        echo "Error: Failed to extract NW.js archive" >&2
        rm -f nwjs-sdk-linux-x64.tar.gz
        exit 1
    fi
    if [ ! -d "nwjs-sdk-v%{nwjs_version}-linux-x64" ]; then
        echo "Error: Extracted NW.js directory not found" >&2
        echo "Expected: nwjs-sdk-v%{nwjs_version}-linux-x64" >&2
        rm -f nwjs-sdk-linux-x64.tar.gz
        exit 1
    fi
    if ! mv nwjs-sdk-v%{nwjs_version}-linux-x64 nwjs; then
        echo "Error: Failed to rename NW.js directory" >&2
        rm -f nwjs-sdk-linux-x64.tar.gz
        exit 1
    fi
    if [ ! -d "nwjs" ] || [ ! -f "nwjs/nw" ]; then
        echo "Error: NW.js directory is missing or incomplete after installation" >&2
        echo "Expected nwjs directory with nw binary" >&2
        rm -f nwjs-sdk-linux-x64.tar.gz
        exit 1
    fi
    rm -f nwjs-sdk-linux-x64.tar.gz
    echo "==> NW.js v%{nwjs_version} downloaded and extracted successfully"
fi

%build
# No build step needed - this is a packaged application
echo "==> Build phase: No compilation needed (packaged application)"

%install
echo "==> Installing files to build root..."
rm -rf %{buildroot}

# Install application files
echo "==> Installing application files..."
mkdir -p %{buildroot}/usr/share/%{name}
cp -r html css js examples plugins xsd xslt package.json LICENSE.md README.md %{buildroot}/usr/share/%{name}/

# Install NW.js runtime
echo "==> Installing NW.js runtime..."
mkdir -p %{buildroot}/usr/lib64/%{name}
cp -r nwjs %{buildroot}/usr/lib64/%{name}/

# Install launcher script
echo "==> Installing and configuring launcher script..."
mkdir -p %{buildroot}/usr/bin
install -m 755 bin/visual-page-editor %{buildroot}/usr/bin/%{name}

# Update launcher to check for bundled NW.js first and fix application path
# Use awk to fix both NW.js path and application location path
awk '
/^  nw=\$\(which nw\);$/ { \
  print "  # Check for bundled NW.js first"; \
  print "  nw=\"/usr/lib64/%{name}/nwjs/nw\""; \
  print "  [ ! -f \"" "$" "nw\" ] && nw=$(which nw);"; \
  next \
}
/^[[:space:]]*nw_page_editor=.*nw-page-editor.*$/ { \
  print; \
  print "  [ ! -f \"" "$" "nw_page_editor/js/nw-app.js\" ] && [ -f \"/usr/share/%{name}/js/nw-app.js\" ] &&"; \
  print "    nw_page_editor=\"/usr/share/%{name}\""; \
  next \
}
{ print }
' %{buildroot}/usr/bin/%{name} > %{buildroot}/usr/bin/%{name}.tmp && \
chmod 755 %{buildroot}/usr/bin/%{name}.tmp && \
mv %{buildroot}/usr/bin/%{name}.tmp %{buildroot}/usr/bin/%{name}

# Install documentation
echo "==> Installing documentation..."
mkdir -p %{buildroot}/usr/share/doc/%{name}
cp README.md BUILD.md PACKAGING.md LICENSE.md %{buildroot}/usr/share/doc/%{name}/ 2>/dev/null || true
echo "==> Installation complete. Packaging files..."

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

