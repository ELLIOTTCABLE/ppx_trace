(lang dune 3.6)

(name ppx_trace)

(generate_opam_files true)

(source
 (github ELLIOTTCABLE/ppx_trace))

(authors "ELLIOTTCABLE")

(license LICENSE)

(package
 (name ppx_trace)
 (synopsis "Tracing & telemetry syntax extension")
 (depends
  (ocaml
   (>= 4.08))
  ppxlib
  (alcotest :with-test)
  (ocamlformat
   (and
    :with-test
    (>= 0.24)
    (< 0.25)))))
