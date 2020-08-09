#!/usr/bin/env bash

set -e

if [ "$#" -ne 1 ]; then
  echo "Search root was not supplied. Searching from current directory"
  SEARCH_ROOT="$(pwd)"
else
  SEARCH_ROOT="$(readlink -f $1)"
  echo "Searching from ${SEARCH_ROOT}"
fi

PATTERN="https:\/\/([-a-zA-Z0-9]+:[-a-zA-Z0-9_]+@|)([-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6})\/(\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*))"
REPLACEMENT="git@\2:\3"
find "${SEARCH_ROOT}" -type d -name "\.git"  -print | while read -r REPO;
do
  cd "${REPO}"
  echo "Found ${REPO}"
  for name in $(git remote); do
    REMOTE=$(git remote get-url "${name}")
    if [[ "${REMOTE}" =~ ^git@ ]]; then
      continue
    fi
    NEWURL=$(echo "${REMOTE}" | sed --regexp-extended "s/${PATTERN}/${REPLACEMENT}.git/g" | sed --regexp-extended "s/\.git\.git/.git/g")

    echo "Replacing ${name}/${REMOTE} with ${NEWURL}"
    git remote set-url "${name}" "${NEWURL}"
  done
  echo ""
done
