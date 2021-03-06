(*****************************************************************************)
(*             OCamlODBC                                                     *)
(*                                                                           *)
(* Copyright (C) 2004-2011 Institut National de Recherche en Informatique    *)
(* et en Automatique. All rights reserved.                                   *)
(*                                                                           *)
(* This program is free software; you can redistribute it and/or modify      *)
(* it under the terms of the GNU Lesser General Public License as published  *)
(* by the Free Software Foundation; either version 2.1 of the License, or    *)
(* any later version.                                                        *)
(*                                                                           *)
(* This program is distributed in the hope that it will be useful,           *)
(* but WITHOUT ANY WARRANTY; without even the implied warranty of            *)
(* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             *)
(* GNU Lesser General Public License for more details.                       *)
(*                                                                           *)
(* You should have received a copy of the GNU Lesser General Public License  *)
(* along with this program; if not, write to the Free Software               *)
(* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                  *)
(* 02111-1307  USA                                                           *)
(*                                                                           *)
(* Contact: Maxence.Guesdon@inria.fr                                         *)
(*****************************************************************************)


(** The module for the column type and its conversion into a string. *)
module SQL_column =
struct
  type t = Odbc.sql_t
  let string = Odbc.string_of_sql_t
end

module SQLInterface = Ocamlodbc_lowlevel.Interface(SQL_column)

module OCamlODBC_messages =
struct
  let disconnect = "ODBC : problem while disconnecting"
  let connection nom_base nom_user pzPasswd iRC1 =
    "Error while connecting to database " ^ nom_base ^ " as "
    ^ nom_user ^ " with password <" ^ pzPasswd ^ "> : "
    ^ (string_of_int iRC1)
  let connection_driver connect_string iRC1 =
    "Error while connecting to database with connection string "
    ^ connect_string ^ "> : " ^ (string_of_int iRC1)
end

type connection = {
  phEnv : Ocamlodbc_lowlevel.sQLHENV ;
  phDbc : Ocamlodbc_lowlevel.sQLHDBC ;
  base : string ;
  user : string ;
  passwd : string ;
}

let connect base user passwd =
  let (iRC1,hEnv,pHDbc) = SQLInterface.initDB base user passwd in
  if iRC1 = 0 then
    {
      phEnv = hEnv;
      phDbc = pHDbc;
      base = base ;
      user = user ;
      passwd = passwd ;
    }
  else
    raise (Odbc.SQL_Error (OCamlODBC_messages.connection base user passwd iRC1))

let connect_driver ?(prompt=false) connect_string =
  let (iRC1,hEnv,pHDbc) = SQLInterface.initDB_driver connect_string prompt in
  if iRC1 = 0 then
    {
      phEnv = hEnv;
      phDbc = pHDbc;
      base = connect_string ;
      user = "" ;
      passwd = "" ;
    }
  else
    raise (Odbc.SQL_Error (OCamlODBC_messages.connection_driver
                             connect_string iRC1))

let disconnect connection =
  let iRC = SQLInterface.exitDB connection.phEnv connection.phDbc in
  if iRC <> 0 then raise(Odbc.SQL_Error OCamlODBC_messages.disconnect)

(** Cette fonction ex�cute une requ�te interrompue par des appels
    r�guliers au GC. Elle retourne un triplet : code d'erreur (0 si
    ok), liste de couples (nom, type) pour d�crire les colonnes
    retourn�es, liste de liste de chaines repr�sentant les
    enregistrements.
*)
let execute_gen conn ?(get_info=false) ?(n_rec=40) req callback =
  if req = "" then
    (-1, ([] : (string * Odbc.sql_t) list))
  else (
    let (ret, env) = SQLInterface.execDB conn.phEnv conn.phDbc req in
    match ret with
    | 0 ->
	let l_desc_col =
	  if get_info then SQLInterface.get_infoDB env
            (* r�cup�rer les informations sur les champs retourn�s
	       (nom et type) par la derni�re requ�te ex�cut�e *)
	  else [] in
        (* r�cup�rer les records en plusieurs fois *)
	let rec iter () =
	  let (n, ll_res) = SQLInterface.itereDB env n_rec in
	  (*Gc.minor();*)
	  callback ll_res;
	  if n >= n_rec (* maybe more rows *) then iter() in
	iter();
	SQLInterface.free_execDB env;
	(ret, l_desc_col)

     | 1 ->
	 (* pas de colonne, donc pas d'enregistrements � r�cup�rer *)
	 SQLInterface.free_execDB env;
	 (0, [])
     | _ ->
	 SQLInterface.free_execDB env;
	 (ret, [])
  )

let execute_fetchall conn get_info req =
  let res  = ref [] in
  let callback  ll = res := !res @ ll in
  let (code, info) = execute_gen conn ~get_info:get_info req callback in
  (code, info, !res)

let execute conn req =
  let (c, _, l) = execute_fetchall conn false req in
  (c, l)

let execute_with_info conn req =
  execute_fetchall conn true req



(** Object-oriented interface. *)

(**
   @param base the database to connect to
   @param user the user to use when connecting
   @param passwd the password to use when connecting, can be [""]
*)
class database base user passwd =
object (self)
  (** The connection, initialized when the object is created. *)
  val connection = connect base user passwd
    (** The flag to indicates whether we are connected or not,
	used not to disconnect more than once.*)
  val mutable connected = true

  method connect () = ()

  method disconnect () =
    if connected then (
      connected <- false;
      disconnect connection
    )

  method execute req = execute connection req

  method execute_with_info req = execute_with_info connection req

  method execute_gen ?(get_info=false) ?(n_rec=1) req
    (callback : string option list list -> unit) =
    execute_gen connection ~get_info:get_info ~n_rec:n_rec req callback
end
