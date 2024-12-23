#!/bin/bash

# install pipx and its depedenencies for ansible

install_nix() {
  echo "Installing Nix"
  sh <(curl -L https://nixos.org/nix/install) --daemon
  source ~/.bashrc
}

install_pipx() {
  echo "Installing pipx"
  sudo apt update
  sudo apt install -y python3-pip python3-venv
  python3 -m pip install --user pipx
  python3 -m pipx ensurepath
  source ~/.bashrc
}

# Install ansible using pipx
install_ansible() {
  echo "Installing Ansible using pipx"
  pipx install ansible
  ansible --version
}

run_ansible() {
  echo "Running Ansible playbook"
  ansible-playbook playbook.yml --ask-become-pass
}

main() {
  # install_pipx
  # update_variables
  install_nix
  # run_ansible
}

main

