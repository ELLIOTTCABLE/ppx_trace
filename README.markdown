ppx_trace
=========

Work in progress. A ppx rewriter to quickly wrap entire functions in a tracing callback, for use with [ocaml-opentelemetry][], [trace][], etc.

   [ocaml-opentelemetry]: <https://github.com/imandra-ai/ocaml-opentelemetry>
   [trace]: <https://github.com/c-cube/trace>

### Contributing

Install deps:

```console
$ opam install . --deps-only --with-test
```

Build:

```console
$ dune build
```

Test:

```console
$ dune build @runtest
```

Experiment manually:

```console
$ ./pp.sh --impl test/test_trace_expression.ml
```
