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

(** Interface to ODBC databases.

    See http://home.gna.org/ocamlodbc/configuring.html for
    configutation information. *)

(** To report errors. *)
exception SQL_Error of string


(** The various SQL types for columns. *)
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


module SQL_column :
sig
  type t = sql_column_type
  val string : sql_column_type -> string
end


(** {2 Classic interface} *)

(** The type of connections to databases. *)
type connection

val connect : string -> string -> string -> connection
  (** [connect base user passwd] creates a connection to data source
      [base], as user [user], with password [passwd].

      @raise SQL_Error if the connection to the database failed. *)

val connect_driver : ?prompt:bool -> string -> connection
  (** [connect_driver conn_string] exposes the SQLDriverConnect
      function to OCaml (for ODBC v2 or greater under MinGW).  This
      allows SQLServer "trusted authentication" mode based on NT
      domain identities.  An example of [conn_string] is ["Driver={SQL
      Server};SERVER=FOOSERVER;Trusted_Connection=yes;Database=MYDB"].

      @param prompt tells whether the if the driver should raise a
      dialog box to request username and password.  Default: [false].

      @raise SQL_Error if the connection to the database failed. *)

val disconnect : connection -> unit
  (** Disconnect from a database. The given connection should not be
      used after this function was called.

      @raise SQL_Error if an error occured while disconnecting.*)

val execute : connection -> string -> int * string option list list
  (** [execute c q] executes query [q] through connection [c] and
      returns the result as a pair [(error_code, recordlist)], where a
      record is a [string option list].  The [error_code] is 0 if no
      error occured.  Each field of a record can be [None], which
      represents the SQL NULL, or [Some v] where [v] is a string holding
      the field value. *)

val execute_with_info :
  connection -> string
  -> int * (string * sql_column_type) list * string option list list
  (** [execute_with_info c q] executes query [q] through connection [c] and
      returns the result as a tuple [(error_code, type_list, record list)],
      where [type_list] indicates the SQL types of the returned columns,
      and a record is a [string list].
      The [error_code] is [>= 0] if no error occured.*)

val execute_gen :
  connection -> ?get_info:bool -> ?n_rec:int -> string ->
  (string option list list -> unit) -> int * (string * sql_column_type) list
  (** [execute_gen c get_info n_rec q callback] executes query [q] over
      the connection [c], and invokes [callback] on successful blocks of
      the results (of [n_rec] records each). Each record is a [string
      list] of fields.

      The result is a tuple [(error_code, type_list)].  The
      [error_code] is [>= 0] if no error occurred, [type_list] is
      empty if [get_info] is [false].  *)


(** {2 Object-oriented interface} *)

(** The class which represents a connection to a database.  The
    connection occurs when the object is created.
    @raise SQL_Error if an error occured during the connection to the
    database.  *)
class data_base :
  string ->
  string ->
  string ->
object
  method connect : unit -> unit
  (** @deprecated The connection to the database oocurs when the
      object is created.*)

  method disconnect : unit -> unit
  (** Disconnect from the database. The objet should not be used
      after calling this method.
      @raise SQL_Error if an error occurs while disconnecting.*)

  method execute : string -> int * (string option list list)
  (** [#execute q] executes query [q] and returns the result as a pair
      [(error_code, recordlist)], where a record is a [string
      list]. The [error_code] is 0 if no error occured.*)

  method execute_with_info :
    string -> int * ((string * sql_column_type) list)
                  * (string option list list)
  (** [#execute_with_info q] executes query [q] and returns the result
      as a tuple [(error_code, type_list, record list)], where
      [type_list] indicates the SQL types of the returned columns, and
      a record is a [string list].

      The [error_code] is 0 if no error occured.*)

  method execute_gen :
    ?get_info:bool -> ?n_rec:int -> string ->
    (string option list list -> unit) -> int * (string * sql_column_type) list
  (** [#execute_gen get_info n_rec q callback] executes query [q] and
      invokes [callback] on successful blocks of the results (of
      [n_rec] records each). Each record is a [string list] of fields.
      The result is a tuple [(error_code, type_list)]. The
      [error_code] is 0 if no error occurred, [type_list] is empty if
      [get_info] is [false].  *)
end
