(*[Mo]Module contenaing the messages of Biniki .[Mo]*)

let logiciel = "Biniki";;
let version = "1.0";;

let module_version = version;;
let module_name = logiciel;;
let module_author = "Maxence Guesdon";;
let mVersion = "Module "^module_name^" version "^module_version^" par "^module_author;;

let mUsage = "Usage : "^Sys.argv.(0)^" <base> [<utilisateur> [<mot de passe>]]\n";;
let mAbout = logiciel^" "^version^" : \n\nCopyright (c) 2001 par "^module_author^"\nhttp://maxence.guesdon.free.fr\nmax@sbuilders.com\n\nDistribué sous licence GPL.";;
let mErreur = "Erreur";;

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
let mCancel = "Annuler";;
let mWarning = "Attention ! ";;
let mExecute = "Exécuter";;

let m0 = "Erreur inconnue";;

(* menus labels *)
let mn1 = "Fichier";;
let mn2 = "Fermer";;
let mn3 = "?";;
let mn4 = "A propos";;
