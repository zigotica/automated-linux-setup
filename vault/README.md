# Encrypted configuration

`network.yml` contains shared DNS settings as encrypted YAML: `dns_servers` (a list of IP addresses) and `dns_search_domain` (a domain name). The DNS recipe loads it only for hosts with `manage_dns: true`; each host keeps its own `dns_interface`. Edit with `EDITOR=nvim ansible-vault edit vault/network.yml`. Keep all real network values inside the encrypted file, not in host variables or documentation. DNS task output and diffs are suppressed.

## Wi-Fi networks

`playbooks/wifi-import.yml` creates `<inventory-hostname>-wifi.conf` here as an encrypted Ansible Vault file. The decrypted content is the complete existing wpa_supplicant configuration, including SSIDs, passwords, and priorities. Never place a plaintext copy or vault password file in this directory.

Edit the encrypted file with `ansible-vault edit vault/blauet-wifi.conf`. This invokes your editor on a temporary decrypted file, so use a trusted local editor and avoid editor backup or swap files for secrets.
