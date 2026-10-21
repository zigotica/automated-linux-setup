# Automated Debian setup

Manage explicitly registered Debian machines over SSH with Ansible. Keep shared configuration in one place, select machine-specific settings through inventory variables, and preview changes before applying them.

Ansible runs from a macOS control machine. Managed machines need no Ansible agent or checkout of this repository. The examples use `blauet` and its primary user `zgtc`; substitute the inventory hostname and user of the machine you intend to manage.

## Configuration model

- `inventory.yml` explicitly registers managed machines and SSH users.
- `group_vars/debian.yml` defines safe server defaults, package groups, platform mappings, and archive checksums.
- `vars/app_versions.yml` centralizes the upstream app versions: the tracked Neovim series and the exact Figurine release. Both user-configuration and standalone Neovim recipes load it, including through the combined entry points.
- `host_vars/<hostname>.yml` selects the machine profile, optional features, and machine-specific values such as interfaces and DNS.
- `files/common/` contains shared shell, Git, and Neovim configuration.
- `files/desktop/` contains X11 startup, i3 configuration, and status widgets.
- `files/family/shell/` contains the separate family account's minimal shell and Xfce startup files.
- `files/family/xfce/` contains the family's managed Firefox ESR panel launcher.
- `files/opts/<feature>/` contains optional-feature configuration files when needed, currently touchpad settings.
- `vault/<hostname>-wifi.conf` stores encrypted saved Wi-Fi networks.
- `vault/network.yml` stores encrypted DNS servers and search domain shared by all hosts with DNS management enabled.
- `tasks/common/`, `tasks/desktop/`, `tasks/family/`, and `tasks/opts/<feature>/` contain the corresponding reusable task files; shared target safeguards and the user-deployment coordinator stay directly under `tasks/`.
- `playbooks/` contains recipes that can run independently.
- `all-dry-run.yml` and `all.yml` provide combined preview and apply entry points.

Folders describe purpose rather than the machine they were imported from. There is no host-named files directory, and no `server/` directory is needed until there are server-only files or tasks. Optional Wi-Fi and DNS logic lives under `tasks/opts/`; it needs no separate static files directory. Wi-Fi credentials stay encrypted under `vault/`.

`machine_profile` is either `server` (the default) or `desktop`. Both receive the common command-line package set, shared primary-user shell files, Neovim, and Figurine. The desktop profile additionally installs i3, Xfce core and its terminal, X11, audio/Bluetooth, browser, and related utilities. It deploys the primary user's declared i3 files and enables tty1 X11 startup in that user's login profile. Xfce does not replace i3. No display manager or large desktop application bundle is selected. Wi-Fi, touchpad, DNS management, and the family account remain explicit opt-ins.

Optional switches default to `false`: `manage_wifi`, `manage_touchpad`, `manage_dns`, `manage_git_work`, and `manage_family`. Use YAML booleans, not quoted strings. Touchpad and family management require the desktop profile; Wi-Fi, DNS, and private work Git configuration can be enabled independently on either profile. Disabling a feature skips management, without uninstalling packages, deleting existing files, or stopping services. The managed primary-user login profile is still rendered for the selected profile, so selecting `server` removes its automatic X11 startup block. Disabling family management does not remove its account, files, or authentication rules.

The example host `blauet` explicitly selects `desktop`, enables the three hardware/network switches, and enables the family account. Work Git management remains disabled by default. A new server needs an inventory entry with its SSH user and a host-variable file such as:

```yaml
primary_user: admin
system_hostname: example-server
machine_profile: server
```

No Wi-Fi vault, desktop manifest, or dhcpcd settings are required for that server. Shared Git settings, the static personal Git identity, and global ignores are deployed to both profiles. Work Git configuration is opt-in and sourced from a private file outside this repository.

## Requirements

On the control machine, install Ansible:

```bash
brew install ansible
```

SSH-key setup uses `ansible.posix.authorized_key`, included in the full Ansible distribution. The target needs SSH access, Python 3, an existing primary user, and sudo for privileged tasks.

Register each target deliberately. The inventory hostname should resolve through DNS; use an explicit `ansible_host` hostname mapping if the connection needs a fully qualified name. Local `/etc/hostname` and `/etc/hosts` settings on the target do not publish DNS records. Across VLANs, use unicast DNS rather than relying on `.local` mDNS.

For a first connection before DNS is ready, temporarily add `-e 'ansible_host=<bootstrap-ip>'` to the relevant command. Once hostname access works, omit the override. Host-key verification remains enabled; verify the server fingerprint before accepting a new key.

Keep private keys and unencrypted credentials outside the repository. Store the vault password separately, for example in a password manager.

## Initial SSH access

Connect once interactively and verify the server identity:

```bash
ssh zgtc@blauet
```

Authorize an existing control-machine public key, substituting its actual filename:

```bash
ansible-playbook playbooks/ssh-key.yml --limit blauet -e "ssh_public_key_file=$HOME/.ssh/id_ed25519.pub" --ask-pass --check --diff
ansible-playbook playbooks/ssh-key.yml --limit blauet -e "ssh_public_key_file=$HOME/.ssh/id_ed25519.pub" --ask-pass --diff
```

This recipe runs as the primary user without sudo, preserves existing authorized keys and password login, and does not change the control machine's SSH configuration. A passphrase-protected key may need to be loaded into the running SSH agent.

Verify key authentication using a fresh connection, then check Ansible:

```bash
ssh -o BatchMode=yes -o ControlPath=none zgtc@blauet true
ansible blauet -m ansible.builtin.ping
```

After key authentication works, Ansible commands do not need `--ask-pass`. For interactive access, use ordinary SSH with the target's user and hostname:

```bash
ssh zgtc@blauet
```

For another registered machine, substitute its user and hostname. Ansible reads connection settings from `inventory.yml`; there is no separate repository SSH configuration to maintain.

## Preview and apply

Run commands from the repository root and select exactly one registered machine.

Preview the combined configuration:

```bash
ansible-playbook all-dry-run.yml --limit blauet --check --diff --ask-become-pass --ask-vault-pass
```

Apply the same configuration:

```bash
ansible-playbook all.yml --limit blauet --diff --ask-become-pass --ask-vault-pass
```

The execution order is selected packages, shared/profile-specific primary-user configuration (including Neovim and Figurine), optional family account, optional touchpad, hostname and optional DNS, then optional Wi-Fi. `--ask-vault-pass` is needed when either `manage_wifi: true` or `manage_dns: true`: Wi-Fi uses the host's encrypted supplicant file, and DNS uses the shared encrypted `vault/network.yml`. For a server with both features disabled, omit `--ask-vault-pass` from both commands.

`all-dry-run.yml` requires `--check`. Each recipe enforces a literal single-host `--limit`; omitted limits, groups, wildcards, and multiple-host selections are rejected before configuration tasks. The sudo password authorizes privileged tasks; the vault password decrypts shared network settings and saved Wi-Fi configuration.

Re-run after applying to check idempotency. Investigate unexpected reported changes. Check mode cannot verify working Wi-Fi credentials, apply Xorg settings to a running session, or perform Figurine's first download and extraction. A successful preview is not a substitute for verifying the resulting behavior.

## Individual recipes

Run a recipe independently when only one configuration area is needed:

| Recipe | Purpose |
| --- | --- |
| `playbooks/site.yml` | Install the declared Debian package set |
| `playbooks/neovim.yml` | Install the newest stable patch in the configured Neovim series |
| `playbooks/user-config.yml` | Deploy shared/profile-specific user files, Neovim, and Figurine |
| `playbooks/family.yml` | Manage the optional passwordless local-console family account and Xfce startup |
| `playbooks/touchpad.yml` | Install X11 natural scrolling when `manage_touchpad` is enabled |
| `playbooks/network-identity.yml` | Manage hostname/local hosts mapping, then optional DNS |
| `playbooks/dns.yml` | Manage dhcpcd DNS only when `manage_dns` is enabled |
| `playbooks/wifi.yml` | Deploy saved networks and power-saving settings when `manage_wifi` is enabled |
| `playbooks/ssh-key.yml` | Authorize a selected public key |
| `playbooks/wifi-import.yml` | Import existing networks into a local encrypted vault |
| `playbooks/wifi-inspect.yml` | Display the current Wi-Fi structure with network values redacted |

For example:

```bash
ansible-playbook playbooks/site.yml --limit blauet --check --diff --ask-become-pass
ansible-playbook playbooks/user-config.yml --limit blauet --diff
```

User configuration and SSH-key authorization run without sudo. System recipes require `--ask-become-pass`; enabled DNS and Wi-Fi deployment also require `--ask-vault-pass`. Add `--check` to preview a configuration recipe. Initial Wi-Fi import does not support check mode.

## Packages and user files

The package recipe ensures `debian_packages` are present with `install_recommends: false`. It does not refresh the APT cache, request system-wide upgrades, or remove packages omitted from the list. The selected list combines `debian_common_packages`, `debian_desktop_packages` only for desktops, and `debian_wifi_packages` only when Wi-Fi management is enabled. The common list includes Git, fzf, ripgrep, less, lsof, hardware-inspection utilities, and wget; servers do not inherit graphical, audio/Bluetooth, or Wi-Fi packages by default.

Neovim is installed from checksum-verified official upstream archives by the user-configuration recipe or independently through `playbooks/neovim.yml`. It tracks the newest stable patch in `neovim_series: '0.12'` and installs into the fixed directory `~/.local/opt/neovim/current/`. The managed Bash profile adds its `bin` directory directly to PATH, without an alias or symlink. Updates replace this installation in place and leave Debian's packaged executable untouched.

The shared Neovim configuration lives in [files/common/neovim/](files/common/neovim/README.md). The user-configuration recipe deploys its entry point, plugin lockfile, and Lua modules into the primary user's `~/.config/nvim/` on each selected machine, for both desktop and server use. Documentation and tests stay in the repository. Deployment does not create backups or delete unrelated destination files. The standalone Neovim recipe installs only the runtime.

The example host's `hardware_packages` list records firmware and microcode requirements but is inactive. No task installs it or enables `non-free-firmware`.

Shared shell files come from `files/common/shell/`; `bash_profile.j2` renders profile-specific X11 startup while retaining the shared PATH and editor settings. Git settings, the static `.gitconfig-personal`, and global ignores come from `files/common/git/`. Shared Neovim files come from `files/common/neovim/`. Figurine has installation tasks under `tasks/common/figurine.yml`, but no separate configuration files beyond its shared shell greeting. Destinations use `primary_user`'s account home directory.

Desktop files use the shared `desktop_config_files` manifest in `group_vars/debian.yml`. Each entry selects a source relative to `files/desktop/`, destination-relative `path`, mode, and optional validator. Sources ending in `.j2` are rendered as templates; other sources are copied. The manifest includes `.xinitrc`, i3 configuration, the status coordinator, and six widgets, and is deployed only for the desktop profile. Host-specific file directories and source manifests are no longer needed. Bash and Git syntax checks and `i3 -C` run before actual replacements; check mode alone does not establish that all validators have run.

The supplied Bash configuration loads aliases and functions in an explicit order and uses a colored prompt with an SSH indicator. It displays a random-font Figurine greeting when the executable is available. Figurine is installed for both profiles. The login profile sets executable paths and Neovim editor variables; tty1 automatic X11 startup is rendered only for the desktop profile.

The supplied i3 status coordinator sources widget functions once and refreshes every two seconds. An array controls widget order, and CPU sample state stays in the coordinator shell. The Wi-Fi widget is rendered with the selected host's `wifi_interface`; without a configured interface it reports DOWN.

### Per-host i3 function keys

Each desktop host must define `i3_fn_keys` in its host variables. Numbers are rendered as F1 through F12 in the i3 configuration; all eight assignments must be distinct integers. `blauet` uses:

```yaml
i3_fn_keys:
  brightness_down: 2
  brightness_up: 3
  volume_mute: 6
  volume_down: 7
  volume_up: 8
  media_previous: 9
  media_play_pause: 10
  media_next: 11
```

Other laptops can assign different numbers without changing the shared i3 template. These are ordinary F-key bindings, preserving the existing setup; the laptop's Fn-lock setting determines how its physical keys generate those events. The media bindings use `playerctl previous`, `playerctl play-pause`, and `playerctl next` for [MPRIS-enabled players](https://manpages.debian.org/trixie/playerctl/playerctl.1.en.html). The package is installed only for desktops, and no player daemon is started. These settings apply to the primary user's i3 session, not the separate family Xfce session. Deploy packages before the user configuration to install the new dependency, then reload i3 with Mod+Shift+c. Deployment validates the rendered configuration with `i3 -C` but does not reload the session automatically.

## Family Xfce account

With `machine_profile: desktop` and `manage_family: true`, the family recipe creates the unprivileged account `family` with home `/home/family`, Bash, a locked password, its own primary group, and no supplementary groups. It does not deploy primary-user shell files, Git settings, Neovim configuration, or the Figurine greeting. Installed desktop applications remain system-wide and are available to either user.

The account has passwordless local-console login, not an empty reusable password and not autologin. A service-specific rule in `/etc/pam.d/login` permits only `family` on tty1 through tty6 (including `/dev/`-prefixed forms) to pass authentication without a password. The common authentication stack is not modified. Normal account/session checks still apply. A required account rule at the beginning of `/etc/pam.d/sshd` denies this user through SSH, including key authentication; the recipe requires SSH's `UsePAM yes`. Other usernames retain normal authentication. PAM files are read for new sessions, so no daemon restart or reload is requested. See [Linux-PAM conditions](https://sources.debian.org/src/pam/1.7.0-5/modules/pam_succeed_if/pam_succeed_if.8.xml) and [PAM control semantics](https://manpages.debian.org/trixie/libpam-runtime/pam.conf.5.en.html).

Anyone with access to the permitted local consoles can enter this account and use its files and browser sessions. This is deliberately unsuitable for protecting private family data or a password-protected lock screen. The recipe removes supplementary group memberships from an existing `family` account; this includes sudo membership. It refuses an unexpected system UID, different home path, or symlinked home.

The separate files under `files/family/shell/` start Xfce after an interactive local text-console login. The user types `family` at the login prompt; there is no password prompt. Remote and already-graphical shells do not start X11. The primary user continues to start i3 as before. The [Debian Xfce core metapackage](https://packages.debian.org/trixie/xfce4) and `xfce4-terminal` are selected with APT recommendations disabled; no graphical login manager is added by these package selections.

The family recipe also replaces generic browser launchers in the Xfce panel with Firefox ESR, using `files/family/xfce/firefox-esr.desktop`. Existing launcher filenames, panel positions, and unrelated items are preserved. When no panel layout exists, it seeds Debian's installed default layout without overwriting an existing one, then changes only the generic browser application references. This changes the panel launcher, not system-wide browser preferences. [Xfce launchers use desktop files](https://docs.xfce.org/xfce/xfce4-panel/launcher).

Log `family` out of Xfce before applying the family recipe: it refuses panel writes while that user's `xfconfd` is running, to avoid conflicting with in-memory settings. A dry run remains allowed while the session is running. No desktop process is stopped or restarted. Log back in afterward to verify the Firefox icon and that it launches Firefox ESR. First-time panel initialization is skipped in check mode when there is no panel XML yet.

Install packages before running the family recipe independently:

```bash
ansible-playbook playbooks/site.yml --limit blauet --check --diff --ask-become-pass
ansible-playbook playbooks/family.yml --limit blauet --check --diff --ask-become-pass
```

After reviewing the previews, apply those recipes in the same order without `--check`. Keep a working administrator SSH session open. Check mode cannot exercise PAM authentication or a graphical session, and it skips copying startup files when the family home does not yet exist. Preflight checks inspect existing PAM services and SSH settings before making changes, and reject layouts outside the reviewed assumptions.

The refactored setup has been deployed to `blauet`. The user confirmed passwordless local-console login as `family`, Xfce startup, and the managed Firefox ESR launcher working. Fresh administrator SSH access, refusal of `family` SSH access, logout behavior, and `id family` showing no supplementary groups have not yet been explicitly confirmed. Keep a working administrator session open until fresh SSH access is verified. Use sequential graphical sessions for initial testing, logging out of i3 before entering Xfce. Offline checks do not establish authentication or graphical-session acceptance.

## Private work Git configuration

Work Git configuration is not stored in this repository. To enable it for a selected host, supply `manage_git_work: true` and an absolute `git_work_config_file` path through a private variables file on the control machine, also outside the repository. For example, a private variables file could contain:

```yaml
manage_git_work: true
git_work_config_file: /absolute/private/path/work.gitconfig
```

The referenced file is an ordinary Git configuration containing your work settings. Pass the private variables file when deploying the selected machine:

```bash
ansible-playbook playbooks/user-config.yml --limit blauet --diff -e @/absolute/private/path/blauet.yml
```

The task verifies that the source is a regular file outside the repository, including after resolving symlinks. It validates Git syntax and copies the file to the target user's `~/.gitconfig-work` with mode `0600`, no backups, and no contents in task output or diffs. With management disabled, no work source is read and any existing target file remains untouched. Protect the local source and private variables file with appropriate permissions and never add them to the repository.

The shared `.gitconfig` already conditionally includes `~/.gitconfig-work` for repositories under `~/Documents/work/`. Repositories elsewhere retain the personal defaults.

## Figurine

For both desktop and server profiles, the user recipe downloads a prebuilt Figurine release for the target's detected OS and architecture. The version is pinned in `vars/app_versions.yml`; platform mappings and archive SHA-256 values remain in `group_vars/debian.yml`. When changing the Figurine version, update its matching archive checksums too. Supported targets are currently Linux AMD64 and ARM64. Debian package versions remain managed by APT; Neovim plugin revisions stay with its configuration and lockfile.

Archives are verified, cached, and extracted under the primary user's `~/.cache/figurine/`. The executable is installed into `~/.config/bin/figurine`. No compilation or binary stored in the repository is needed. Initial installation requires target network access.

Check mode skips downloading and extraction. It can preview copying a previously extracted executable, or report that the first installation needs a real run. The pinned release is [Figurine v2.1.1](https://github.com/arsham/figurine/releases/tag/v2.1.1).

## Hostname and DNS

Host variables define `system_hostname`. The network-identity recipe always manages the active and persistent hostname and the `127.0.1.1` mapping in `/etc/hosts`, independently of DNS or Wi-Fi. With `manage_dns: true`, its separate DNS recipe loads `dns_servers` and `dns_search_domain` from the shared encrypted `vault/network.yml` and manages an interface-specific block in `/etc/dhcpcd.conf`. Each host defines only its own `dns_interface`, which can be wired or wireless and is not inferred from `wifi_interface`.

Only the optional DNS recipe requires the reviewed dhcpcd setup. With DNS management disabled, the network vault is not loaded and no dhcpcd file is inspected or modified. Dhcpcd continues generating `/etc/resolv.conf`; the recipe does not replace that generated file, restart networking, or renew DHCP. Persistent DNS changes apply when dhcpcd next reads its configuration.

All DNS-managed hosts reuse the same vaulted network settings. Keep the real DNS addresses and domain out of plaintext configuration and documentation. Edit them with `EDITOR=nvim ansible-vault edit vault/network.yml`, using the existing vault password. The source must be encrypted; DNS loading, value validation, and configuration changes do not expose values in task output or diffs. Pinning a DNS server requires it to remain reachable on the networks used.

The recipe configures a DNS client, not a Pi-hole server or DNS records. Control-machine hostname resolution must already be provided by the network.

## Touchpad

With `machine_profile: desktop` and `manage_touchpad: true`, the recipe installs the shared `files/opts/touchpad/30-touchpad.conf` as `/etc/X11/xorg.conf.d/30-touchpad.conf`, owned by root with mode `0644`. `touchpad_config_source` can override that source path relative to `files/` if a different configuration is needed. Otherwise the recipe exits before inspecting the source or creating X11 directories.

The example enables natural scrolling by matching touchpads rather than temporary XInput device IDs. It takes effect at the next X11 session start; reloading i3 alone does not apply Xorg input settings.

## Saved Wi-Fi networks

Wi-Fi deployment runs only with `manage_wifi: true`; otherwise it exits before checking the vault or inspecting network files. The explicit import/inspection recipes remain available independently. Wi-Fi recipes currently support the reviewed ifupdown/wpa_supplicant layout: DHCP on `wifi_interface`, a `wpa-conf` reference to `/etc/wpa_supplicant/wpa_supplicant-<interface>.conf`, and a persistent power-saving command. They do not provision an arbitrary network stack from scratch.

For initial import, read the existing target configuration directly into an encrypted local vault:

```bash
ansible-playbook playbooks/wifi-import.yml --limit blauet --ask-become-pass
```

Import prompts for a new vault password and confirmation, reads the protected file into memory, and saves only ciphertext to `vault/<inventory-hostname>-wifi.conf`. It preserves SSIDs, passwords, and priorities, refuses to overwrite an existing vault, and does not change the target.

Edit saved networks through Ansible Vault:

```bash
ansible-vault edit vault/blauet-wifi.conf
```

The vault holds the complete supplicant configuration and is the source of truth for the deployed saved-network list. Preserve control-interface settings and network blocks you still need. Vault editing and deployment use temporary decrypted files; configure the editor to avoid secret-containing swap or backup files.

Inspect the target structure with network values redacted:

```bash
ansible-playbook playbooks/wifi-inspect.yml --limit blauet --ask-become-pass
```

Deploy with:

```bash
ansible-playbook playbooks/wifi.yml --limit blauet --ask-become-pass --ask-vault-pass
```

Deployment writes the supplicant file as root with mode `0600` and hides sensitive task output and diffs. `wifi_power_save` controls the existing persistent `post-up` setting while preserving the surrounding interfaces configuration. Networking is not restarted and the active network is not switched.

## Operational boundaries

No recipe creates backup copies. Existing backups are left untouched. Recovery of managed source configuration belongs in repository history; keep encrypted vault revisions if needed.

Only the opt-in family recipe creates or changes a user account and its console/SSH PAM rules; existing primary users must already exist. The recipes do not rewrite APT sources, automatically remove packages, request system-wide upgrades, reboot, or restart networking, SSH, or X11. Open a new terminal for shell changes and use a deliberate new session or reload for desktop changes as appropriate.

Register new hosts explicitly, review their profile, optional switches, variables, and files, and use the single-host limit for each run. A profile change is not a cleanup recipe: previously installed desktop packages and files remain unless removed separately with explicit approval.

## Local checks

Inspect inventory and validate entry points without contacting targets:

```bash
ansible-inventory --graph
ansible-inventory --host blauet
ansible-playbook all.yml --syntax-check
ansible-playbook all-dry-run.yml --syntax-check
ansible-playbook all.yml --limit blauet --list-tasks
```

Offline package-selection, template-rendering, manifest, and feature-gate checks use Ansible's existing Python environment, without contacting hosts or starting an Ansible execution process. On the macOS control machine:

```bash
"$(brew --prefix ansible)/libexec/bin/python" tests/check_profiles.py
```

The desktop/server split has passed offline checks and full dry runs on `blauet`, and the refactored desktop setup has been deployed there. The user confirmed a successful full apply whose only change was updated Neovim Lua configuration, as well as family console login, Xfce startup, and the Firefox ESR launcher. Neovim 0.12.6 was installed through its standalone recipe and reran with `changed=0`; the user confirmed its menu and fzf work. Other editor behavior and the remaining access checks listed above have not been explicitly confirmed. The shared network-vault migration passes offline checks and the user-confirmed full target dry run: `ok=90`, `changed=0`, `unreachable=0`, `failed=0`, and `skipped=13`. This confirms idempotency in check mode; it is not additional live verification of authentication, networking, or editor behavior. The server profile has offline coverage but has not been deployed to a real server. Static `--list-tasks` output includes disabled feature tasks; their early-exit conditions are evaluated only during execution.
