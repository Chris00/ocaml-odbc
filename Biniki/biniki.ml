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

(*[Mo] This is the main module of Biniki. [Mo]*)

let base = 
  try Sys.argv.(1)
  with _ ->
    output_string stderr Biniki_messages.mUsage;
    exit 1

let user =
  try Sys.argv.(2)
  with _ -> Biniki_messages.login

let passwd = 
  try Sys.argv.(3)
  with _ -> ""

(* create a database object *)
let db = new Ocamlodbc.data_base base user passwd

(* connect to data base *)
let _ =
  try db#connect ()
  with Ocamlodbc.SQL_Error s ->
    output_string stderr (s^"\n");
    exit 2

(* create a context object *)
let context = new Biniki_context.context base db

(* create the first window ; this function returns when all
   windows are closed, not only the first one created.*)
let _ = Biniki_window.window context ()

(* disconnect from data base *)
let _ =
  try db#disconnect ()
  with Ocamlodbc.SQL_Error s ->
    output_string stderr (s^"\n");
    exit 3
