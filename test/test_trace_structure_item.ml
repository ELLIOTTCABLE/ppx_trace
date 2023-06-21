open Alcotest

module Trace_string_name = struct
  module Trace_syntax = struct
    let span ~name ~full_name:_ f =
       let ret = f () in
       String.concat " " [ ret; "-"; name; "got wrapped btw" ]
  end
end

let test_stri_simple =
   let open Trace_string_name in
   test_case "Simple function" `Quick (fun () ->
       let module Sth = struct
         let%span greet name = "Hi there, " ^ name
       end in
       (check string) "got wrapped" "Hi there, ec - greet got wrapped btw"
         (Sth.greet "ec"))


let test_stri_multiple =
   test_case "Simple function" `Quick (fun () ->
       let open Trace_string_name in
       let%span greet2 first last = String.concat " " [ "Hi there,"; first; last ] in
       (check string) "got wrapped" "Hi there, Elliott Cable - greet2 got wrapped btw"
         (greet2 "Elliott" "Cable"))


module Trace_string_full_name = struct
  module Trace_syntax = struct
    let span ~name:_ ~full_name f =
       let ret = f () in
       String.concat " " [ ret; "-"; full_name; "got wrapped btw" ]
  end
end

module Test_full_name = struct
  module Sth = struct
    let test_stri_full_name =
       let open Trace_string_full_name in
       test_case "Simple function (full name)" `Quick (fun () ->
           let%span greet name = "Hi there, " ^ name in
           (check string) "got wrapped"
             "Hi there, ec - \
              Dune__exe__Test_trace_structure_item.Test_full_name.Sth.test_stri_full_name.(fun).greet \
              got wrapped btw"
             (greet "ec"))
  end
end

let tests =
   [
     ( "structure item",
       [ test_stri_simple; test_stri_multiple; Test_full_name.Sth.test_stri_full_name ] );
   ]
