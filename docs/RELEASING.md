# Publish a GitHub release

This guide assumes an existing GitHub repository with its `origin` remote configured.
The local repository starts on `main`. No remote, commit, tag, or GitHub release is created by the packaging commands.

1. Update `plugin.json` and `CHANGELOG.md` for the version you intend to publish.

2. Run `make test` and the [live DMS checks](TESTING.md).

3. Build the source archive.

```sh
make package
version=$(node -p "require('./plugin.json').version")
(cd dist && sha256sum --check "standtimer-v$version.tar.gz.sha256")
```

4. Commit the reviewed source and push `main`. Confirm that the **Check and package** workflow passes.

5. Tag the committed version and publish its archive and checksum.

```sh
version=$(node -p "require('./plugin.json').version")
git tag "v$version"
git push origin "v$version"
gh release create "v$version" \
	"dist/standtimer-v$version.tar.gz" \
	"dist/standtimer-v$version.tar.gz.sha256" \
	--title "Stand timer $version" --notes-file CHANGELOG.md
```

Use release-specific notes if `CHANGELOG.md` contains more than one version.
Keep the license and source notices in every archive.
Publishing a GitHub release does not submit the plugin to the DMS registry.
