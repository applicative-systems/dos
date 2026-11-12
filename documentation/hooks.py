"""MkDocs hooks (see `hooks:` in mkdocs.yml)."""

# Pages the Nix build generates (nix/documentation.nix); the files in
# docs/ are placeholders, so "edit"/"view this page" would point nowhere.
GENERATED = ("requirements/", "options.md", "status.md")


def on_files(files, config):
    for f in files:
        if f.src_uri.startswith(GENERATED):
            f.edit_uri = None
    return files
