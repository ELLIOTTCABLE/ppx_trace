open Ppxlib

let structure_item_ext =
   let ext =
      Extension.V3.declare_with_path_arg "span" Extension.Context.structure_item
        Ast_pattern.(pstr (pstr_value __ __ ^:: nil))
        Ppx_trace_expander.expand_structure_item
   in
   Context_free.Rule.extension ext


let expression_ext =
   let ext =
      Extension.V3.declare_with_path_arg "span" Extension.Context.expression
        Ast_pattern.(single_expr_payload __)
        Ppx_trace_expander.expand_expression
   in
   Context_free.Rule.extension ext


let () =
   Driver.register_transformation "ppx_trace"
     ~enclose_impl:Ppx_trace_expander.enclose_impl
     ~rules:[ structure_item_ext; expression_ext ]
