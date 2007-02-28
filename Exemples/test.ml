(****************************************************************************)
(*              OCamlODBC                                                   *)
(*                                                                          *)
(*  Copyright (C) 2004 Institut National de Recherche en Informatique et    *)
(*  en Automatique. All rights reserved.                                    *)
(*                                                                          *)
(*  This program is free software; you can redistribute it and/or modify    *)
(*  it under the terms of the GNU General Public License as published       *)
(*  by the Free Software Foundation; either version 2.1 of the License, or  *)
(*  any later version.                                                      *)
(*                                                                          *)
(*  This program is distributed in the hope that it will be useful,         *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of          *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           *)
(*  GNU Lesser General Public License for more details.                     *)
(*                                                                          *)
(*  You should have received a copy of the GNU General Public License       *)
(*  along with this program; if not, write to the Free Software             *)
(*  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                *)
(*  02111-1307  USA                                                         *)
(*                                                                          *)
(*  Contact: Maxence.Guesdon@inria.fr                                       *)
(*                                                                          *)
(****************************************************************************)

open Ocamlodbc

let string_of_opt = function
  None -> "<NULL>"
| Some s -> s

let affiche iRC result =
  if iRC = 0 then (
    print_newline();
    let p_row row = List.iter (function s -> print_string ((string_of_opt s)^" ")) row in
    let p_rows rows =
      List.iter (function row -> p_row row; print_newline()) rows in
    print_string "Resultats :\n";
    p_rows result;
    print_newline()
  )
  else (
    print_int iRC;
    print_newline()
  )


let usage = Sys.argv.(0) ^ " database user [password]"

let main () =
  let (pszDB, pszUser) =
    try Sys.argv.(1), Sys.argv.(2)
    with _ -> prerr_endline usage ; exit 1  in
  let pszPassword = if Array.length Sys.argv < 4 then  "" else Sys.argv.(3) in

  (* Affichage parametre base *)
  print_string ("nom base : " ^ pszDB ^ "\n");
  print_string ("nom util : " ^ pszUser ^ "\n");
  print_string ("passwd   : " ^ pszPassword ^ "\n");

  (* Connection *)
  let connection = connect pszDB pszUser pszPassword in

(*
  let (a1,b1,c1) = db#execute("select * from pet") in
  let (a2,b2,c2) = db#execute("select * from pet where sex = 1") in
  let (a3,b3,c3) = db#execute("select * from pet where species = \"dog\"") in
  let (a4,b4,c4) = db#execute("select name from pet where owner = \"lucky luke\"") in
  affiche a1 b1 c1;
  affiche a4 b4 c4;
  affiche a3 b3 c3;
  affiche a2 b2 c2;
*)
  let req_create = "create table base_test (cle integer)" in
  let _ = execute connection req_create in
  let req_insert i =
    "insert into base_test (cle) values ("^(string_of_int i)^")" in
  for i = 1 to 1500 do
    ignore(execute connection (req_insert i))
  done;
  let req_select i =
    "select * from base_test where cle > " ^ (string_of_int i)
    ^ " and cle < "^(string_of_int (i+100)) in
  for i = 1 to 1500 do
    let (a,c) = execute connection (req_select i) in
    affiche a c
  done;
  let req_destroy = "drop table base_test" in
  let _ = execute connection req_destroy in
  disconnect connection
;;


let () =
  try
    main();
    Unix.sleep(5)
  with
  | SQL_Error(s) -> print_string s; print_newline()
  | e -> prerr_endline(Printexc.to_string e)



