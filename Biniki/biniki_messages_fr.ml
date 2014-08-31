(****************************************************************************)
(*             OCamlODBC                                                    *)
(*                                                                          *)
(* Copyright (C) 2004-2011 Institut National de Recherche en Informatique   *)
(* et en Automatique. All rights reserved.                                  *)
(*                                                                          *)
(* This program is free software; you can redistribute it and/or modify     *)
(* it under the terms of the GNU General Public License as published        *)
(* by the Free Software Foundation; either version 2.1 of the License, or   *)
(* any later version.                                                       *)
(*                                                                          *)
(* This program is distributed in the hope that it will be useful,          *)
(* but WITHOUT ANY WARRANTY; without even the implied warranty of           *)
(* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            *)
(* GNU Lesser General Public License for more details.                      *)
(*                                                                          *)
(* You should have received a copy of the GNU General Public License        *)
(* along with this program; if not, write to the Free Software              *)
(* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                 *)
(* 02111-1307  USA                                                          *)
(*                                                                          *)
(* Contact: Maxence.Guesdon@inria.fr                                        *)
(*                                                                          *)
(****************************************************************************)

(*[Mo]Module contenaing the messages of Biniki .[Mo]*)

let logiciel = "Biniki";;
let version = "1.0";;

let module_version = version;;
let module_name = logiciel;;
let module_author = "Maxence Guesdon";;
let mVersion = "Module "^module_name^" version "^module_version
               ^ " par " ^ module_author;;

let mUsage =
  "Usage : "^Sys.argv.(0)^" <base> [<utilisateur> [<mot de passe>]]\n";;
let mAbout =
  logiciel^" "^version^" : \n\nCopyright (c) 2001 par "
  ^module_author
  ^"\nhttp://maxence.guesdon.free.fr\nmax@sbuilders.com\n\n\
    Distribué sous licence GPL.";;
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
