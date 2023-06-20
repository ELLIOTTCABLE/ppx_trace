open Alcotest

module Trace_syntax = struct
  let span ~name f =
     let ret = f () in
     String.concat " " [ ret; "-"; name; "got wrapped btw" ]
end

let test_expression_simple =
   test_case "Simple function" `Quick (fun () ->
       let%span greet name = "Hi there, " ^ name in
       (check string) "got wrapped" "Hi there, ec - greet got wrapped btw" (greet "ec"))


let test_expression_multiple =
   test_case "Simple function" `Quick (fun () ->
       let%span greet first last = String.concat " " [ "Hi there,"; first; last ] in
       (check string) "got wrapped" "Hi there, Elliott Cable - greet got wrapped btw"
         (greet "Elliott" "Cable"))


let tests = [ ("expression", [ test_expression_simple; test_expression_multiple ]) ]

let run () =
   let open Alcotest in
   run "Correct usage" tests
