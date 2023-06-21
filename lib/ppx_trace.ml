open Ppxlib

let structure_item_ext =
   Context_free.Rule.extension
   @@ Extension.declare_with_path_arg "span" Extension.Context.structure_item
        Ast_pattern.(pstr (pstr_value __ __ ^:: nil))
        Ppx_trace_expander.expand_structure_item


let expression_ext =
   Context_free.Rule.extension
   @@ Extension.declare_with_path_arg "span" Extension.Context.expression
        Ast_pattern.(single_expr_payload __)
        Ppx_trace_expander.expand_expression


let () =
   Driver.register_transformation "ppx_trace"
     ~rules:[ structure_item_ext; expression_ext ]
