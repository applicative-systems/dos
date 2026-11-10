<!--
SPDX-FileCopyrightText: Bundesamt für Sicherheit in der Informationstechnik (BSI); the grundschutz-nixos contributors
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Requirement status

Generated from `catalog/` (BSI Grundschutz++, CC BY-SA 4.0) and `mapping/mapping.json`. Do not edit; run `tools/update-status.sh`.
Controls without a mapping entry are `unmapped` (not yet triaged). Only groups with something implemented, partial or planned get a table. This is our interpretation, not an official BSI statement.

## Summary

| Group | Title | Total | implemented | partial | planned | manual | not-applicable | deferred | unmapped |
|---|---|---|---|---|---|---|---|---|---|
| GC | Governance und Compliance | 16 | 0 | 0 | 0 | 0 | 0 | 0 | 16 |
| STM | Strukturmodellierung | 6 | 0 | 0 | 0 | 0 | 0 | 0 | 6 |
| UMS | Umsetzung | 11 | 0 | 0 | 0 | 0 | 0 | 0 | 11 |
| VRB | Verbesserung | 10 | 0 | 0 | 0 | 0 | 0 | 0 | 10 |
| PERF | Monitoring-Evaluation | 9 | 0 | 0 | 0 | 0 | 0 | 0 | 9 |
| RISK | Risikomanagement | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 4 |
| ASST | Informationen und Assets | 44 | 0 | 0 | 0 | 0 | 0 | 0 | 44 |
| PERS | Personal | 19 | 0 | 0 | 0 | 0 | 0 | 0 | 19 |
| BES | Beschaffungsmanagement | 54 | 0 | 0 | 0 | 0 | 0 | 0 | 54 |
| DLS | Dienstleistersteuerung | 12 | 0 | 0 | 0 | 0 | 0 | 0 | 12 |
| TEST | Änderungen und Tests | 16 | 0 | 0 | 0 | 0 | 0 | 0 | 16 |
| GEB | Gebäudemanagement | 46 | 0 | 0 | 0 | 0 | 0 | 0 | 46 |
| SENS | Sensibilisierung | 76 | 0 | 0 | 0 | 0 | 0 | 0 | 76 |
| ARCH | Architektur | 30 | 0 | 0 | 0 | 0 | 0 | 0 | 30 |
| BER | Berechtigung | 79 | 0 | 0 | 0 | 0 | 0 | 0 | 79 |
| NOT | Notfallplanung | 26 | 0 | 0 | 0 | 0 | 0 | 0 | 26 |
| DET | Detektion | 42 | 0 | 0 | 0 | 0 | 0 | 0 | 42 |
| REA | Sicherheitsvorfallsbehandlung | 10 | 0 | 0 | 0 | 0 | 0 | 0 | 10 |
| KONF | Konfiguration | 113 | 1 | 10 | 19 | 17 | 9 | 57 | 0 |
| DEV | Entwicklung | 29 | 0 | 0 | 0 | 0 | 0 | 0 | 29 |
| **all** | | **652** | 1 | 10 | 19 | 17 | 9 | 57 | 539 |

## KONF: Konfiguration

| ID | Level | Status | Title | Modules | Tests | Notes |
|---|---|---|---|---|---|---|
| KONF.1.1 | normal-SdT | manual | Verfahren und Regelungen |  |  | Process/policy for configuration management. The flake repo with review and CI is the technical foundation, but the policy itself is organizational. |
| KONF.1.2 | normal-SdT | manual | Regelmäßige Überprüfung |  |  | Periodic review of the policies; organizational. |
| KONF.1.3 | normal-SdT | manual | Management von Werkzeugen |  |  | Documentation of config tools and their origin; flake.lock pins provenance, the documentation is organizational. |
| KONF.1.4 | normal-SdT | manual | Einschränkung des Zugriffs auf Dokumentation |  |  | Access restriction on configuration documentation (git repo permissions); outside the NixOS config. |
| KONF.1.5 | normal-SdT | manual | Verschlüsselung von Konfigurationsgeheimnissen |  |  | Secrets in config should be encrypted (sops-nix/agenix). Cannot be detected generically; KONF.2.3 already rejects plaintext user passwords. |
| KONF.2.1 | normal-SdT | manual | Grundkonfiguration für Systeme |  |  | The NixOS configuration is the documented baseline; documenting it is up to the user. |
| KONF.2.2 | normal-SdT | partial | Kryptographische Verfahren in IT-Systemen | [`modules/konf/2-2-cryptographic-algorithms.nix`](../modules/konf/2-2-cryptographic-algorithms.nix) | [`tests/konf-ssh.nix`](../tests/konf-ssh.nix) | SSH only. The guidance defers to established algorithms; we use BSI TR-02102-4 (2026-01) tables 2-5 as that standard. sshd and the ssh client are limited to the listed key exchange, cipher, MAC and signature algorithms (OpenSSH names), host keys are ECDSA only, rekey after 1 GB/1 h. Consequences: Ed25519, Curve25519 and RSA are not in the TR and are rejected. diffie-hellman-group15-sha512 has no OpenSSH equivalent. Encrypt-then-MAC HMAC variants and sk-ecdsa-sha2-nistp256 are accepted as the same primitives (our interpretation). Not covered: TLS and other protocols, disk encryption algorithms, DH group size in /etc/ssh/moduli. |
| KONF.2.3 | normal-SdT | partial | Default-Zugangsdaten in IT-Systemen | [`modules/konf/2-3-default-credentials.nix`](../modules/konf/2-3-default-credentials.nix) |  | Plaintext passwords in the config are rejected. Well-known default hashes cannot be detected. |
| KONF.2.4 | normal-SdT | partial | Deaktivierung nicht benötigter Systemfunktionen | [`modules/konf/2-4-disable-unneeded-functions.nix`](../modules/konf/2-4-disable-unneeded-functions.nix) | [`tests/konf-2-4.nix`](../tests/konf-2-4.nix) | Disables Bluetooth, FireWire, rarely used network protocols/filesystems (kernel modules), avahi, printing and the default package set. List is a starting point, not exhaustive. Deviations via keepKernelModules and keepServices. Not covered: weak crypto algorithms (KONF.2.2), unneeded users, firmware features. |
| KONF.2.5 | normal-SdT | planned | Überprüfung der Systemkonfiguration |  |  | Configuration drift. NixOS is declarative; plan: assert system.configurationRevision is set so a running system is traceable to a commit. |
| KONF.2.6 | normal-SdT | not-applicable | Mobile Device Management |  |  | Mobile devices; server scope. |
| KONF.2.7 | erhöht | manual | Souveräne Werkzeuge |  |  | Level erhöht, optional (KANN). Sovereign tooling is a procurement decision. |
| KONF.2.8 | erhöht | manual | Alternative Administrationszugänge |  |  | Level erhöht, optional. Alternative admin access (e.g. serial/out-of-band) is deployment specific. |
| KONF.2.9 | erhöht | planned | Abgesicherter und authentisierter Bootprozess |  |  | Level erhöht. Assert Secure Boot is active (e.g. lanzaboote) when the option is available; exempt for VMs. |
| KONF.3.1 | normal-SdT | planned | Kryptographischer Hardwarespeicher |  |  | Assert TPM use (security.tpm2.enable) with exempt for hardware without TPM. |
| KONF.3.2 | normal-SdT | planned | Speicherverschlüsselung |  |  | Assert encrypted root (initrd LUKS, or ZFS native encryption). Exempt option for cloud/VM setups where the provider encrypts. |
| KONF.3.3 | normal-SdT | not-applicable | SIM-PIN |  |  | SIM/mobile connectivity; server scope. |
| KONF.3.4 | erhöht | not-applicable | Physischer Diebstahlschutz |  |  | Mobile devices. |
| KONF.3.5 | erhöht | not-applicable | Standortbestimmung |  |  | Location determination, optional (KANN); not meaningful for servers. |
| KONF.3.6 | erhöht | not-applicable | Fernlöschung oder -sperre |  |  | Mobile devices. |
| KONF.3.7 | normal-SdT | planned | Einschränkung angeschlossener Peripherie |  |  | Restrict attached peripherals: services.usbguard and/or blacklist usb-storage. Needs an allowlist option per deployment. |
| KONF.3.8 | normal-SdT | partial | Einschränkung von Wechselmedien | [`modules/konf/3-8-removable-media.nix`](../modules/konf/3-8-removable-media.nix) | [`tests/konf-mounts-privileges.nix`](../tests/konf-mounts-privileges.nix) | Disables automounters: udisks2, devmon, gvfs, autofs. Manual mounts stay possible and are not forced to noexec. Desktops will need an opt-out. |
| KONF.4.1 | normal-SdT | manual | Anbindung an Verzeichnisdienst |  |  | Directory service attachment depends on the organization (SSSD/LDAP); not generically enforceable. |
| KONF.4.2 | normal-SdT | planned | DNS-Anbindung |  |  | Resolvers must be authorized. Plan: option listing allowed resolvers, assert networking.nameservers/resolved DNS is a subset. |
| KONF.4.3 | normal-SdT | partial | Authentifizierung von Fernwartungsfunktionen | [`modules/konf/4-3-remote-maintenance-authentication.nix`](../modules/konf/4-3-remote-maintenance-authentication.nix) | [`tests/konf-ssh.nix`](../tests/konf-ssh.nix) | SSH only. Public key authentication only; password, keyboard-interactive, empty-password and host-based authentication are off. Other remote maintenance protocols (RDP, SNMP, vendor tools) are not covered. |
| KONF.4.4 | normal-SdT | partial | Einschränkung von Fernwartungsfunktionen | [`modules/konf/4-4-remote-maintenance-restriction.nix`](../modules/konf/4-4-remote-maintenance-restriction.nix) | [`tests/konf-ssh.nix`](../tests/konf-ssh.nix) | SSH only. No root login, login restricted to allowGroups (default wheel), TCP/agent/X11 forwarding, gateway ports and tunnels off unless allowForwarding is set. Deploy tools need a normal admin user with sudo instead of root. Lockout guard: evaluation fails if no user in allowGroups has an authorized key (ECDSA when KONF.2.2 is on). |
| KONF.4.5 | normal-SdT | planned | Zeitquellen |  |  | Time sources must be authorized. Plan: option for NTP servers, enforce on timesyncd/chrony, assert no unlisted sources. |
| KONF.5.1 | normal-SdT | partial | Authentifizierung am System | [`modules/konf/5-1-system-authentication.nix`](../modules/konf/5-1-system-authentication.nix) |  | Every login must authenticate: users.allowNoPasswordLogin false, no console autologin, no user with an empty hashed password, no PAM service accepting empty passwords. The login PAM service is forced to false because NixOS enables it by default. Covered by the eval assertion test and the profile check only: NixOS VM tests cannot enable it, since the test driver uses an empty root password. Screen lock and MFA are not covered (BER.5.9). |
| KONF.5.2 | normal-SdT | manual | Keine Mehrfachanmeldung |  |  | Guidance is about users being logged in with several identities at once; no config-level rule on a server. Revisit if desktop scope is added. |
| KONF.6.1 | normal-SdT | planned | Minimal erforderliche Berechtigungen für Anwendungen |  |  | Minimal privileges for applications: systemd sandboxing defaults for services we manage, plus AppArmor. Large; split per service later. |
| KONF.6.2 | normal-SdT | deferred | Gemeinsam genutzte Verzeichnisse |  |  | File server role only; handle in a role-specific module (Samba/NFS). |
| KONF.6.3 | erhöht | not-applicable | Kiosk-Modus |  |  | Mobile kiosk mode. |
| KONF.6.4 | normal-SdT | partial | Privilegierte Systemfunktionen | [`modules/konf/6-4-privileged-functions.nix`](../modules/konf/6-4-privileged-functions.nix) | [`tests/konf-mounts-privileges.nix`](../tests/konf-mounts-privileges.nix) | sudo executable only for group wheel, sudo asks wheel members for a password (opt-out allowPasswordlessSudo), su requires wheel. privilegeEscalation = run0 replaces sudo with systemd run0 (polkit, no setuid sudo). Not covered: role-based administration (KANN), inventory of setuid wrappers. |
| KONF.6.5 | erhöht | planned | Dynamische Zugriffskontrolle im System |  |  | Level erhöht. Mandatory access control: assert security.apparmor.enable. |
| KONF.6.6 | normal-SdT | deferred | Getrennte Datenhaltung |  |  | Application level. |
| KONF.6.7 | normal-SdT | deferred | Privilegierte Funktionen der Anwendung |  |  | Application level. |
| KONF.6.8 | normal-SdT | deferred | Berechtigungen des Webserver-Prozesses |  |  | Web server role. |
| KONF.6.9 | normal-SdT | deferred | Zugriff auf Code |  |  | Web server role. |
| KONF.6.10 | normal-SdT | deferred | Auflistung von Verzeichnisinhalten |  |  | Web server role. |
| KONF.6.11 | normal-SdT | deferred | Einschränkung von Uploads |  |  | Web server role. |
| KONF.6.12 | normal-SdT | not-applicable | Konferenzmoderation |  |  | Video conferencing application. |
| KONF.6.13 | erhöht | deferred | Dynamische Zugriffskontrolle in der Anwendung |  |  | Application level, optional. |
| KONF.6.14 | normal-SdT | not-applicable | Browser Sandboxing |  |  | Web browsers; server scope. |
| KONF.6.15 | erhöht | not-applicable | Virtualisierte Browser-Umgebung |  |  | Web browsers; server scope. |
| KONF.6.16 | erhöht | deferred | Datenaustausch in der Virtualisierung |  |  | Virtualization hosts only; handle with a virtualization role. |
| KONF.7.1 | normal-SdT | planned | Echtzeitscanner |  |  | Malware scanning on file access: ClamAV (services.clamav, on-access). Needs an agreed scope of paths. |
| KONF.7.2 | normal-SdT | planned | Regelmäßige Scans |  |  | Regular scans: services.clamav.scanner with interval. |
| KONF.7.3 | erhöht | planned | Host-basierte Angriffserkennung |  |  | Level erhöht. Host-based detection (auditd rules, AIDE); verify which options nixpkgs provides. |
| KONF.7.4 | erhöht | manual | Angriffserkennung anhand von Netzverkehr |  |  | Level erhöht. Network IDS is usually a separate system. |
| KONF.7.5 | normal-SdT | planned | Alarmierung |  |  | Alerting on malware findings. Assert a notification path (mail/webhook) is configured once 7.1/7.2 exist. |
| KONF.7.6 | normal-SdT | planned | Automatische Updates |  |  | Automatic signature updates: services.clamav.updater. |
| KONF.7.7 | erhöht | manual | Regelmäßiger Funktionstest |  |  | Level erhöht. Periodic test of the scanner (EICAR); operational procedure. |
| KONF.7.8 | erhöht | manual | Dual-Engine-Strategie |  |  | Level erhöht. Multiple scan engines; product decision. |
| KONF.7.9 | normal-SdT | planned | Einschränkung der Installation |  |  | Restrict installation of software: users.mutableUsers false, nix.settings.allowed-users restricted to wheel/root. |
| KONF.7.10 | normal-SdT | partial | Einschränkung der Ausführung | [`modules/konf/7-10-execution-restriction.nix`](../modules/konf/7-10-execution-restriction.nix) | [`tests/konf-mounts-privileges.nix`](../tests/konf-mounts-privileges.nix) | noexec,nosuid,nodev on /tmp (tmpfs), /var/tmp (bind mount) and /dev/shm. Opt-out via keepExec; Nix builds in /tmp need it. Not covered: application allowlisting (AppArmor/SELinux, code signing), data mounts such as /home or /srv (site specific). |
| KONF.7.11 | erhöht | manual | Einschränkung von Softwarebibliotheken |  |  | Level erhöht. Library execution control; no standard NixOS mechanism. |
| KONF.7.12 | erhöht | manual | Einschränkung von Skripten |  |  | Level erhöht. Script execution control; no standard NixOS mechanism. |
| KONF.7.13 | erhöht | deferred | Einschränkung von Systemaufrufen |  |  | Level erhöht. Per-service systemd SystemCallFilter; part of per-service hardening (see 6.1). |
| KONF.7.14 | normal-SdT | planned | Code-Signierung im Betriebssystemkern |  |  | Module signature enforcement. NixOS kernels do not sign modules by default; investigate security.lockKernelModules and a signed-kernel option first. |
| KONF.7.15 | normal-SdT | partial | Lokale Firewall | [`modules/konf/7-15-local-firewall.nix`](../modules/konf/7-15-local-firewall.nix) | [`tests/konf-7-15.nix`](../tests/konf-7-15.nix) | Host firewall is enabled and asserted. Outbound allowlisting is application-specific and not enforced. |
| KONF.7.16 | normal-SdT | implemented | Anti-Exploit | [`modules/konf/7-16-anti-exploit.nix`](../modules/konf/7-16-anti-exploit.nix) | [`tests/konf-7-16.nix`](../tests/konf-7-16.nix) | Interpretation: kernel exploit mitigations. Sysctl limits (kptr_restrict, dmesg_restrict, unprivileged BPF, BPF JIT hardening, ASLR, ptrace_scope, perf_event_paranoid), hardened boot parameters (slab_nomerge, init_on_alloc/free, page_alloc.shuffle, randomize_kstack_offset, vsyscall=none), page table isolation, kexec disabled. Contradicting user settings are reported via assertions. |
| KONF.8.1 | normal-SdT | planned | Automatische Überprüfung |  |  | Monitor for pending security updates. Plan: assert update checking is configured (autoUpgrade or vulnix); exempt for externally managed deployments. |
| KONF.8.2 | normal-SdT | planned | Automatische Updates der Anwendung |  |  | Automatic security updates for applications: assert system.autoUpgrade (flake-based) or exempt with reason. |
| KONF.9.1 | normal-SdT | planned | Speicherplatzbegrenzung |  |  | Guidance: limit storage for non-system services via quotas/separate filesystems. Plan: assert separate /var and /home mounts or quotas. |
| KONF.9.2 | erhöht | manual | Begrenzung der Hostleistung |  |  | Level erhöht. Host CPU limits for guests; part of virtualization role. |
| KONF.9.3 | erhöht | manual | Alternative Komponenten für kritische Funktionen |  |  | Level erhöht. Redundant components for critical functions; architecture decision. |
| KONF.10.1 | normal-SdT | deferred | Grundkonfiguration für Anwendungen |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.10.2 | normal-SdT | deferred | Kryptographische Verfahren in Anwendungen |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.10.3 | normal-SdT | deferred | Default-Zugangsdaten in Anwendungen |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.10.4 | normal-SdT | deferred | Deaktivierung nicht benötigter Anwendungsfunktionen |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.10.5 | normal-SdT | deferred | Überprüfung der Konfiguration |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.11.1 | normal-SdT | deferred | Authentifizierung vor dem Zugriff |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.11.2 | normal-SdT | deferred | Warteraum |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.11.3 | normal-SdT | deferred | Veröffentlichung von Domain-Infomationen |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.11.4 | normal-SdT | deferred | Erraten von Zugriffslinks |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.11.5 | normal-SdT | deferred | Einschränkung unauthentifizierter Anschlüsse |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.11.6 | erhöht | deferred | Übersicht angemeldeter Verbindungen |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.11.7 | normal-SdT | deferred | Einschränkung von Schnittstellen |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.11.8 | erhöht | deferred | Verschlüsselung schützenswerter Daten (at-rest) |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.12.1 | normal-SdT | deferred | Eingabevalidierung |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.12.2 | normal-SdT | deferred | Verschlüsselungsstatus der aktuellen Verbindung |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.12.3 | normal-SdT | deferred | Cookies |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.12.4 | normal-SdT | deferred | Speicherung von Zugangsdaten |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.12.5 | normal-SdT | deferred | Auto-Vervollständigung von Daten |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.12.6 | erhöht | deferred | Browser-Historie |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.12.7 | normal-SdT | deferred | Erweiterte Attribute |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.12.8 | normal-SdT | deferred | Teilnahme per Default ohne Bild und Ton |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.12.9 | normal-SdT | deferred | Keine heimliche Aufzeichnung |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.12.10 | normal-SdT | deferred | Cookie-Attribute |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.12.11 | erhöht | deferred | Anonyme oder Pseudonyme Kommunikation |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.12.12 | normal-SdT | deferred | Verbindungsprotokoll |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.12.13 | normal-SdT | deferred | Sendebericht |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.12.14 | normal-SdT | deferred | DNS-Falschinformationen |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.13.1 | normal-SdT | deferred | Filtern schädlicher Nachrichten |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.13.2 | normal-SdT | deferred | Authentizität von Nachrichten |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.13.3 | normal-SdT | deferred | Kryptographische Signatur des Mailservers |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.13.4 | erhöht | deferred | Kryptographische Signatur durch Nutzende |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.13.5 | normal-SdT | deferred | Publikation der Sendeberechtigung |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.13.6 | normal-SdT | deferred | Publikation der Serversignatur |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.13.7 | erhöht | deferred | TLS-Reports |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.13.8 | erhöht | deferred | DMARC-Reports |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.13.9 | normal-SdT | deferred | Publikation der DMARC-Richtlinie |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.13.10 | normal-SdT | deferred | Authentifizierung der Server-Zertifikate über DNS |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.13.11 | normal-SdT | deferred | MTA-STS |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.14.1 | normal-SdT | deferred | Verschlüsselung beim Transport |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.14.2 | normal-SdT | deferred | Source Port Randomisierung |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.14.3 | normal-SdT | deferred | Iterative Beantwortung |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.14.4 | erhöht | deferred | Caching |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.14.5 | normal-SdT | deferred | Zeitüberschreitung von Netzverbindungen |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.15.1 | erhöht | deferred | Begrenzung des Speicherplatzes |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.15.2 | erhöht | deferred | Begrenzung der Rechenleistung |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.15.3 | erhöht | deferred | Schutz gegen Denial of Service |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |
| KONF.15.4 | erhöht | deferred | Überbuchung von virtualisierten Ressourcen |  |  | Application- or service-specific (KONF.10 to KONF.15); to be handled in per-service/role modules. |

## Groups without a table

These groups have no implemented, partial or planned control, so their controls are not listed individually (see the summary for counts): GC, STM, UMS, VRB, PERF, RISK, ASST, PERS, BES, DLS, TEST, GEB, SENS, ARCH, BER, NOT, DET, REA, DEV.
The full list is in `catalog/`.

