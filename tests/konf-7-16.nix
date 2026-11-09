# NixOS test module (as consumed by pkgs.testers.runNixOSTest).
_: {
  name = "konf-7-16";

  nodes.machine = _: {
    grundschutz.requirements."KONF.7.16".enable = true;
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    expected = {
        "kernel.kptr_restrict": "2",
        "kernel.dmesg_restrict": "1",
        "kernel.unprivileged_bpf_disabled": "1",
        "net.core.bpf_jit_harden": "2",
        "kernel.randomize_va_space": "2",
        "kernel.yama.ptrace_scope": "1",
        "kernel.perf_event_paranoid": "2",
        "kernel.kexec_load_disabled": "1",
    }
    for key, value in expected.items():
        actual = machine.succeed(f"sysctl -n {key}").strip()
        t.assertEqual(actual, value, key)

    cmdline = machine.succeed("cat /proc/cmdline")
    for param in ["slab_nomerge", "init_on_alloc=1", "init_on_free=1", "page_alloc.shuffle=1", "randomize_kstack_offset=on"]:
        t.assertIn(param, cmdline.split(), "kernel command line")
  '';
}
