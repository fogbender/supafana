#!/usr/bin/env sh

usage() {
  echo ''
  echo 'USAGE: '
  echo ''
  echo '-n --name  REQUIRED Permission name'
  echo ''
  echo '-h --help           Help'
  echo ''
}


# Options
while [ $# -gt 0 ]; do
  case "$1" in
    -n|--name)
      permission="$2"
      ;;
    -h|--help)
      usage
      exit 1
      ;;
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument *\n"
      printf "***************************\n"
      usage
      exit 1
  esac
  shift
  shift
done

if [[ -z "${permission}" ]]
then
  printf "************************************\n"
  printf "* Error: Missing required argument *\n"
  printf "************************************\n"
  usage
  exit 1
fi

set -euo pipefail

az role definition list --query "[?permissions[?actions[?contains(@, '${permission}')]]].roleName"
