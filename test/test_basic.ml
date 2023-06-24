module Trace_syntax = struct
  type code_path = {
     file_path : string;
     main_module_name : string;
     submodule_path : string list;
     enclosing_module : string;
     enclosing_value : string option;
     value : string option;
   }

  let span ~name ~code_path:_ ~stdlib_name:_ f =
     let ret = f () in
     String.concat " " [ ret; "-"; name; "got wrapped btw" ]
end

let%span greet name = "Hello, " ^ name ^ "!"

let run () = ()
