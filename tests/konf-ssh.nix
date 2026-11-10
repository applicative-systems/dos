# NixOS test module (as consumed by pkgs.testers.runNixOSTest).
# Covers KONF.2.2, KONF.4.3 and KONF.4.4 on a real sshd, in containers (only
# userspace is involved, so no VM is needed). KONF.5.1 cannot be
# enabled on a test VM: the test driver gives root an empty password and
# console autologin (covered by the 5-1 assertion test in flake.nix instead).
# The expected algorithm sets are taken from BSI TR-02102-4 (2026-01), tables 2-5.
{ hostPkgs, ... }:
let
  keys = hostPkgs.runCommand "konf-ssh-test-keys" { nativeBuildInputs = [ hostPkgs.openssh ]; } ''
    mkdir $out
    ssh-keygen -q -t ecdsa -b 256 -N "" -f $out/ecdsa
    ssh-keygen -q -t ed25519 -N "" -f $out/ed25519
  '';
  authorized = [
    "${keys}/ecdsa.pub"
    "${keys}/ed25519.pub"
  ];
in
{
  name = "konf-ssh";

  # The Nix build sandbox shows store files with a foreign owner, so ssh rejects
  # the systemd-ssh-proxy drop-in that the client config includes.
  defaults.programs.ssh.systemd-ssh-proxy.enable = false;

  containers = {
    server =
      { lib, ... }:
      {
        services.openssh.enable = true;
        grundschutz.requirements = {
          "KONF.2.2".enable = true;
          "KONF.4.3".enable = true;
          "KONF.4.4".enable = true;
        };
        # Without PAM (forced for containers) sshd refuses accounts locked with "!";
        # "*" means "no password login" but not locked.
        users.users = {
          alice = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            hashedPassword = "*";
            openssh.authorizedKeys.keyFiles = authorized;
          };
          bob = {
            isNormalUser = true;
            hashedPassword = "*";
            openssh.authorizedKeys.keyFiles = authorized;
          };
          root = {
            hashedPassword = lib.mkForce "*";
            openssh.authorizedKeys.keyFiles = authorized;
          };
        };
      };

    # unrestricted client: offers every key type, so the server is what refuses
    client = { };

    # client with KONF.2.2: ssh_config algorithm lists
    strict = {
      grundschutz.requirements."KONF.2.2".enable = true;
    };
  };

  testScript = ''
    start_all()
    for node in [server, client, strict]:
        node.wait_for_unit("multi-user.target")
    # containers default to socket-activated sshd (container-config.nix)
    server.wait_for_unit("sshd.socket")
    server.wait_for_open_port(22)

    client.succeed("install -m600 ${keys}/ecdsa /root/id_ecdsa")
    client.succeed("install -m600 ${keys}/ed25519 /root/id_ed25519")

    def ssh(user, key):
        return (
            f"ssh -i /root/id_{key} -o IdentitiesOnly=yes -o BatchMode=yes "
            f"-o StrictHostKeyChecking=no {user}@server true 2>&1"
        )

    def login_works(user, key):
        status, out = client.execute(ssh(user, key))
        t.assertEqual(status, 0, out)

    def login_refused(user, key):
        status, out = client.execute(ssh(user, key))
        t.assertNotEqual(status, 0, out)

    def effective(machine, command):
        out = {}
        for line in machine.succeed(command).splitlines():
            key, _, value = line.partition(" ")
            out[key.lower()] = value
        return out

    KEX = {"diffie-hellman-group-exchange-sha256", "diffie-hellman-group16-sha512",
           "ecdh-sha2-nistp256", "ecdh-sha2-nistp384", "ecdh-sha2-nistp521"}
    CIPHERS = {"aes256-gcm@openssh.com", "aes128-gcm@openssh.com",
               "aes256-ctr", "aes192-ctr", "aes128-ctr"}
    MACS = {"hmac-sha2-512-etm@openssh.com", "hmac-sha2-256-etm@openssh.com",
            "hmac-sha2-512", "hmac-sha2-256"}
    HOSTKEY = {"ecdsa-sha2-nistp256", "ecdsa-sha2-nistp384", "ecdsa-sha2-nistp521"}

    with subtest("KONF.4.3/4.4: an allowed user with an ECDSA key can log in"):
        login_works("alice", "ecdsa")

    with subtest("KONF.2.2: Ed25519 keys are refused although authorized"):
        login_refused("alice", "ed25519")

    with subtest("KONF.4.3: password authentication is refused"):
        status, out = client.execute(
            "ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no "
            "-o BatchMode=yes -o StrictHostKeyChecking=no alice@server true 2>&1"
        )
        t.assertNotEqual(status, 0)
        t.assertIn("Permission denied (publickey)", out)

    with subtest("KONF.4.4: root and users outside AllowGroups are refused"):
        login_refused("root", "ecdsa")
        login_refused("bob", "ecdsa")

    with subtest("KONF.2.2: server offers only an ECDSA host key"):
        scan = client.succeed("ssh-keyscan server 2>/dev/null")
        t.assertIn("ecdsa-sha2-nistp384", scan)
        t.assertNotIn("ssh-ed25519", scan)
        t.assertNotIn("ssh-rsa", scan)

    with subtest("effective sshd configuration"):
        cfg = effective(server, "sshd -T")
        t.assertIn("kexalgorithms", cfg, sorted(cfg))
        t.assertEqual(set(cfg["kexalgorithms"].split(",")), KEX)
        t.assertEqual(set(cfg["ciphers"].split(",")), CIPHERS)
        t.assertEqual(set(cfg["macs"].split(",")), MACS)
        t.assertEqual(set(cfg["hostkeyalgorithms"].split(",")), HOSTKEY)
        t.assertLessEqual(
            set(cfg["pubkeyacceptedalgorithms"].split(",")),
            HOSTKEY | {"sk-ecdsa-sha2-nistp256@openssh.com"},
        )
        t.assertEqual(cfg["rekeylimit"], "1073741824 3600")
        for key, value in {
            "passwordauthentication": "no",
            "kbdinteractiveauthentication": "no",
            "permitemptypasswords": "no",
            "hostbasedauthentication": "no",
            "pubkeyauthentication": "yes",
            "authenticationmethods": "publickey",
            "permitrootlogin": "no",
            "allowgroups": "wheel",
            "allowtcpforwarding": "no",
            "allowagentforwarding": "no",
            "x11forwarding": "no",
            "gatewayports": "no",
            "permittunnel": "no",
        }.items():
            t.assertEqual(cfg[key], value, key)

    with subtest("KONF.2.2: ssh client algorithm lists"):
        cfg = effective(strict, "ssh -G server")
        t.assertIn("kexalgorithms", cfg, sorted(cfg))
        t.assertEqual(set(cfg["kexalgorithms"].split(",")), KEX)
        t.assertEqual(set(cfg["ciphers"].split(",")), CIPHERS)
        t.assertEqual(set(cfg["macs"].split(",")), MACS)
        t.assertEqual(set(cfg["hostkeyalgorithms"].split(",")), HOSTKEY)
  '';
}
