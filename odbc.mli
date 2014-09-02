(*****************************************************************************)
(*             OCamlODBC                                                     *)
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
(*****************************************************************************)

exception SQL_Error of string
(** Raised to signal errors. *)

(** The various SQL types for columns. *)
type sql_t =
  | Unknown
  | Char
  | Numeric
  | Decimal
  | Integer
  | Smallint
  | Float
  | Real
  | Double
  | Varchar
  | Date
  | Time
  | Timestamp
  | Longvarchar
  | Binary
  | Varbinary
  | Longvarbinary
  | Bigint
  | Tinyint
  | Bit

val string_of_sql_t : sql_t -> string
(** Return a string representation of the column type. *)

;;
