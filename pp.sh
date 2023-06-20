#!/usr/bin/env dash

# Build and execute the ppx against an input file, displaying the generated output on stdout.
#
#     ./pp.sh --impl test/test_trace_expression.ml

type="$1"
shift
case "$type" in
"--impl" | "--intf")
   opam exec --sw=. -- \
      dune exec --display=quiet test/errors/bin/pp.exe -- "$type" "$@" |
      ocamlformat "$type" -
   ;;
*)
   printf "%s\n" "First argument must be either --impl or --intf" >&2
   exit 1
   ;;
esac
