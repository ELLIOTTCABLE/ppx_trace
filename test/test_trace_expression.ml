[@@@warning "-26"]

module Trace_syntax = struct
  let span ~name f =
     let ret = f () in
     String.concat " " [ ret; "-"; name; "got wrapped btw" ]
end

let test_expression () =
   let%span greet name = "Hi there, " ^ name in
   Alcotest.(check string)
     "got wrapped" "Hi there, ec - greet got wrapped btw" (greet "ec")


let tests = Alcotest.[ ("expression", [ test_case "Expression" `Quick test_expression ]) ]

let run () =
   let open Alcotest in
   run "Correct usage" tests
