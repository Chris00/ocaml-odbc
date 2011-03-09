(************************************************************************************)
(*                OCamlODBC                                                         *)
(*                                                                                  *)
(*    Copyright (C) 2004-2011 Institut National de Recherche en Informatique        *)
(*    et en Automatique. All rights reserved.                                       *)
(*                                                                                  *)
(*    This program is free software; you can redistribute it and/or modify          *)
(*    it under the terms of the GNU General Public License as published             *)
(*    by the Free Software Foundation; either version 2.1 of the License, or        *)
(*    any later version.                                                            *)
(*                                                                                  *)
(*    This program is distributed in the hope that it will be useful,               *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of                *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                 *)
(*    GNU Lesser General Public License for more details.                           *)
(*                                                                                  *)
(*    You should have received a copy of the GNU General Public License             *)
(*    along with this program; if not, write to the Free Software                   *)
(*    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                      *)
(*    02111-1307  USA                                                               *)
(*                                                                                  *)
(*    Contact: Maxence.Guesdon@inria.fr                                             *)
(*                                                                                  *)
(************************************************************************************)

(*[Mo] This module contains misc functions used in biniki.[Mo]*)

(*[Fonc] This function takes a filename and returns
   the list of strings (one string per line) read
   from the file. Raises Failure if an error occurs.
[Fonc]*)
let input_string_list file =
  try
    let chanin = open_in file in
    let rec iter () =
      try
	let s = input_line chanin in
	s :: (iter ())
      with
	_ ->
	  close_in chanin;
	  []
    in
    iter ()
  with
    Sys_error s ->
      raise (Failure s)
  | _ ->
      raise (Failure Biniki_messages.m0)

(*[Fonc] This function takes a filename and a string list
   and writes the strings in the file.
   Raises Failure if an error occurs.
[Fonc]*)
let output_string_list file string_list =
  try
    let chanout = open_out file in
    let rec iter = function
	[] -> close_out chanout
      |	s :: q ->
	  output_string chanout
	    (s^(if q = [] then "" else "\n"));
	  iter q
    in
    iter string_list
  with
    Sys_error s ->
      raise (Failure s)
  | _ ->
      raise (Failure Biniki_messages.m0)

(*[Fonc]This function is used to display a question in a dialog box,
   with a parametrized list of buttons. The function returns the number
   of the clicked button, or 0 if the window is savagedly destroyed.[Fonc]*)
let question_box title message button_list =
  let button_nb = ref 0 in
  let window = GWindow.window ~modal:true ~title: title () in
  let box = GPack.vbox ~spacing:5 ~border_width:3 ~packing:window#add () in
  let lMessage = GMisc.label ~text: message ~packing: (box#pack ~expand: true) () in
  let bbox = GPack.hbox ~spacing: 5 ~border_width:3
      ~packing: (box#pack ~expand: false) ()
  in
  (* the function called to create each button by iterating *)
  let rec iter_buttons n = function
      [] ->
        ()
    | button_label :: q ->    
        let b = GButton.button ~label: button_label 
            ~packing:(bbox#pack ~expand: true ~fill:true ~padding:4) ()
        in
        let _ = b #connect#clicked
            ~callback: (fun _ -> button_nb := n; window #destroy ())
        in
        (* si c'est le premier bouton, on lui met le focus *)
        if n = 1 then b#misc#grab_focus () else ();

        iter_buttons (n+1) q
  in
  iter_buttons 1 button_list;
  let _ = window #connect#destroy ~callback: GMain.Main.quit in
  window#set_position `CENTER;
  window # show ();
  GMain.Main.main ();
  !button_nb
;;

(*[Fonc]This function is used to display a message in a dialog box with just an Ok button.
   We use the question box with just an ok button. [Fonc]*)
let message_box title message =
  let _ = question_box title message [Biniki_messages.mOk] in
  ()
;;

(*[Fonc]This function takes a clist widget and set the width of each column
   to be large enough for the largest string in the column and its title.[Fonc]*)
let autosize_clist wlist =
  (* get the number of columns *)
  let nb_columns = wlist#columns in
  (* get the columns titles *)
  let rec iter lacc i =
    if i >= nb_columns then
      lacc
    else
      let title = wlist#column_title i in
      iter (lacc@[("  "^title^"  ")]) (i+1)
  in
  let titles = iter [] 0 in
  (* insert a row with the titles *)
  let _ = wlist#insert ~pos:0 titles in
  (* use to clist columns_autosize method *)
  let _ = wlist#columns_autosize () in
  (* remove the inserted row *)
  let _ = wlist#remove 0 in
  ()
;;

(*[Fonc]This function removes the trailing spaces of a string.[Fonc]*)
let remove_trailing_spaces s =
  Str.global_replace (Str.regexp "[' ']+$") "" s
;;
