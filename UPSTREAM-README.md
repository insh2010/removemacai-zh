<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/screens/overview-dark.webp">
    <img src="docs/screens/overview-light.webp" alt="The RemoveMacAI app" width="840">
  </picture>
</p>

# RemoveMacAI

Debloat macOS. Turn off Apple Intelligence and delete its models, stop the analytics and ads, quiet the pop-ups, switch off other apps' background updaters and get disk space back. You see every change before it happens, and every change can be undone.

Built on [pared](https://github.com/4evy/pared) by 4evy, who did the hard work first: mapping Apple's asset service, the model sets and the settings keys the Apple Intelligence part relies on.

## Install

### The app

```sh
curl -fsSL https://raw.githubusercontent.com/omlahore/RemoveMacAI/main/install.sh | bash -s app
```

### The command line

```sh
curl -fsSL https://raw.githubusercontent.com/omlahore/RemoveMacAI/main/install.sh | bash
```

## Requirements

Apple silicon. macOS 27 supported (27.0.1 needs 0.2.3+). 26 and earlier not supported.

## License

[MIT](LICENSE)

> 完整官方 README（含全部功能表、FAQ、Command line 表格）见上游仓库 https://github.com/omlahore/RemoveMacAI 。
