"""Offline profile checks. Use the Python environment that provides Ansible."""

import ast
import configparser
import re
from pathlib import Path
import subprocess
import unittest

from jinja2 import Environment, StrictUndefined
import yaml
import shlex
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
ENV = Environment(undefined=StrictUndefined)
ENV.filters["quote"] = shlex.quote


def load(path):
  return yaml.safe_load((ROOT / path).read_text())


class Profiles(unittest.TestCase):
  def setUp(self):
    self.defaults = load("group_vars/debian.yml")
    self.desktop = self.defaults | load("host_vars/blauet.yml")

  def packages(self, variables):
    return ast.literal_eval(ENV.from_string(variables["debian_packages"]).render(variables))

  def test_app_versions_have_one_shared_source(self):
    versions = load("vars/app_versions.yml")
    self.assertRegex(versions["neovim_series"], r"^\d+\.\d+$")
    self.assertRegex(versions["figurine_version"], r"^\d+\.\d+\.\d+$")
    for key in versions:
      self.assertNotIn(key, self.defaults)
    for recipe in ("user-config", "neovim"):
      play = load(f"playbooks/{recipe}.yml")[0]
      self.assertIn("../vars/app_versions.yml", play["vars_files"])

  def test_server_defaults(self):
    self.assertEqual(self.defaults["machine_profile"], "server")
    for switch in ("manage_wifi", "manage_touchpad", "manage_dns", "manage_git_work", "manage_family"):
      self.assertIs(self.defaults[switch], False)
    self.assertEqual(self.packages(self.defaults), self.defaults["debian_common_packages"])
    self.assertNotIn("git_user_name", self.defaults)
    self.assertNotIn("git_user_email", self.defaults)

  def test_desktop_preserves_all_groups(self):
    expected = set(self.defaults["debian_common_packages"]
                   + self.defaults["debian_desktop_packages"]
                   + self.defaults["debian_wifi_packages"])
    self.assertEqual(set(self.packages(self.desktop)), expected)
    for switch in ("manage_wifi", "manage_touchpad", "manage_dns"):
      self.assertIs(self.desktop[switch], True)
    self.assertEqual(self.desktop["dns_interface"], self.desktop["wifi_interface"])
    self.assertIn("xfce4", self.packages(self.desktop))
    self.assertIn("i3-wm", self.packages(self.desktop))
    self.assertNotIn("task-xfce-desktop", self.packages(self.desktop))
    self.assertTrue(self.desktop["manage_family"])

  def test_family_account_is_separate_and_opt_in(self):
    play = load("playbooks/family.yml")[0]
    self.assertIs(play["become"], True)
    self.assertEqual(play["tasks"][0]["when"], "manage_family")
    tasks = load("tasks/family/main.yml")
    user = next(task["ansible.builtin.user"] for task in tasks if "ansible.builtin.user" in task)
    self.assertEqual(user["name"], "family")
    self.assertEqual(user["home"], "/home/family")
    self.assertEqual(user["password"], "!")
    self.assertEqual(user["groups"], "")
    self.assertIs(user["append"], False)
    copy = next(task for task in tasks if "ansible.builtin.copy" in task)
    self.assertEqual(set(copy["loop"]), {".bash_profile", ".bashrc", ".xinitrc"})
    self.assertIn("/files/family/shell/", copy["ansible.builtin.copy"]["src"])
    self.assertNotIn("common/", str(tasks))
    self.assertIn("/home/family/", copy["ansible.builtin.copy"]["dest"])
    for file in (ROOT / "files/family/shell").iterdir():
      subprocess.run(["bash", "-n", str(file)], check=True)
      for excluded in ("figurine", "neovim", "exec i3", ".bash_aliases", ".bash_functions"):
        self.assertNotIn(excluded, file.read_text())
    profile = (ROOT / "files/family/shell/.bash_profile").read_text()
    self.assertIn("SSH_CONNECTION", profile)
    self.assertIn("DISPLAY", profile)
    self.assertIn("/dev/tty[1-6]", profile)
    self.assertIn("exec startxfce4", (ROOT / "files/family/shell/.xinitrc").read_text())
    for entry in ("all.yml", "all-dry-run.yml"):
      self.assertTrue(any(play.get("ansible.builtin.import_playbook") == "playbooks/family.yml" for play in load(entry)))

  def test_family_authentication_is_console_specific(self):
    tasks = load("tasks/family/main.yml")
    rules = [task["ansible.builtin.lineinfile"] for task in tasks if "ansible.builtin.lineinfile" in task]
    self.assertEqual({rule["path"] for rule in rules}, {"/etc/pam.d/login", "/etc/pam.d/sshd"})
    console = next(rule for rule in rules if rule["path"].endswith("/login") and "line" in rule)
    self.assertTrue(console["line"].startswith("auth sufficient pam_succeed_if.so user = family "))
    self.assertEqual(console["insertbefore"], r"^@include\s+common-auth\s*$")
    words = console["line"].split()
    terminals = words[words.index("in") + 1].split(":")
    self.assertEqual(set(terminals),
                     {f"{prefix}tty{number}" for prefix in ("", "/dev/") for number in range(1, 7)})
    ssh = next(rule for rule in rules if rule["path"].endswith("/sshd"))
    self.assertEqual(ssh["line"], "account required pam_succeed_if.so user != family quiet")
    self.assertEqual(ssh["insertbefore"], "BOF")
    for rule in rules:
      self.assertIs(rule["backup"], False)
      self.assertIs(rule["create"], False)
    for task in tasks:
      self.assertNotIn("ansible.builtin.service", task)
      self.assertNotIn("ansible.builtin.systemd_service", task)

  def test_family_browser_changes_preserve_unrelated_panel_items(self):
    tasks = load("tasks/family/panel.yml")
    guard = tasks[1]["ansible.builtin.assert"]
    self.assertIn("ansible_check_mode or family_panel_daemon.rc | default(1) != 0", guard["that"])
    block = next(task["block"] for task in tasks if "block" in task)
    seed = next(task["ansible.builtin.copy"] for task in block if task.get("ansible.builtin.copy", {}).get("remote_src"))
    self.assertIs(seed["force"], False)
    self.assertIs(seed["backup"], False)
    change = next(task["ansible.builtin.replace"] for task in block if "ansible.builtin.replace" in task)
    fixture = '<channel><value value="xfce4-web-browser.desktop"/><value value="exo-web-browser.desktop"/><value value="xfce4-terminal.desktop"/><property name="size" value="32"/></channel>'
    changed = re.sub(change["regexp"], change["replace"], fixture)
    expected = fixture.replace("xfce4-web-browser.desktop", "firefox-esr.desktop").replace("exo-web-browser.desktop", "firefox-esr.desktop")
    self.assertEqual(changed, expected)
    self.assertEqual(re.sub(change["regexp"], change["replace"], changed), changed)
    find = next(task["ansible.builtin.find"] for task in block if "ansible.builtin.find" in task)
    for content, matches in (("[Desktop Entry]\nExec=exo-open --launch WebBrowser %u\n", True),
                             ("Exec=xfce4-open --launch WebBrowser\n", True),
                             ("Exec=exo-open --launch TerminalEmulator\n", False),
                             ("Exec=chromium %u\n", False)):
      self.assertEqual(bool(re.search(find["contains"], content)), matches)
    launcher = (ROOT / "files/family/xfce/firefox-esr.desktop").read_text()
    self.assertTrue(re.search(find["contains"], launcher))
    desktop = configparser.ConfigParser(interpolation=None)
    desktop.read_string(launcher)
    self.assertEqual(desktop["Desktop Entry"]["Exec"], "firefox-esr %u")
    self.assertEqual(desktop["Desktop Entry"]["Icon"], "firefox-esr")
    replacement = block[-1]["ansible.builtin.copy"]
    self.assertEqual(replacement["dest"], "{{ item.path }}")
    self.assertIs(replacement["backup"], False)
    self.assertFalse(any("ansible.builtin.service" in task or "ansible.builtin.systemd_service" in task for task in tasks + block))

  def test_legacy_family_rule_is_removed_before_console_rule(self):
    tasks = load("tasks/family/main.yml")
    removal_index = next(index for index, task in enumerate(tasks)
                         if task.get("ansible.builtin.lineinfile", {}).get("state") == "absent")
    removal = tasks[removal_index]["ansible.builtin.lineinfile"]
    console_index = next(index for index, task in enumerate(tasks)
                         if task.get("ansible.builtin.lineinfile", {}).get("line", "").startswith("auth sufficient"))
    self.assertLess(removal_index, console_index)
    self.assertEqual(removal["path"], "/etc/pam.d/login")
    self.assertIs(removal["backup"], False)
    legacy = "auth [success=done default=ignore] pam_succeed_if.so user = family"
    unrelated = ["# " + legacy,
                 "auth [success=done default=ignore] pam_succeed_if.so user = another",
                 "@include common-auth",
                 tasks[console_index]["ansible.builtin.lineinfile"]["line"]]
    fixture = [legacy, *unrelated, legacy]
    filtered = [line for line in fixture if not re.search(removal["regexp"], line)]
    self.assertEqual(filtered, unrelated)
    self.assertEqual([line for line in filtered if not re.search(removal["regexp"], line)], filtered)

  def test_wifi_is_independent_of_desktop(self):
    server_wifi = self.defaults | {"manage_wifi": True}
    self.assertEqual(set(self.packages(server_wifi)),
                     set(self.defaults["debian_common_packages"] + self.defaults["debian_wifi_packages"]))
    desktop_wired = self.desktop | {"manage_wifi": False}
    self.assertFalse(set(self.packages(desktop_wired)) & set(self.defaults["debian_wifi_packages"]))

  def test_wifi_uses_one_shared_encrypted_source(self):
    shared = ROOT / "vault/wifi.conf"
    self.assertTrue(shared.read_bytes().startswith(b"$ANSIBLE_VAULT;"))
    for task_file in ("tasks/opts/wifi/import.yml", "tasks/opts/wifi/main.yml"):
      content = (ROOT / task_file).read_text()
      self.assertIn("vault/wifi.conf", content)
      self.assertNotIn("inventory_hostname }}-wifi.conf", content)
    self.assertFalse(list((ROOT / "vault").glob("*-wifi.conf")))

  def test_wifi_inspection_redacts_inline_installer_credentials(self):
    tasks = load("tasks/opts/wifi/inspect.yml")
    command = next(task for task in tasks if "ansible.builtin.command" in task)
    script = command["ansible.builtin.command"]["argv"][2]
    with tempfile.TemporaryDirectory() as directory:
      interfaces = Path(directory) / "interfaces"
      interfaces.write_text("""auto lo
iface lo inet loopback
allow-hotplug wlo1
iface wlo1 inet dhcp
  wpa-ssid PrivateNetwork
  wpa-psk secret-password
""")
      result = subprocess.run([sys.executable, "-c", script, str(interfaces), "interfaces", "wlo1"],
                              capture_output=True, text=True, check=True)
    self.assertEqual(result.stdout.splitlines(),
                     ["iface wlo1 inet dhcp", "wpa-ssid [redacted]", "wpa-psk [redacted]"])
    self.assertNotIn("PrivateNetwork", result.stdout)
    self.assertNotIn("secret-password", result.stdout)
    self.assertIs(command["no_log"], True)

  def test_wifi_deployment_migrates_only_selected_inline_stanza(self):
    tasks = load("tasks/opts/wifi/main.yml")
    command = next(task for task in tasks if task["name"] == "Replace inline credentials with the managed supplicant reference")
    script = command["ansible.builtin.command"]["argv"][2]
    with tempfile.TemporaryDirectory() as directory:
      interfaces = Path(directory) / "interfaces"
      interfaces.write_text("""auto lo
iface lo inet loopback
allow-hotplug wlo1
iface wlo1 inet dhcp
  wpa-ssid PrivateNetwork
  wpa-psk secret-password
allow-hotplug wlan1
iface wlan1 inet dhcp
  wpa-ssid PreserveThis
  wpa-psk preserve-this-secret
""")
      first = subprocess.run([sys.executable, "-c", script, "wlo1", str(interfaces)],
                             capture_output=True, text=True, check=True)
      migrated = interfaces.read_text()
      second = subprocess.run([sys.executable, "-c", script, "wlo1", str(interfaces)],
                              capture_output=True, text=True, check=True)
    self.assertEqual(first.stdout.strip(), "changed")
    self.assertEqual(second.stdout.strip(), "unchanged")
    self.assertIn("wpa-conf /etc/wpa_supplicant/wpa_supplicant-wlo1.conf", migrated)
    self.assertNotIn("PrivateNetwork", migrated)
    self.assertNotIn("secret-password", migrated)
    self.assertIn("PreserveThis", migrated)
    self.assertIn("preserve-this-secret", migrated)
    self.assertIs(command["no_log"], True)

  def test_rendered_login_profiles(self):
    template = ENV.from_string((ROOT / "files/common/shell/bash_profile.j2").read_text())
    for variables in (self.defaults, self.desktop):
      with self.subTest(profile=variables["machine_profile"]):
        rendered = template.render(variables)
        self.assertEqual("exec startx" in rendered, variables["machine_profile"] == "desktop")
        self.assertIn(".local/opt/neovim/current/bin", rendered)
        subprocess.run(["bash", "-n"], input=rendered, text=True, check=True)

  def test_desktop_xinit_applies_only_declared_keyboard_layout(self):
    template = ENV.from_string((ROOT / "files/desktop/xinitrc.j2").read_text())
    spanish = template.render(keyboard_layout="es")
    inherited = template.render()
    self.assertIn("setxkbmap es", spanish)
    self.assertNotIn("setxkbmap", inherited)
    for rendered in (spanish, inherited):
      self.assertIn("exec i3", rendered)
      subprocess.run(["bash", "-n"], input=rendered, text=True, check=True)

  def test_example_manifest_sources(self):
    for entry in self.desktop["desktop_config_files"]:
      self.assertTrue((ROOT / "files/desktop" / entry["src"]).is_file())
    self.assertEqual(len(self.desktop["desktop_config_files"]), 9)
    self.assertTrue((ROOT / "files" / self.defaults["touchpad_config_source"]).is_file())
    self.assertFalse((ROOT / "files/blauet").exists())

  def test_i3_function_keys_render_per_host(self):
    template = ENV.from_string((ROOT / "files/desktop/i3/config.j2").read_text())
    expected = {
      "brightness_down": "brightnessctl set 5%-",
      "brightness_up": "brightnessctl set 5%+",
      "volume_mute": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
      "volume_down": "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-",
      "volume_up": "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+",
      "media_previous": "playerctl previous",
      "media_play_pause": "playerctl play-pause",
      "media_next": "playerctl next",
    }
    for keys in (self.desktop["i3_fn_keys"], dict(zip(expected, range(1, 9)))):
      with self.subTest(keys=keys):
        rendered = template.render(i3_fn_keys=keys)
        bindings = [line for line in rendered.splitlines() if re.match(r"^bindsym F\d+ ", line)]
        self.assertEqual(len(bindings), 8)
        for action, command in expected.items():
          self.assertIn(f"bindsym F{keys[action]} exec --no-startup-id {command}", bindings)
    self.assertEqual(self.desktop["i3_fn_keys"]["media_previous"], 9)
    self.assertEqual(self.desktop["i3_fn_keys"]["media_play_pause"], 10)
    self.assertEqual(self.desktop["i3_fn_keys"]["media_next"], 11)
    self.assertIn("playerctl", self.packages(self.desktop))
    self.assertNotIn("playerctl", self.packages(self.defaults))
    entry = next(item for item in self.desktop["desktop_config_files"] if item["path"] == ".config/i3/config")
    self.assertEqual(entry["src"], "i3/config.j2")
    self.assertEqual(entry["validate"], "/usr/bin/i3 -C -c %s")

  def test_i3_function_key_validation_rejects_invalid_assignments(self):
    validation = load("tasks/desktop/main.yml")[1]
    actions = validation["vars"]["required_i3_fn_actions"]
    checks = validation["ansible.builtin.assert"]["that"]

    def valid(keys):
      return all(ENV.compile_expression(check)(i3_fn_keys=keys, required_i3_fn_actions=actions) for check in checks)

    original = self.desktop["i3_fn_keys"]
    self.assertTrue(valid(original))
    for invalid in (original | {"media_next": 9}, original | {"media_next": 0},
                    original | {"media_next": 13}, original | {"media_next": "11"},
                    original | {"media_next": True}, original | {"extra": 12},
                    {key: value for key, value in original.items() if key != "media_next"}):
      with self.subTest(keys=invalid):
        self.assertFalse(valid(invalid))

  def test_host_values_render_into_shared_templates(self):
    widget = ENV.from_string((ROOT / "files/desktop/i3/widgets/wifi.sh.j2").read_text())
    for interface in ("wlo1", "wlan0", ""):
      rendered = widget.render(wifi_interface=interface)
      self.assertIn("local interface=" + shlex.quote(interface), rendered)
      subprocess.run(["bash", "-n"], input=rendered, text=True, check=True)
    subprocess.run(["bash", "-n"], input=widget.render(), text=True, check=True)
    rendered = (ROOT / "files/common/git/.gitconfig-personal").read_text()
    result = subprocess.run(["git", "config", "--file", "-", "--get", "user.email"],
                            input=rendered, text=True, capture_output=True, check=True)
    self.assertEqual(result.stdout.strip(), "zigotica@gmail.com")

  def test_work_git_is_opt_in_and_non_disclosing(self):
    git_tasks = load("tasks/common/git.yml")
    opt_in = next(task for task in git_tasks if "ansible.builtin.import_tasks" in task)
    self.assertEqual(opt_in["when"], "manage_git_work")
    tasks = load("tasks/opts/git-work/main.yml")
    for task in tasks:
      self.assertIs(task["no_log"], True)
    copy = tasks[-1]["ansible.builtin.copy"]
    self.assertEqual(copy["src"], "{{ git_work_config_file }}")
    self.assertTrue(copy["dest"].endswith("/.gitconfig-work"))
    self.assertEqual(copy["mode"], "0600")
    self.assertIs(copy["backup"], False)
    self.assertIs(tasks[-1]["diff"], False)
    self.assertIn("validate", copy)
    self.assertFalse(any(task.get("ansible.builtin.file", {}).get("state") == "absent" for task in tasks))

  def test_work_git_private_source_validation(self):
    tasks = load("tasks/opts/git-work/main.yml")
    script = tasks[1]["ansible.builtin.command"]["argv"][2]
    with tempfile.TemporaryDirectory() as directory:
      private = Path(directory) / "work.gitconfig"
      private.write_text("[user]\n  email = work@example.invalid\n")
      internal_link = Path(directory) / "repository-link"
      internal_link.symlink_to(ROOT / "files/common/git/.gitconfig")
      external_link = Path(directory) / "private-link"
      external_link.symlink_to(private)
      for source, accepted in ((private, True), (external_link, True),
                               (internal_link, False), (ROOT / "README.md", False),
                               ("relative.gitconfig", False), (directory, False),
                               (Path(directory) / "missing", False)):
        with self.subTest(source=str(source)):
          result = subprocess.run([sys.executable, "-c", script, str(source), str(ROOT)],
                                  capture_output=True, text=True)
          self.assertEqual(result.returncode == 0, accepted)

  def test_optional_recipes_exit_before_feature_access(self):
    for recipe, switch in (("wifi", "manage_wifi"), ("touchpad", "manage_touchpad"), ("dns", "manage_dns")):
      with self.subTest(recipe=recipe):
        pre = load(f"playbooks/{recipe}.yml")[0]["pre_tasks"]
        self.assertEqual(pre[0]["ansible.builtin.import_tasks"], "../tasks/validate_target.yml")
        self.assertEqual(len(pre), 1)
        feature_tasks = load(f"tasks/opts/{recipe}/main.yml")
        self.assertEqual(feature_tasks[0]["ansible.builtin.meta"], "end_play")
        self.assertEqual(feature_tasks[0]["when"], f"not {switch}")

  def test_hostname_does_not_require_dns_or_wifi(self):
    hostname_play = load("tasks/common/hostname.yml")
    self.assertNotIn("dns_", str(hostname_play))
    self.assertNotIn("wifi_", str(hostname_play))
    self.assertNotIn("dhcpcd", str(hostname_play))

  def test_dns_uses_only_the_shared_encrypted_settings(self):
    self.assertNotIn("dns_servers", self.desktop)
    self.assertNotIn("dns_search_domain", self.desktop)
    self.assertTrue((ROOT / "vault/network.yml").read_bytes().startswith(b"$ANSIBLE_VAULT;"))
    tasks = load("tasks/opts/dns/main.yml")
    self.assertEqual(tasks[0]["when"], "not manage_dns")
    check = tasks[1]
    self.assertIn("vault/network.yml", check["ansible.builtin.command"]["argv"][-1])
    self.assertIn("$ANSIBLE_VAULT;", check["ansible.builtin.command"]["argv"][2])
    include = tasks[2]
    self.assertEqual(include["ansible.builtin.include_vars"]["name"], "shared_network")
    self.assertTrue(include["ansible.builtin.include_vars"]["file"].endswith("/vault/network.yml"))
    self.assertIs(include["no_log"], True)
    persist = next(task for task in tasks if "ansible.builtin.blockinfile" in task)
    self.assertIn("shared_network.dns_servers", persist["ansible.builtin.blockinfile"]["block"])
    self.assertIn("shared_network.dns_search_domain", persist["ansible.builtin.blockinfile"]["block"])
    self.assertIs(persist["no_log"], True)
    self.assertIs(persist["diff"], False)
    validation = next(task for task in tasks if task["name"] == "Validate DNS server addresses")
    self.assertIs(validation["no_log"], True)

  def test_user_deployment_gates(self):
    tasks = load("tasks/user_config.yml")
    figurine = next(task for task in tasks if task.get("ansible.builtin.import_tasks") == "common/figurine.yml")
    self.assertNotIn("when", figurine, "Figurine is installed for both profiles")
    for task in tasks:
      if task.get("ansible.builtin.import_tasks") == "desktop/main.yml":
        self.assertEqual(task["when"], "machine_profile == 'desktop'")
    for component in ("shell", "git", "neovim-config"):
      for task in load(f"tasks/common/{component}.yml"):
        copy = task.get("ansible.builtin.copy")
        if copy:
          self.assertIs(copy["backup"], False)
          folder = {"shell": "shell", "git": "git", "neovim-config": "neovim"}[component]
          for source in task["loop"]:
            self.assertTrue((ROOT / "files/common" / folder / source).exists())


if __name__ == "__main__":
  unittest.main(verbosity=2)
