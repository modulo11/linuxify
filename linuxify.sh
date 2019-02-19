#! /usr/bin/env bash

set -euo pipefail

linuxify_check_os() {
  if ! [[ "$OSTYPE" =~ darwin* ]]; then
      echo "This is meant to be run on macOS only"
      exit
  fi
}

linuxify_check_brew() {
  if ! command -v brew > /dev/null; then
      echo "Homebrew not installed!"
      echo "In order to use this script please install homebrew from https://brew.sh"
      exit
  fi
}

linuxify_formulas=(
    # GNU programs non-existing in macOS
    "watch"
    "wget"
    "wdiff"
    "gdb"
    "autoconf"

    # GNU programs whose BSD counterpart is installed in macOS
    "coreutils"
    "binutils"
    "diffutils"
    "ed"
    "findutils"
    "gawk"
    "gnu-indent"
    "gnu-sed"
    "gnu-tar"
    "gnu-which"
    "grep"
    "gzip"
    "screen"

    # GNU programs existing in macOS which are outdated
    "bash"
    "emacs"
    "gpatch"
    "less"
    "m4"
    "make"
    "nano"
    "bison"

    # BSD programs existing in macOS which are outdated
    "flex"

    # Other common/preferred programs in GNU/Linux distributions
    "libressl"
    "file-formula"
    "git"
    "openssh"
    "perl"
    "python"
    "rsync"
    "unzip"
    "vim"
)

linuxify_install() {
    linuxify_check_os;
    linuxify_check_brew;

    # Install all formulas
    for (( i=0; i<${#linuxify_formulas[@]}; i++ )); do
        brew install ${linuxify_formulas[i]}
    done

    # Change default shell to brew-installed /usr/local/bin/bash
    grep -qF '/usr/local/bin/bash' /etc/shells || echo '/usr/local/bin/bash' | sudo tee -a /etc/shells > /dev/null
    chsh -s /usr/local/bin/bash

    # gdb requires special privileges to access Mach ports.
    # One can either codesign the binary as per https://sourceware.org/gdb/wiki/BuildingOnDarwin
    # Or, on 10.12 Sierra or later with SIP, declare `set startup-with-shell off` in `$HOME/.gdbinit`:
    grep -qF 'set startup-with-shell off' $HOME/.gdbinit || echo 'set startup-with-shell off' | tee -a $HOME/.gdbinit > /dev/null

    # Make changes to PATH/MANPATH/INFOPATH/LDFLAGS/CPPFLAGS
    cp .linuxify $HOME/.linuxify
    echo "Add '[[ "$OSTYPE" =$HOME ^darwin ]] && [ -f $HOME/.linuxify ] && source $HOME/.linuxify' to your $HOME/.bashrc, $HOME/.zshrc or your shell's equivalent config file"
}

linuxify_uninstall() {
    linuxify_check_os;
    linuxify_check_brew;

    # Remove gdb fix
    sed -i.bak '/set startup-with-shell off/d' $HOME/.gdbinit && rm $HOME/.gdbinit.bak

    # Change default shell back to macOS /bin/bash
    sudo sed -i.bak '/\/usr\/local\/bin\/bash/d' /etc/shells && sudo rm /etc/shells.bak
    chsh -s /bin/bash

    # Uninstall all formulas in reverse order
    for (( i=${#linuxify_formulas[@]}-1; i>=0; i-- )); do
        brew uninstall $(echo "${linuxify_formulas[i]}" | cut -d ' ' -f1)
    done

    # Remove changes to PATH/MANPATH/INFOPATH/LDFLAGS/CPPFLAGS
    rm -f $HOME/.linuxify
    echo "Remove '[[ "$OSTYPE" =$HOME ^darwin ]] && [ -f $HOME/.linuxify ] && source $HOME/.linuxify' from your $HOME/.bashrc, $HOME/.zshrc or your shell's equivalent config file"
}

linuxify_info() {
    linuxify_check_os;
    linuxify_check_brew;

    for (( i=0; i<${#linuxify_formulas[@]}; i++ )); do
        echo "==============================================================================================================================="
        brew info ${linuxify_formulas[i]}
    done
}

linuxify_help() {
  echo "usage: linuxify.sh [-h] [command]";
  echo ""
  echo "valid commands:"
  echo "  install    install GNU/Linux utilities"
  echo "  uninstall  uninstall GNU/Linux utilities"
  echo "  info       show info on GNU/Linux utilities"
  echo ""
  echo "optional arguments:"
  echo "  -h, --help  show this help message and exit"
}

linuxify_main() {
    if [ $# -eq 1 ]; then
        case $1 in
            "install") linuxify_install ;;
            "uninstall") linuxify_uninstall ;;
            "info") linuxify_info ;;
            "-h") linuxify_help ;;
            "--help") linuxify_help ;;
        esac
    else
        linuxify_help;
        exit
    fi
}

linuxify_main "$@"
