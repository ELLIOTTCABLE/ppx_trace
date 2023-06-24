type 'a loc = { txt : 'a; loc : Location.t }

type t = {
   file_path : string;
   main_module_name : string;
   submodule_path : string list;
   enclosing_module : string;
   enclosing_value : string option;
   value : string option;
 }

let signature_item ~loc =
   [%sigi:
      type code_path = {
         file_path : string;
         main_module_name : string;
         submodule_path : string list;
         enclosing_module : string;
         enclosing_value : string option;
         value : string option;
       }]


let of_ppxlib_code_path (pc : Ppxlib.Code_path.t) : t =
   {
     file_path = Ppxlib.Code_path.file_path pc;
     main_module_name = Ppxlib.Code_path.main_module_name pc;
     submodule_path = Ppxlib.Code_path.submodule_path pc;
     enclosing_module = Ppxlib.Code_path.enclosing_module pc;
     enclosing_value = Ppxlib.Code_path.enclosing_value pc;
     value = Ppxlib.Code_path.value pc;
   }


include struct
  open Ppxlib

  let eoption ~loc f v =
     match v with
     | None -> [%expr None]
     | Some v -> [%expr Some [%e f v]]


  let to_inline_record ~loc ?within t =
     let loc = { loc with loc_ghost = true } in
     let open Ast_builder.Default in
     let rec_expr =
        [%expr
           {
             file_path = [%e estring ~loc t.file_path];
             main_module_name = [%e estring ~loc t.main_module_name];
             submodule_path = [%e elist ~loc (List.map (estring ~loc) t.submodule_path)];
             enclosing_module = [%e estring ~loc t.enclosing_module];
             enclosing_value = [%e eoption ~loc (estring ~loc) t.enclosing_value];
             value = [%e eoption ~loc (estring ~loc) t.value];
           }]
     in
     match within with
     | None -> rec_expr
     | Some within ->
         let module_expr = pmod_ident ~loc (Located.mk ~loc within) in
         pexp_open ~loc (open_infos ~loc ~expr:module_expr ~override:Fresh) rec_expr
end
