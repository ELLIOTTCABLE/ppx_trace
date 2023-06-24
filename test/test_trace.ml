open Alcotest

let () = Test_basic.run ()

let () =
   let tests =
      List.flatten [ Test_trace_expression.tests; Test_trace_structure_item.tests ]
   in
   run "Correct usage" tests
