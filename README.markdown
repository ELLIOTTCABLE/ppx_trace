ppx_trace
=========

This is a preprocessing transformer ([ppx][]) for OCaml projects that allows you to wrap functions in debugging and tracing metadata, without additional boilerplate at every callsite. This is largely intended for use with a pervasive tracing and debugging implementation such as [ocaml-opentelemetry][] or [trace][].

With `ppx_trace`, you can write:

```ocaml
module SomeComponent = struct
   let foo%span _arg =
      (* ... *)

   let bar%span _arg =
      (* ... *)

   let baz%span _arg =
      (* ... *)
end
```

... instead of verbosely annotating every function and manually duplicating names for tracing purposes:

```ocaml
module SomeComponent = struct
   let foo _arg =
      Dbg.trace ~name:"foo" ~file_name:__MODULE__ ~enclosing_module:"SomeComponent"
         ~module_path:Stdlib.__FUNCTION__ (fun () ->
            (* ... *)
         )

   let bar _arg =
      Dbg.trace ~name:"bar" ~file_name:__MODULE__ ~enclosing_module:"SomeComponent"
         ~module_path:Stdlib.__FUNCTION__ (fun () ->
            (* ... *)
         )

   let baz _arg =
      Dbg.trace ~name:"baz" ~file_name:__MODULE__ ~enclosing_module:"SomeComponent"
         ~module_path:Stdlib.__FUNCTION__ (fun () ->
            (* ... *)
         )
end
```

[ppx]: <https://ocaml.org/docs/metaprogramming> "OCaml.org - Preprocessors and metaprogramming"

[ocaml-opentelemetry]: <https://github.com/imandra-ai/ocaml-opentelemetry>
[trace]: <https://github.com/c-cube/trace>

Installation
------------

1. Install the `ppx_trace` package from opam in your project's [opam switch][]:

   ```console
   $ opam install ppx_trace
   ```

2. Add `ppx_trace` to either your [`dune-project` file][dune-project] ...

   ```diff
    ; dune-project
    (package
     (name my_package)
     (depends
      (ocaml
       (>= 4.08))
   +  ppx_trace
      (alcotest :with-test)))
   ```

   ... or, alternatively, to your manual `opam` file:

   ```diff
    # my_package.opam
    depends: [
      "ocaml" {>= "4.08"}
   +  "ppx_trace"
      "alcotest" {with-test}
    ]
   ```

3. Add `ppx_trace` to your `dune` build-instructions under the `preprocess` stanza:

   ```diff
    ; src/dune
    (test

     (name my_package_lib)
   + (preprocess
   +  (pps ppx_trace))
     (libraries alcotest))


[opam switch]: <https://opam.ocaml.org/doc/man/opam-switch.html> "Opam manaul: opam-switch"
[dune-project]: <https://dune.readthedocs.io/en/stable/howto/opam-file-generation.html> "Dune manual: generating Opam files from dune-project"

Usage
-----

The extension-point for `ppx_trace` is `let%span`; which is supported on two syntactic forms:

1. "Top-level" functions in a module (known as 'structure items'), e.g.

   ```ocaml
   let toplevel_func%span one two =
      (* ... *)

   module Functionality = struct
      let submodule_func%span arg =
         (* ... *)
   end
   ```

2. `let%span ... in` at the expression level, e.g.

   ```ocaml
   let run () =
      (* ... *)
      let%span callback arg =
         (* ... *)
      in
      do_thing abc def callback

When transformed, `ppx_trace` will wrap the function body in a call to the `span` function, provided by a user-provided `Trace_syntax` module. This module should implement the following signature:

```ocaml
sig
   type code_path = {
      file_path : string;
      main_module_name : string;
      submodule_path : string list;
      enclosing_module : string;
      enclosing_value : string option;
      value : string option;
   }

   val span :
      name:string ->
      code_path:code_path ->
      stdlib_name:string ->
      (return -> 'ret) ->
      'ret
end
```

The `Trace_syntax.span` function is expected arguments, providing different ways to report on the instrumented function's location in the source code. For example, given the following `widget.ml` file:

```ocaml
(* src/widget.ml *)
module Trace_syntax = struct
  type code_path = { (* ... *) }

  let span ~name ~code_path ~stdlib_name f = (* ... *)
end

module Foo = struct
  module Bar = struct
    let%span some_func arg1 arg2 = (* ... *)
  end
end
```

... the `Trace_syntax.span` function will be called with the following arguments:

 - `~name` is the name of the binding being instrumented, e.g. `"some_func"`.
 - `~code_path` is a structured record of granular details (provided [by ppxlib][Ppxlib.Code_path]) about the source-code location, e.g.

   ```ocaml
   { file_path = "src/widget.ml" ; (* the path to the .ml file *)

     main_module_name = "Widget" ; (* the module name corresponding to the file *)
     submodule_path = ["Foo"; "Bar"] ; (* the path within the main module, represented as a list of
                                          toplevel-module names (does not descend into expressions) *)
     enclosing_module = Some "Bar" ; (* the nearest enclosing module name ({b does} descend into
                                        subexpressions!) *)
     enclosing_value = "None" ; (* the nearest enclosing value name, if in a subexpression *)
     value = "None" (* the name of the value to which this code path leads - often {b not} the same
                       as [~name] *) }
   ```

- `~stdlib_name` is the [value of `Stdlib.__FUNCTION__`][__FUNCTION__] at the point of instrumentation, for backwards compatibility; this often includes additional path-components, such as anonymous functions, invisible compilation units, etc, e.g. `"Dune__exe__Widget.Foo.Bar.run.X.some_func"`
- `f` is the function body, wrapped in a "thunk" (or unit-argument continuation), e.g. `fun () -> (* ... *)`

[Ppxlib.Code_path]: <https://ocaml.org/p/ppxlib/0.29.1/doc/Ppxlib/Code_path/index.html> "Code_path module documentation - ppxlib.0.29.1"
[__FUNCTION__]: <https://v2.ocaml.org/api/Stdlib.html#VAL__FUNCTION__> "Stdlib.__FUNCTION__ - OCaml Stdlib module documentation"



Contributing
------------

Install a local switch with deps:

```console
$ opam switch create . ocaml-base-compiler.4.14.0 --deps-only --no-install
$ opam install . --deps-only --with-test
```

Build:

```console
$ dune build
```

Run unit tests:

```console
$ dune build @runtest
```

Experiment manually with `./pp.sh`:

```console
$ ./pp.sh --impl test/test_basic.ml
------ /home/me/code/ppx_trace/test/test_basic.ml
++++++ /home/me/code/ppx_trace/test/test_basic.pp.ml
@|-1,18 +1,55 ============================================================
+|open struct
+|  module type PPX_TRACE_INTERNAL__TRACE_SYNTAX_SIG__ = sig
+|    type code_path = {
+|       file_path : string;
+|       main_module_name : string;
+|       submodule_path : string list;
+|       enclosing_module : string;
+|       enclosing_value : string option;
+|       value : string option;
+|     }
+|  end
+|end
+|
 |module Trace_syntax = struct
 |  type code_path = {
 |     file_path : string;
 |     main_module_name : string;
 |     submodule_path : string list;
 |     enclosing_module : string;
 |     enclosing_value : string option;
 |     value : string option;
 |   }
 |
 |  let span ~name ~code_path:_ ~stdlib_name:_ f =
 |     let ret = f () in
 |     String.concat " " [ ret; "-"; name; "got wrapped btw" ]
 |end
 |
-|let%span greet name = "Hello, " ^ name ^ "!"
+|let greet name =
+|   let module Ppx_trace_internal__Trace_syntax__ :
+|     PPX_TRACE_INTERNAL__TRACE_SYNTAX_SIG__ =
+|     Trace_syntax
+|   in
+|   (Trace_syntax.span
+|     : name:string ->
+|       code_path:Trace_syntax.code_path ->
+|       stdlib_name:string ->
+|       (unit -> 'ret) ->
+|       'ret)
+|     ~name:"greet"
+|     ~code_path:
+|       (let open Trace_syntax in
+|       {
+|         file_path = "/home/me/code/ppx_trace/test/test_basic.ml";
+|         main_module_name = "Test_basic";
+|         submodule_path = [];
+|         enclosing_module = "Test_basic";
+|         enclosing_value = None;
+|         value = None;
+|       })
+|     ~stdlib_name:Stdlib.__FUNCTION__
+|     (fun () -> "Hello, " ^ name ^ "!")
+|
 |
 |let run () = ()
```
