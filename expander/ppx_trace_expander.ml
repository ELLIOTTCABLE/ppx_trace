open Ppxlib
open Ast_builder.Default

let pexp_let ~loc rec_ bindings e =
   match bindings with
   | [] -> e
   | _ :: _ -> pexp_let ~loc rec_ bindings e


let oops ~loc desc =
   Location.error_extensionf ~loc
     "[ppx_trace] %s (please report this, with source code, to ELLIOTTCABLE)" desc


let pexp_oops ~loc x = pexp_extension ~loc @@ oops ~loc x
let ppat_oops ~loc x = ppat_extension ~loc @@ oops ~loc x
let trace_syntax = "Trace_syntax"

let trace_syntax ~modul : Longident.t =
   match modul with
   | None -> Lident trace_syntax
   | Some id -> Ldot (Ldot (id.Location.txt, trace_syntax), trace_syntax)


let eoperator ~loc ~modul func =
   let lid : Longident.t = Ldot (trace_syntax ~modul, func) in
   pexp_ident ~loc (Located.mk ~loc lid)


let qualified_span ~modul ?(name_label = "name") ~(name : expression) (body : expression)
    =
   let loc = { body.pexp_loc with loc_ghost = true } in
   let thunk = [%expr fun () -> [%e body]] in
   pexp_apply ~loc
     (eoperator ~loc ~modul "span")
     [ (Labelled name_label, name); (Nolabel, thunk) ]


let rec replace_nested_pexpr (expr : expression) (f : expression -> expression) =
   match expr.pexp_desc with
   | Pexp_fun (lbl, exp0, p, e1) ->
       { expr with pexp_desc = Pexp_fun (lbl, exp0, p, replace_nested_pexpr e1 f) }
   | _ -> f expr


let expand_let ~loc ~modul _rec orig_bindings body =
   if List.length orig_bindings = 0 then
     invalid_arg "expand_let: list of bindings must be non-empty" ;
   let bindings =
      orig_bindings
      |> List.map (fun ({ pvb_pat = pat; pvb_expr = body; _ } as pvb) ->
             match pat.ppat_desc with
             | Ppat_var ident | Ppat_alias (_, ident) ->
                 let name_str : string = ident.txt in
                 let name_expr =
                    pexp_constant ~loc @@ Pconst_string (name_str, loc, None)
                 in
                 let body =
                    replace_nested_pexpr body (fun expr ->
                        qualified_span ~modul ~name:name_expr expr)
                 in
                 { pvb with pvb_expr = body }
             | _ ->
                 { pvb with pvb_pat = ppat_oops ~loc:pat.ppat_loc "unsupported pattern" })
   in
   pexp_let ~loc _rec bindings body


let expand_expression ~modul expr =
   let loc = { expr.pexp_loc with loc_ghost = true } in
   let expansion =
      match expr.pexp_desc with
      | Pexp_let (_rec, bindings, expr) -> expand_let ~loc ~modul _rec bindings expr
      | _ -> pexp_oops ~loc "'%%span' can only be used with 'let'"
   in

   { expansion with pexp_attributes = expr.pexp_attributes @ expansion.pexp_attributes }
