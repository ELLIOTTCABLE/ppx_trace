open Alcotest

module Trace_unqualified_name = struct
  module Trace_syntax = struct
    type code_path = {
       file_path : string;
       main_module_name : string;
       submodule_path : string list;
       enclosing_module : string;
       enclosing_value : string option;
       value : string option;
     }

    let span ~name ~code_path:_ ?stdlib_name:_ f =
       let ret = f () in
       String.concat " " [ ret; "-"; name; "got wrapped btw" ]
  end
end

let test_stri_simple =
   let open Trace_unqualified_name in
   test_case "Simple func" `Quick (fun () ->
       let module Sth = struct
         let%span greet name = "Hi there, " ^ name
       end in
       (check string) "got wrapped" "Hi there, ec - greet got wrapped btw"
         (Sth.greet "ec"))


let test_stri_multiple =
   test_case "Simple func (multiple params)" `Quick (fun () ->
       let open Trace_unqualified_name in
       let module Sth = struct
         let%span greet2 first last = String.concat " " [ "Hi there,"; first; last ]
       end in
       (check string) "got wrapped" "Hi there, Elliott Cable - greet2 got wrapped btw"
         (Sth.greet2 "Elliott" "Cable"))


module Trace_code_path = struct
  module Trace_syntax = struct
    type code_path = {
       file_path : string;
       main_module_name : string;
       submodule_path : string list;
       enclosing_module : string;
       enclosing_value : string option;
       value : string option;
     }

    let fully_qualified_path ~name cp =
       let names = (cp.main_module_name :: cp.submodule_path) @ [ name ] in
       String.concat "." @@ names


    let span ~name ~code_path ?stdlib_name:_ f =
       let ret = f () in
       String.concat " "
         [ ret; "-"; fully_qualified_path ~name code_path; "got wrapped btw" ]
  end
end

module Test_code_path = struct
  module Widget = struct
    let test =
       let open Trace_code_path in
       test_case "Simple func (code path struct)" `Quick (fun () ->
           let module Sth = struct
             let%span greet name = "Hi there, " ^ name
           end in
           (check string) "got wrapped"
             "Hi there, ec - Test_trace_structure_item.Test_code_path.Widget.greet got \
              wrapped btw"
             (Sth.greet "ec"))
  end
end

module Trace_stdlib_name = struct
  module Trace_syntax = struct
    type code_path = {
       file_path : string;
       main_module_name : string;
       submodule_path : string list;
       enclosing_module : string;
       enclosing_value : string option;
       value : string option;
     }

    let span ~name:_ ~code_path:_ ?(stdlib_name = "UNSUPPORTED") f =
       let ret = f () in
       String.concat " " [ ret; "-"; stdlib_name; "got wrapped btw" ]
  end
end

module Test_stdlib_name = struct
  module Widget = struct
    let test =
       let open Trace_stdlib_name in
       test_case "Simple func (stdlib name)" `Quick (fun () ->
           let module Sth = struct
             let%span greet name = "Hi there, " ^ name
           end in
           (check string) "got wrapped"
             "Hi there, ec - \
              Dune__exe__Test_trace_structure_item.Test_stdlib_name.Widget.test.(fun).Sth.greet \
              got wrapped btw"
             (Sth.greet "ec"))
  end
end

module Trace_with_submodule_specifier = struct
  module A = struct
    module Submodule = struct
      module Trace_syntax = struct
        module Trace_syntax = struct
          type code_path = {
             file_path : string;
             main_module_name : string;
             submodule_path : string list;
             enclosing_module : string;
             enclosing_value : string option;
             value : string option;
           }

          let span ~name ~code_path:_ ?stdlib_name:_ f =
             let ret = f () in
             String.concat " "
               [ ret; "-"; name; "got wrapped by the correct function in A.Submodule" ]
        end
      end
    end
  end
end

let test_with_submodule_specifier =
   let open Trace_with_submodule_specifier in
   test_case "Simple func (with module spec)" `Quick (fun () ->
       let module Sth = struct
         let%span.A.Submodule greet name = "Hi there, " ^ name
       end in
       (check string) "got wrapped"
         "Hi there, ec - greet got wrapped by the correct function in A.Submodule"
         (Sth.greet "ec"))


let tests =
   [
     ( "structure item",
       [
         test_stri_simple;
         test_stri_multiple;
         Test_code_path.Widget.test;
         Test_stdlib_name.Widget.test;
         test_with_submodule_specifier;
       ] );
   ]
