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

let usage = Sys.argv.(0) ^ " database user [password]"

let main () =
  let (pszDB, pszUser) =
    try Sys.argv.(1), Sys.argv.(2)
    with _ -> prerr_endline usage; exit 1
  and pszPassword = try Sys.argv.(3) with _ -> "" in

  (* Affichage parametre base *)
  print_string ("database : " ^ pszDB ^ "\n");
  print_string ("user     : " ^ pszUser ^ "\n");
  print_string ("password : " ^ pszPassword ^ "\n");

  (* Creation instance de la base *)
  let db = new data_base pszDB pszUser pszPassword in

  (* Initialisation de la base *)
  db#connect() ;

  (* Boucle infinie de traitement *)
  let sortie = ref false and str = ref "" in
  while not(!sortie = true) do
    begin
      print_string "»»» ";
      str := read_line ();
      if !str = "" then (
	sortie := true;
      )
      else (
	let (iRC, l_nom_type, result) = db#execute_with_info !str in
	if iRC = 0 then (
    	  let p_col row =
	    let print (s,col_type) =
	      print_string(s^" : "^(SQL_column.string col_type)^"\n") in
	    List.iter print row in
    	 print_string "Columns : \n";
    	 p_col l_nom_type;
    	 print_newline();
    	 print_newline();
         let p_row row = List.iter (function s -> print_string (s^" ")) row in
         let p_rows rows =
	   List.iter (function row -> p_row row; print_newline()) rows in
	 print_string "Results :\n";
         p_rows result;
	 print_newline()
	)
	else (
          print_int iRC; print_newline()
	)
      )
    end
  done;
  db#disconnect()


let () =
  try main()
  with
  | SQL_Error(s) -> print_string s; print_newline()
  | e -> prerr_endline(Printexc.to_string e)
