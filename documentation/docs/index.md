# Deutschland-OS

NixOS modules that implement our interpretation of BSI **Grundschutz++** requirements.
This is not an official BSI product and does not make a system "BSI-compliant".

- [Usage](usage.md): add the modules to your system, enable requirements, deviate explicitly
- [Requirements](requirements/index.md): one page per KONF requirement: what we enforce and how to configure it, or why there is no module, plus the original BSI text
- [Status](status.md): all 652 catalog controls and how far we cover them
- [NixOS options](options.md): reference of every option the modules declare

## Background

- [IT-Grundschutz](https://www.bsi.bund.de/DE/Themen/Unternehmen-und-Organisationen/Standards-und-Zertifizierung/IT-Grundschutz/it-grundschutz_node.html) is the BSI's information security methodology; **Grundschutz++** is its machine-readable successor.
- [Stand-der-Technik-Bibliothek](https://github.com/BSI-Bund/Stand-der-Technik-Bibliothek) is the BSI's GitHub repository with the Grundschutz++ catalog (OSCAL/JSON). Requirement IDs such as `KONF.7.10` refer to it; `normal-SdT` and `erhöht` are its security levels.
- [BSI TR-02102](https://www.bsi.bund.de/dok/TR-02102-en) contains the technical guidelines on cryptographic mechanisms; [TR-02102-4](https://www.bsi.bund.de/SharedDocs/Downloads/EN/BSI/Publications/TechGuidelines/TG02102/BSI-TR-02102-4.html) covers SSH and is the basis of the SSH algorithm requirements (KONF.2.2, 4.3, 4.4).

## License

The code is MIT licensed. The requirement texts quoted on the requirement and status pages are taken from the BSI catalog and licensed under CC BY-SA 4.0.
