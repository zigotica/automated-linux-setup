# Encrypted configuration

`network.yml` contains shared DNS settings as encrypted YAML: `dns_servers` (a list of IP addresses) and `dns_search_domain` (a domain name). The DNS recipe loads it only for hosts with `manage_dns: true`; each host keeps its own `dns_interface`. Edit with `EDITOR=nvim ansible-vault edit vault/network.yml`. Keep all real network values inside the encrypted file, not in host variables or documentation. DNS task output and diffs are suppressed.

`bluetooth.yml` contains the shared desktop Bluetooth device names and hardware addresses under `audio_devices`. The Bluetooth recipe loads it only for desktop profiles and suppresses the included values from task output and diffs. Create or edit it with `EDITOR=nvim ansible-vault create vault/bluetooth.yml` or `EDITOR=nvim ansible-vault edit vault/bluetooth.yml`; replace documentation placeholders with the real value inside the editor, and never store a plaintext copy or its hardware addresses elsewhere in the repository.

## Wi-Fi networks

`playbooks/wifi-import.yml` creates the shared `wifi.conf` here as an encrypted Ansible Vault file. A dedicated existing wpa_supplicant file is preserved completely. Debian-installer inline `wpa-ssid` and `wpa-psk` directives are converted in memory into a standard single-network supplicant configuration before encryption. The decrypted content includes SSIDs and passwords. Every managed Debian host with Wi-Fi enabled deploys this same source. Never place a plaintext copy or vault password file in this directory.

Edit the encrypted file with `ansible-vault edit vault/wifi.conf`. This invokes your editor on a temporary decrypted file, so use a trusted local editor and avoid editor backup or swap files for secrets.
