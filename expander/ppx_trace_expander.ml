module Cp = Code_path
open Ppxlib
module Code_path = Cp
open Ast_builder.Default

let pexp_let ~loc rec_ bindings e =
   match bindings with
   | [] -> e
   | _ :: _ -> pexp_let ~loc rec_ bindings e


let oops ~loc desc =
   Location.error_extensionf ~loc
     "[ppx_trace] %s (please report this, with source code, to ELLIOTTCABLE)" desc


let pstr_oops ~loc x = pstr_extension ~loc @@ oops ~loc x
let pexp_oops ~loc x = pexp_extension ~loc @@ oops ~loc x
let ppat_oops ~loc x = ppat_extension ~loc @@ oops ~loc x
let trace_syntax = "Trace_syntax"

let trace_syntax ~modul : Longident.t =
   match modul with
   | None -> Lident trace_syntax
   | Some id -> Ldot (Ldot (id.Location.txt, trace_syntax), trace_syntax)


let ptyp_constr ~loc lid =
   let loc = { loc with loc_ghost = true } in
   ptyp_constr ~loc (Located.mk ~loc @@ lid) []


let span_sig ~loc ~modul ?(name_label = "name") ?(code_path_label = "code_path")
    ?(stdlib_name_label = "stdlib_name") () =
   let loc = { loc with loc_ghost = true } in
   let lstr label next ~optional =
      ptyp_arrow
        (if optional then Optional label else Labelled label)
        (ptyp_constr ~loc @@ Lident "string")
        ~loc next
   in
   let lcode_path label next =
      ptyp_arrow (Labelled label)
        (ptyp_constr ~loc @@ Ldot (modul, "code_path"))
        ~loc next
   in
   lstr name_label ~optional:false
   @@ lcode_path code_path_label
   @@ lstr stdlib_name_label ~optional:true
   @@ [%type: (unit -> 'ret) -> 'ret]


let trace_syntax_sig ~loc =
   let loc = { loc with loc_ghost = true } in
   [%stri
      module type PPX_TRACE_INTERNAL__TRACE_SYNTAX_SIG__ = sig
        [%%i Code_path.signature_item ~loc]
      end]


let internal_mod = "Ppx_trace_internal__Trace_syntax__"
let internal_mod_sig = "PPX_TRACE_INTERNAL__TRACE_SYNTAX_SIG__"
let major, minor = Scanf.sscanf Sys.ocaml_version "%d.%d" (fun x y -> (x, y))
let gte412 = major >= 4 && minor >= 12

let enclose_impl whole_loc : structure_item list * structure_item list =
   match whole_loc with
   | None -> ([], [])
   | Some loc ->
       let loc = { loc with loc_ghost = true } in
       let header =
          [%stri
             open struct
               [%%i trace_syntax_sig ~loc]
             end]
       in
       ([ header ], [])


let __function__ ~loc () =
   let loc = { loc with loc_ghost = true } in
   evar ~loc "Stdlib.__FUNCTION__"


let assert_module_sig ~loc ~(modul : longident) ~(sig_ : longident) expr =
   let loc = { loc with loc_ghost = true } in
   pexp_letmodule ~loc
     (Located.mk ~loc (Some internal_mod))
     (pmod_constraint ~loc
        (pmod_ident ~loc @@ Located.mk ~loc modul)
        (pmty_ident ~loc @@ Located.mk ~loc sig_))
     expr


let qualified_span ~modul ?(name_label = "name") ?(code_path_label = "code_path")
    ?(stdlib_name_label = "stdlib_name") ~(name : expression) ~(code_path : expression)
    (body : expression) =
   let loc = { body.pexp_loc with loc_ghost = true } in
   let thunk = [%expr fun () -> [%e body]] in
   let constrained_ident =
      pexp_constraint ~loc
        (pexp_ident ~loc @@ Located.mk ~loc @@ Ldot (modul, "span"))
        (span_sig ~loc ~modul ~name_label ~code_path_label ~stdlib_name_label ())
   in
   let expressions =
      if gte412 then
        [
          (Labelled name_label, name);
          (Labelled code_path_label, code_path);
          (Optional stdlib_name_label, __function__ ~loc ());
          (Nolabel, thunk);
        ]
      else
        [
          (Labelled name_label, name);
          (Labelled code_path_label, code_path);
          (Nolabel, thunk);
        ]
   in
   pexp_apply ~loc constrained_ident expressions


let rec replace_nested_pexpr (expr : expression) (f : expression -> expression) =
   match expr.pexp_desc with
   | Pexp_fun (lbl, exp0, p, e1) ->
       { expr with pexp_desc = Pexp_fun (lbl, exp0, p, replace_nested_pexpr e1 f) }
   | _ -> f expr


let expand_bindings ~loc ~code_path ~modul orig_bindings =
   let modul = trace_syntax ~modul in
   let code_path = Code_path.of_ppxlib_code_path code_path in
   if List.length orig_bindings = 0 then
     invalid_arg "expand_let: list of bindings must be non-empty" ;
   orig_bindings
   |> List.map (fun ({ pvb_pat = pat; pvb_expr = body; _ } as pvb) ->
          match pat.ppat_desc with
          | Ppat_var ident | Ppat_alias (_, ident) ->
              let name_str : string = ident.txt in
              let name_expr = pexp_constant ~loc @@ Pconst_string (name_str, loc, None) in
              let code_path_expr =
                 Code_path.to_inline_record ~loc ~within:modul code_path
              in
              let body =
                 replace_nested_pexpr body (fun expr ->
                     assert_module_sig ~loc ~modul ~sig_:(Lident internal_mod_sig)
                     @@ qualified_span ~modul ~name:name_expr ~code_path:code_path_expr
                          expr)
              in
              { pvb with pvb_expr = body }
          | _ -> { pvb with pvb_pat = ppat_oops ~loc:pat.ppat_loc "unsupported pattern" })


let expand_structure_item ~(ctxt : Expansion_context.Extension.t) ~arg:modul _rec bindings
    =
   let loc = Expansion_context.Extension.extension_point_loc ctxt in
   let code_path = Expansion_context.Extension.code_path ctxt in
   let bindings = expand_bindings ~code_path ~loc ~modul bindings in
   pstr_value ~loc _rec bindings


let expand_expression ~(ctxt : Expansion_context.Extension.t) ~arg:modul expr =
   let loc = { expr.pexp_loc with loc_ghost = true } in
   let code_path = Expansion_context.Extension.code_path ctxt in
   let expansion =
      match expr.pexp_desc with
      | Pexp_let (_rec, bindings, body) ->
          let bindings = expand_bindings ~loc ~code_path ~modul bindings in
          pexp_let ~loc _rec bindings body
      | _ -> pexp_oops ~loc "'%%span' can only be used with 'let'"
   in

   { expansion with pexp_attributes = expr.pexp_attributes @ expansion.pexp_attributes }
