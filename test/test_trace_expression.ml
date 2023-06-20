[@@@warning "-26"]

module Trace_syntax = struct
  let span ~name f =
     let open Printf in
     printf "%s started\n" name ;
     let ret = f () in
     printf "%s ended\n" name ;
     ret
end

let () =
   let%span some_func abc _def = abc + 123 and widget _bleh = 354 in
   print_endline @@ string_of_int (some_func 1 "ignored")


let run () = ()
