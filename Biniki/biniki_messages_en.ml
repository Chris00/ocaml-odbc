(*[Mo]Module contenaing the messages of Biniki .[Mo]*)

let logiciel = "Biniki";;
let version = "1.0";;

let module_version = version;;
let module_name = logiciel;;
let module_author = "Maxence Guesdon";;
let mVersion = "Module "^module_name^" version "^module_version^" by "^module_author;;

let mUsage = "Usage : "^Sys.argv.(0)^" <base> [<user> [<password>]]\n";;
let mAbout = logiciel^" "^version^" : \n\nCopyright (c) 2001 by "^module_author^"\nhttp://maxence.guesdon.free.fr\nmax@sbuilders.com\n\nDistributed under license GPL.";;
let mErreur = "Error";;

let history_file = ".biniki";;

let home = Sys.getenv "HOME";;
let login =
  try
    Unix.getlogin ()
  with
  |  _ -> (* we get the basename of the $HOME directory *)
      Filename.basename home
;;

let mOk = "Ok";;
let mCancel = "Cancel";;
let mWarning = "Warning ! ";;
let mExecute = "Execute";;

let m0 = "Unknown error";;

(* menus labels *)
let mn1 = "File";;
let mn2 = "Close";;
let mn3 = "?";;
let mn4 = "About ...";;
