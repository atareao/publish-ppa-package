# Publish PPA Package

GitHub action to publish the Ubuntu PPA (Personal Package Archives) packages.

## Inputs

### `repository`
**Required** The PPA repository, e.g. `atareao/atareao`.

### `gpg_private_key`
**Required** GPG private key exported as an ASCII armored version or its base64 encoding, exported with the following command.

```sh
gpg --output private.pgp --armor --export-secret-key <KEY_ID or EMAIL>
```

### `gpg_passphrase`
**Optional** Passphrase of the GPG private key.

### `src_dir`
Required The source directory, default to `src`.

### `deb_email`
**Required** The email address of the maintainer.

### `deb_fullname`
**Required** The full name of the maintainer.

### `debian_dir`
**Optional** The debian directory, default to `debian`.

### `series`
**Optional** The series to which the package will be published, separated by space. e.g., `"bionic focal"`.

Default to the series that are supported at the moment, i.e., the output of `distro-info --supported`.

### `extra_series`
**Optional** The extra series to which the package will be published, separated by space. e.g., `"bionic focal"`.

### `revision`
**Optional** The revision of the package, default to `1`.

### `extra_ppa`
**Optional** The extra PPA this package depends on, separated by space. e.g., `"liushuyu-011/rust-bpo-1.75"`.

## Example usage

```yaml
name: Publish PPA
uses: atareao/publish-ppa-package@v2
with:
    repository: "yuezk/globalprotect-openconnect"
    gpg_private_key: ${{ secrets.PPA_GPG_PRIVATE_KEY }}
    deb_email: "<email>"
    deb_fullname: "<full name>"
```

## Real-world applications

- [GlobalProtect-openconnect](https://github.com/yuezk/GlobalProtect-openconnect): A GlobalProtect VPN client for Linux, written in Rust, based on OpenConnect and Tauri, supports SSO with MFA, Yubikey, etc.

## LICENSE

[MIT](./LICENSE)
