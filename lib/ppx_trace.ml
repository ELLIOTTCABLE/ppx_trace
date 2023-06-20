open Ppxlib

[@@@warning "-21"]

(* let structure_item_ext = Context_free.Rule.extension @@ Extension.declare_with_path_arg
   "span" Extension.Context.structure_item Ast_pattern.(single_expr_payload __) (fun
   ~loc:_ ~path:_ ~arg expr -> Ppx_trace_expander.expand_structure_item ~modul:arg
   expr) *)

let expression_ext =
   Context_free.Rule.extension
   @@ Extension.declare_with_path_arg "span" Extension.Context.expression
        Ast_pattern.(single_expr_payload __)
        (fun ~loc:_ ~path:_ ~arg expr ->
          Ppx_trace_expander.expand_expression ~modul:arg expr)


let () =
   Driver.register_transformation "ppx_trace"
     ~rules:[ (* structure_item_ext; *) expression_ext ]
