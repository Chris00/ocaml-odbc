(*[Mo] This is the main module of Biniki. [Mo]*)

let base = 
  try Sys.argv.(1)
  with _ ->
    output_string stderr Biniki_messages.mUsage;
    exit 1

let user =
  try Sys.argv.(2)
  with _ -> Biniki_messages.login

let passwd = 
  try Sys.argv.(3)
  with _ -> ""

(* create a database object *)
let db = new Ocamlodbc.data_base base user passwd

(* connect to data base *)
let _ =
  try db#connect ()
  with Ocamlodbc.SQL_Error s ->
    output_string stderr (s^"\n");
    exit 2

(* create a context object *)
let context = new Biniki_context.context base db

(* create the first window ; this function returns when all
   windows are closed, not only the first one created.*)
let _ = Biniki_window.window context ()

(* disconnect from data base *)
let _ =
  try db#disconnect ()
  with Ocamlodbc.SQL_Error s ->
    output_string stderr (s^"\n");
    exit 3
