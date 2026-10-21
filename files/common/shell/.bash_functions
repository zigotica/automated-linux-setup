#!/usr/bin/env bash

# Functions
__is_ssh() {
  if [[ -n ${SSH_CONNECTION:-} ]]; then
    printf '[SSH] '
  fi
}

# Return history entries filtered by grep or number of items
# use case: hist [<grep>] [<number>]
# example: hist yarn
# example: hist 20
# example: hist yarn 20
function hist() {
  if [[ -n "$@" ]]; then
    if [ "$#" -gt 1 ]; then
      if [ -z "${2//[0-9]}" ]; then
        history | grep "$1" | tail -"$2";
      else
        echo "usage: hist [<grep>] [<number>]" >&2;
        exit 1;
      fi
    elif [ -z "${@//[0-9]}" ]; then
      history "$@";
    else
      history | grep "$@";
    fi;
  else
    history;
  fi;
}
