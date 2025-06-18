# venvctl

**venvctl** is a lightweight CLI utility to manage Python virtual environments using `venv`.  
It includes convenient commands to create, activate, remove, and list environments.

+ Built for Python developers who prefer `venv` over `conda`, but still want conda-like ergonomics.
+ 

---

## Features
### Current
+ `venvctl create <name>` — create a virtual environment with optional name
+ `venvctl remove <name>` — delete an environment
+ `venvctl activate <name>` — safely activate an environment
+ `venvctl deactivate` - handle the cases where some shells don’t preload the deactivate function unless a venv is active.
+ `venvctl list` — list all environments managed by `venvctl`
+ `venvctl status` — show current environment and the corresponding Python version

### Ongoing
+ `venvctl test {start|stop}` - Test the new features that will be added.
+ `venvctl --version` - Get the current version. Will be implemented along with the major update for the next version.
+ `venvctl create <name> --Python 3.x.x` An extra flag to specify the Python version, which is compatible with the native Python and `pyenv`.

---

## Installation / Uninstallation
There is nothing special for the (un)installation process.
```bash
git clone https://github.com/yourname/venvctl.git
cd venvctl
./install.sh
```

This script will:
+ Copy `venvctl.sh` to `~/.config/venvctl/`
+ Create a persistent registry at `~/.config/venvctl/venvs.db`
+ Create a symbolic link to `~/.local/bin/venvctl`

That being said, it's necessary to make sure `~/.local/bin` is in your `$PATH`:
```bash
echo $PATH | grep -q "$HOME/.local/bin" && echo "Yep" || echo "Nope"
```
If not, add the following to your shell config (~/.bash_profile or ~/.bashrc):
```bash
export PATH="$HOME/.local/bin:$PATH"
```
Then
```bash
source ~/.bash_profile  # or source ~/.bashrc
```

## Project Structure
```
~/.config/venvctl/
├── venvctl.sh         # Main CLI script
└── venvs.db           # Tracked virtualenv registry

~/.local/bin/venvctl   # Symlink to venvctl.sh
```

This is everything for now.

## Dependencies

+ Bash 5.x (Tested on bash 5.2)
+ Python>=3.3 (so that it ships with the `venv` module)
+ pyenv (Tested on 2.6.2). This is currently optional but recommended.


## Next Steps

This project is actively developed and tested on:

- **macOS Sequoia 15.5**
  - Bash 5.2
  - GNU coreutils (installed via Homebrew)
- Planned test coverage:
  - macOS default (Zsh + BSD coreutils)
  - Ubuntu/Debian (Bash/Zsh, GNU utils)
  - Other Linux distros

---

### New Features

#### `--python` Flag for `venvctl create`

Allow specifying the Python version directly:

```bash
venvctl create myenv --Python 3.x.x
```

+ Check whether the specified version exists via `pyenv versions | grep <version>`
+ If not:
    - Attempt install via `pyenv install <version>`
    - Set the local Python version via `pyenv local <version>`
+ Call
```bash
  python3 -m venv myenv
```

---

#### Enhanced Test Mode

Goals:
+ Use isolated sandbox `.venvctl_test/`
+ Override `$VENVCTL_CONFIG_DIR` and `$VENVCTL_DB`
+ Auto-clean via `venvctl test cleanup`

---

#### Versioning
TBD.

### Future: Homebrew/apt Support

Allow installation via:

```bash
brew install venvctl
sudo apt install venvctl
```
