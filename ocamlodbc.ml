(*****************************************************************************)
(*              OCamlODBC                                                    *)
(*                                                                           *)
(*  Copyright (C) 2004 Institut National de Recherche en Informatique et     *)
(*  en Automatique. All rights reserved.                                     *)
(*                                                                           *)
(*  This program is free software; you can redistribute it and/or modify     *)
(*  it under the terms of the GNU Lesser General Public License as published *)
(*  by the Free Software Foundation; either version 2.1 of the License, or   *)
(*  any later version.                                                       *)
(*                                                                           *)
(*  This program is distributed in the hope that it will be useful,          *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            *)
(*  GNU Lesser General Public License for more details.                      *)
(*                                                                           *)
(*  You should have received a copy of the GNU Lesser General Public License *)
(*  along with this program; if not, write to the Free Software              *)
(*  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                 *)
(*  02111-1307  USA                                                          *)
(*                                                                           *)
(*  Contact: Maxence.Guesdon@inria.fr                                        *)
(*****************************************************************************)

(* $Id: ocamlodbc.ml,v 1.11 2005-11-12 16:36:30 chris Exp $ *)

(** The software name *)
let logiciel = "OCamlODBC"

(** The software version *)
let version = "2.20"

exception SQL_Error of string

(* BEWARE: Keep constructor in the right order w.r.t. OCAML_SQL_*
   constants in ocaml_odbc_c.c *)
type sql_column_type =
  | SQL_unknown
  | SQL_char
  | SQL_numeric
  | SQL_decimal
  | SQL_integer
  | SQL_smallint
  | SQL_float
  | SQL_real
  | SQL_double
  | SQL_varchar
  | SQL_date
  | SQL_time
  | SQL_timestamp
  | SQL_longvarchar
  | SQL_binary
  | SQL_varbinary
  | SQL_longvarbinary
  | SQL_bigint
  | SQL_tinyint
  | SQL_bit


(** The module for the column type and its conversion into a string. *)
module SQL_column =
struct
  type t = sql_column_type
  let string col_type =
    match col_type with
    | SQL_unknown -> "SQL_unknown"
    | SQL_char -> "SQL_char"
    | SQL_numeric -> "SQL_numeric"
    |	SQL_decimal -> "SQL_decimal"
    | SQL_integer -> "SQL_integer"
    | SQL_smallint -> "SQL_smallint"
    | SQL_float -> "SQL_float"
    | SQL_real -> "SQL_real"
    | SQL_double -> "SQL_double"
    | SQL_varchar -> "SQL_varchar"
    | SQL_date -> "SQL_date"
    | SQL_time -> "SQL_time"
    | SQL_timestamp -> "SQL_timestamp"
    | SQL_longvarchar -> "SQL_longvarchar"
    | SQL_binary -> "SQL_binary"
    | SQL_varbinary -> "SQL_varbinary"
    | SQL_longvarbinary -> "SQL_longvarbinary"
    | SQL_bigint -> "SQL_bigint"
    | SQL_tinyint -> "SQL_tinyint"
    | SQL_bit -> "SQL_bit"
end

module SQLInterface = Ocaml_odbc.Interface(SQL_column)

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
  phEnv : Ocaml_odbc.sQLHENV ;
  phDbc : Ocaml_odbc.sQLHDBC ;
  base : string ;
  user : string ;
  passwd : string ;
}

let connect base user passwd =
  let (iRC1,hEnv,pHDbc) = SQLInterface.initDB base user passwd in
  if (iRC1 = 0) then
    {
      phEnv = hEnv;
      phDbc = pHDbc;
      base = base ;
      user = user ;
      passwd = passwd ;
    }
  else
    raise (SQL_Error (OCamlODBC_messages.connection base user passwd iRC1))

let connect_driver ?(prompt=false) connect_string =
  let (iRC1,hEnv,pHDbc) = SQLInterface.initDB_driver connect_string prompt in
  if (iRC1 = 0) then
    {
      phEnv = hEnv;
      phDbc = pHDbc;
      base = connect_string ;
      user = "" ;
      passwd = "" ;
    }
  else
    raise (SQL_Error (OCamlODBC_messages.connection_driver connect_string iRC1))

let disconnect connection =
  let iRC = (SQLInterface.exitDB connection.phEnv connection.phDbc) in
  if (iRC > 0) then
    raise (SQL_Error OCamlODBC_messages.disconnect)
  else
    ()

(** Cette fonction privée exécute une requête interrompue par des appels
   réguliers au GC. Elle retourne un triplet : code d'erreur (0 si ok),
   liste de couples (nom, type) pour décrire les colonnes retournées,
   liste de liste de chaines représentant les enregistrements.
*)
let execute_gen connection ?(get_info=false) ?(n_rec=1) req callback =
  if req = "" then
    (-1, ([] : (string * sql_column_type) list))
  else
    (
     let phEnv = connection.phEnv in
     let phDbc = connection.phDbc in
     let (ret, env) = SQLInterface.execDB phEnv phDbc req in
     match ret with
       0 ->
	 let l_desc_col =
	   if get_info then
             (* récupérer les informations sur les champs retournés
		(nom et type) par la dernière requête exécutée *)
	     SQLInterface.get_infoDB env
	   else
	     []
	 in
         (* récupérer les records en plusieurs fois *)
	 (
	  let rec iter () =
	    let (n, ll_res) = SQLInterface.itereDB env n_rec in
	    (*Gc.minor();*)

	    let no_more = n < n_rec in
	    (
	      callback ll_res;
	      if   no_more
	      then ()
	      else iter ()
	    )
	  in
	  let _ = iter () in
	  let _ = SQLInterface.free_execDB env in
	  (ret, l_desc_col)
      	 )

     | 1 ->
	 (* pas de colonne, donc pas d'enregistrements à récupérer *)
	 let _ = SQLInterface.free_execDB env in
	 (0, [])
     | _ ->
	 let _ = SQLInterface.free_execDB env in
	 (ret, [])
    )

let execute_fetchall connection get_info req =
  let res  = ref [] in
  let step = 40     in
  let callback  ll = res := (!res) @ ll in
  let (code, info) =
      execute_gen connection ~get_info:get_info ~n_rec:step req callback
  in
  (code, info, !res)

let execute connection req =
  let (c, _, l) = execute_fetchall connection false req in
  (c, l)

let execute_with_info connection req =
  execute_fetchall connection true req

(** Object-oriented interface. *)

(**
   @param base the database to connect to
   @param user the user to use when connecting
   @param passwd the password to use when connecting, can be [""]
*)
class data_base base user passwd =
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
    (callback : string list list -> unit) =
    execute_gen connection ~get_info:get_info ~n_rec:n_rec req callback
end
