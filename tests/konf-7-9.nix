{
  name = "konf-7-9";

  nodes.machine = {
    grundschutz.requirements."KONF.7.9".enable = true;
    users.users = {
      alice.isNormalUser = true;
      admin = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("nix-daemon.socket")

    query = "nix-store --query --hash /run/current-system"

    # unprivileged users are refused by the Nix daemon, so they cannot install
    # (the client only sees a reset connection; the reason is in the daemon log)
    machine.fail(f"su - alice -c '{query}'")
    machine.wait_until_succeeds(
        "journalctl -u nix-daemon | grep -q \"user 'alice' is not allowed to connect\""
    )

    # wheel members may
    machine.succeed(f"su - admin -c '{query}'")
  '';
}
