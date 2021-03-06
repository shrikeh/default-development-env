#!/usr/bin/env bash

function setup_ansible_venv() {
  local virtualenv_dir='.venv'
  virtualenv "${virtualenv_dir}";
  source "${virtualenv_dir}/bin/activate";
  pip install -q -r provisioning/ansible/requirements.txt;
}

setup_ansible_venv;
