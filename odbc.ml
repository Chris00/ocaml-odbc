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

(* BEWARE: Keep constructor in the right order w.r.t. OCAML_SQL_*
   constants in ocaml_odbc_c.c *)
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

let string_of_sql_t = function
  | Unknown -> "Unknown"
  | Char -> "Char"
  | Numeric -> "Numeric"
  | Decimal -> "Decimal"
  | Integer -> "Integer"
  | Smallint -> "Smallint"
  | Float -> "Float"
  | Real -> "Real"
  | Double -> "Double"
  | Varchar -> "Varchar"
  | Date -> "Date"
  | Time -> "Time"
  | Timestamp -> "Timestamp"
  | Longvarchar -> "Longvarchar"
  | Binary -> "Binary"
  | Varbinary -> "Varbinary"
  | Longvarbinary -> "Longvarbinary"
  | Bigint -> "Bigint"
  | Tinyint -> "Tinyint"
  | Bit -> "Bit"
