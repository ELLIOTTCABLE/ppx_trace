#!/usr/bin/env dash

# Build and execute the ppx against an input file, displaying the generated output on stdout.
#
#     ./pp.sh --impl test/test_trace_expression.ml

realpath() { echo "$(
   cd "$(dirname "$1")" || return
   pwd
)/$(basename "$1")"; }

type="$1"
shift
filename="$(realpath "$1")"
shift

output="${filename%.ml}.pp.ml"

case "$type" in
"--impl" | "--intf")
   opam exec --sw=. -- \
      dune exec --display=quiet test/errors/bin/pp.exe -- "$type" "$filename" "$@" |
      ocamlformat "$type" - >"$output" &&
      patdiff "$filename" "$output"
   ;;
*)
   printf "%s\n" "First argument must be either --impl or --intf" >&2
   exit 1
   ;;
esac
