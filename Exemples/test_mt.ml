(*********************************************************************************)
(*                OCamlODBC                                                         *)
(*                                                                               *)
(*    Copyright (C) 2004 Institut National de Recherche en Informatique et       *)
(*    en Automatique. All rights reserved.                                       *)
(*                                                                               *)
(*    This program is free software; you can redistribute it and/or modify       *)
(*    it under the terms of the GNU General Public License as published          *)
(*    by the Free Software Foundation; either version 2.1 of the License, or     *)
(*    any later version.                                                         *)
(*                                                                               *)
(*    This program is distributed in the hope that it will be useful,            *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of             *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *)
(*    GNU Lesser General Public License for more details.                        *)
(*                                                                               *)
(*    You should have received a copy of the GNU General Public License          *)
(*    along with this program; if not, write to the Free Software                *)
(*    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   *)
(*    02111-1307  USA                                                            *)
(*                                                                               *)
(*    Contact: Maxence.Guesdon@inria.fr                                          *)
(*                                                                               *)
(*********************************************************************************)

open Ocamlodbc


let string_of_opt = function
  None -> "<NULL>"
| Some s -> s

let affiche iRC result =
  if iRC = 0
  then
    (
     print_newline();
     begin
       let p_row row = (List.iter (function s -> print_string ((string_of_opt s)^" ")) row) in
       let p_rows rows = (List.iter (function row -> p_row row; print_newline()) rows) in
       begin
      	 print_string "Resultats :\n";
      	 p_rows result;
      	 print_newline()
       end;
     end
    )
  else
    print_int iRC
;;

let usage = Sys.argv.(0) ^ " database user [password]"

let tab = Sys.argv
let (pszDB, pszUser) =
  try tab.(1), tab.(2)
  with _ -> prerr_endline usage ; exit 1


let pszPassword = if (Array.length tab) < 4 then  "" else tab.(3) ;;

let main () =
  let id = try Thread.id (Thread.self ()) with _ -> 0 in
  print_string ("Thread "^(string_of_int id)^" created!");
  print_newline ();

  (* Affichage paramètre base *)
  print_string ("nom base : "^pszDB^"\n");
  print_string ("nom util : "^pszUser^"\n");
  print_string ("passwd   : "^pszPassword);
  print_newline ();

  (* Connection *)
  let connection =
    try connect pszDB pszUser pszPassword
    with SQL_Error(s) -> print_string s; print_newline() ; exit 1
  in

  let req_create = "create table base_test (cle integer)" in
  let _ = execute connection req_create in
  let req_insert i = "insert into base_test (cle) values ("^(string_of_int i)^")" in
  for i = 1 to 10000 do
    let _ = execute connection (req_insert i) in
    ()
  done;
  print_string ("Thread "^(string_of_int id)^" finished insertions!");
  print_newline ();
  let req_select i =
    let i = 100 in
    "select * from base_test where cle > "^(string_of_int i)^" and cle < "^(string_of_int (i+100))
  in

  for i = 1 to 3000 do
    let (a,_,c) = execute_with_info connection (req_select i) in
    affiche a c
  done;

(*
  let req_destroy = "drop table base_test" in
  let _ = execute connection req_destroy in
*)
  disconnect connection;
  print_string ("Thread "^(string_of_int id)^" terminated!");
  print_newline ()
;;


try
  for i = 1 to 4 do
    let t = Thread.create main () in
    print_string "One thread created.";
    print_newline ();
  done;
  let _ = read_line () in
  ()

with
  SQL_Error(s) -> print_string s; print_newline()
| _ -> print_string "Erreur inconnue.\n"
;;


