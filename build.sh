#!/bin/bash

set -o errexit -o pipefail -o nounset

#cat /github/workspace/README.md

REPOSITORY=$INPUT_REPOSITORY
GPG_PRIVATE_KEY="$INPUT_GPG_PRIVATE_KEY"
GPG_PASSPHRASE=$INPUT_GPG_PASSPHRASE
SERIES=$INPUT_SERIES
REVISION=$INPUT_REVISION
DEB_EMAIL=$INPUT_DEB_EMAIL
DEB_FULLNAME=$INPUT_DEB_FULLNAME
# Extra ppa separated by space
EXTRA_PPA=$INPUT_EXTRA_PPA

assert_non_empty() {
    name=$1
    value=$2
    if [[ -z "$value" ]]; then
        echo "::error::Invalid Value: $name is empty." >&2
        exit 1
    fi
}

assert_non_empty inputs.repository "$REPOSITORY"
assert_non_empty inputs.gpg_private_key "$GPG_PRIVATE_KEY"
assert_non_empty inputs.gpg_passphrase "$GPG_PASSPHRASE"
assert_non_empty inputs.deb_email "$DEB_EMAIL"
assert_non_empty inputs.deb_fullname "$DEB_FULLNAME"

export DEBEMAIL="$DEB_EMAIL"
export DEBFULLNAME="$DEB_FULLNAME"

if [[ -z "$REVISION" ]]; then
    REVISION=0
fi

echo "::group::Importing GPG private key..."
echo "Importing GPG private key..."

GPG_KEY_ID=$(echo "$GPG_PRIVATE_KEY" | gpg --import-options show-only --import | sed -n '2s/^\s*//p')
echo $GPG_KEY_ID
echo "$GPG_PRIVATE_KEY" | gpg --batch --passphrase "$GPG_PASSPHRASE" --import

echo "Checking GPG expirations..."
if [[ $(gpg --list-keys | grep expired) ]]; then
    echo "GPG key has expired. Please update your GPG key." >&2
    exit 1
fi

echo "::endgroup::"

echo "::group::Adding PPA..."
echo "Adding PPA: $REPOSITORY"
add-apt-repository -y ppa:$REPOSITORY
# Add extra PPA if it's been set
if [[ -n "$EXTRA_PPA" ]]; then
    for ppa in $EXTRA_PPA; do
        echo "Adding PPA: $ppa"
        add-apt-repository -y ppa:$ppa
    done
fi
apt-get update
echo "::endgroup::"

if [[ -z "$SERIES" ]]; then
    SERIES=$(distro-info --supported)
fi

# Add extra series if it's been set
if [[ -n "$INPUT_EXTRA_SERIES" ]]; then
    SERIES="$INPUT_EXTRA_SERIES $SERIES"
fi

for s in $SERIES; do
    ubuntu_version=$(distro-info --series $s -r | cut -d' ' -f1)

    echo "::group::Building deb for: $ubuntu_version ($s)"

    cp -r /github/workspace /tmp/$s && cd /tmp/$s

    # Extract the package name from the debian changelog
    package=$(dpkg-parsechangelog --show-field Source)
    pkg_version=$(dpkg-parsechangelog --show-field Version | cut -d- -f1)
    changes="New upstream release"

    # Create the debian changelog
    rm -rf debian/changelog
    dch --create --distribution $s --package $package --newversion $pkg_version-ppa$REVISION~ubuntu$ubuntu_version "$changes"

    debuild --no-tgz-check -S -sa \
        -k"$GPG_KEY_ID" \
        -p"gpg --batch --passphrase "$GPG_PASSPHRASE" --pinentry-mode loopback"

    dput ppa:$REPOSITORY ../*.changes

    echo "Uploaded $package to $REPOSITORY"

    echo "Cleaning up..."
    rm -rf /tmp/${package}_${pkg_version}-ppa${REVISION}~ubuntu${ubuntu_version}*

    echo "::endgroup::"
done
