#!/usr/bin/env bash

verbose=false
file="$(pwd)"

print_usage() {
  echo "${0} [-v] [-f filename]"
  echo ""
  echo "f - Target this file/directory instead of the current directory"
  echo "v - List the files in f (or current directory) instead of the directory itself"
}

while getopts 'vf:' flag; do
  case "${flag}" in
    f) file=$(readlink -f "${OPTARG}") ;;
    v) verbose=true ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [ "$verbose" = true ]; then
    if [[ -d ${file} ]]; then
      du -sh "${file}"/* | sort -h | sed -r 's/\/\//\//g'
    else
      du -sh "${file}" | sed -r 's/\/\//\//g'
    fi
else
  du -sh "${file}" | sed -r 's/\/\//\//g'
fi
