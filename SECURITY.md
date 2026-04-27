# Security Policy

## Reporting vulnerabilities

If you discover a security vulnerability in SpartaNode, please report
it responsibly:

- Email: **security@spartanode.com**
- Do NOT open a public GitHub issue for security vulnerabilities.

We will acknowledge receipt within 48 hours and aim to provide a fix
or mitigation within 7 days for critical issues.

## Signing policy

Every release is published with:

1. **SHA256SUMS.txt** — SHA-256 checksums for all artifacts.
2. **SHA256SUMS.txt.asc** — detached GPG signature of the checksums
   file.

The install scripts (`install.sh`, `install.ps1`) verify both the GPG
signature and the SHA-256 checksum before extracting any files.

## GPG key

- **Public key**: [`keys/spartanode-releases.asc`](keys/spartanode-releases.asc)
- **Email**: `releases@spartanode.com`
- **Fingerprint**: `(to be published after key generation)`

The fingerprint is also pinned in the install scripts. If the
downloaded key's fingerprint does not match the pinned value, the
install script aborts.

To import and verify manually:

```bash
curl -fsSL https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/keys/spartanode-releases.asc | gpg --import
gpg --verify SHA256SUMS.txt.asc SHA256SUMS.txt
```

## Key rotation

If the signing key is compromised or rotated:

1. A new key will be generated and published at
   `keys/spartanode-releases.asc`.
2. The old key will be moved to `keys/spartanode-releases-revoked.asc`
   with a revocation certificate.
3. A signed announcement will be posted using the OLD key before
   rotation, confirming the new key's fingerprint.
4. The install scripts will be updated with the new fingerprint.
5. All future releases will be signed with the new key.

## Code signing (platform-specific)

| Platform | Status |
|---|---|
| **Windows** | Unsigned (v1 enterprise). EV Authenticode cert planned for consumer release. |
| **macOS** | Apple Developer ID + notarization (Phase E3). |
| **Linux** | GPG-signed checksums (no OS-level signing required). |

## Supported versions

Only the latest release receives security updates. We recommend
keeping SpartaNode up to date via the install scripts or the built-in
updater.
