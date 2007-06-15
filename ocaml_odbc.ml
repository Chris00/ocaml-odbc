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

(** Low level part of OCamlODBC.  Do not use directly. *)

(* Definitions des types abstraits *)

type sQLHENV
  (** Database environment *)
type sQLHDBC
  (** Database context *)
type env
  (** Result handle *)

module type Sql_column_type =
sig
  type t
  val string : t -> string
end

module Interface (Sql_col : Sql_column_type) =
struct
  (*  Constructeurs des types abstraits (valeur vide) *)
  external value_SQLHENV : unit -> sQLHENV = "ocamlodbc_HENV_c" "noalloc"
  external value_SQLHDBC : unit -> sQLHDBC = "ocamlodbc_HDBC_c" "noalloc"

  (*  Fonctions C utilisées *)
  external initDB : string -> string -> string -> (int * sQLHENV * sQLHDBC)
    = "ocamlodbc_initDB_c"
    (** [initDB database user password] initializes a DB access.
        @return (err, phEnv, phDbc) where [err <> 0] in case of error,
        and [phEnv], [phDbc] are DB environment and context.  *)
  external initDB_driver : string -> bool -> (int * sQLHENV * sQLHDBC)
    = "ocamlodbc_initDB_driver_c"
    (** [initDB_driver conn prompt] initializes a DB access where
        [conn] is a ODBC driver connection string and [prompt = true]
        if the driver should raise a dialog box to request username
        and password.  The return value is the same as [initDB].  *)
  external exitDB : sQLHENV -> sQLHDBC -> int
    = "ocamlodbc_exitDB_c"
    (** [exitDB phEnv phDbc] closes the DB access.  Return [0] in case
        of success and a non-null number otherwise.  *)

  external execDB : sQLHENV -> sQLHDBC -> string -> int * env
    = "ocamlodbc_execDB_c"
    (** [execDB phEnv phDbc sql] retruns [(err, r)] where [r] is a
        handle to the results of the [sql] statement and
        - [err = 1] if there are no columns;
        - [err = 0] if theare are columns and the statement was
        executes properly;
        - other values of [err] indicate an error (in which case
        [r] cannot be used).  *)
  external free_execDB : env -> unit
    = "ocamlodbc_free_execDB_c"
    (** [free_execDB r] free the resources associated with the request
        handle [r].  *)
  external get_infoDB : env -> (string * Sql_col.t) list
    = "ocamlodbc_get_infoDB_c"
    (** [get_infoDB r] returns a list of pairs for each column in [r],
        where the pair [(cn, t)] means that the column name is [cn]
        and its SQL type is [t]. *)
  external itereDB : env -> int -> int * string option list list
    = "ocamlodbc_itere_execDB_c"
    (** [itereDB r nmax] returns a pair [(n, l)] where [n] is the
        number of returned rows and [l] is the list of rows (of length
        [n <= nmax]).  If [n < n_max], you must NOT call again
        [itereDB] on [r] -- this may result in a Segmentation
        fault.  *)
end
