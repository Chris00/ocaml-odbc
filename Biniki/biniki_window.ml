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

(*[Mo] This module contains the function which builds abiniki window. [Mo]*)

(*[Fonc]This function builds a biniki main window.
   If the query optional parameter is given, then the query
   must be executed, and if it gives results, a window
   must show them.
   If there is no results or if an error occurs, no window
   is displayed.
   If the query is correct (no error occured when executed),
   then it is added to the history.
   If no query parameter is given, the window is displayed,
   containing no "result box".
[Fonc]*)
let rec window context ?(query : string option) () =
  try     
    let (n, columns, records) = 
      match query with
	None ->
	  (0, [], [])
      | Some q ->
	  context#database#execute_with_info q
    in
    if n = 0 then
      (
       (* the query, if any, was successfully executed ; add it to the history *)
       let _ = 
	 match query with
	   None -> ()
	 | Some q -> context#add_query q
       in
       (* create the window if there are results to display or
	  it is the initial window (no query) *)
       match columns with
	 [] when query <> None ->
	   (* no result *)
	   ()
       | _ ->
           (* create the window *)
	   let win = GWindow.window
	       ~title: (Biniki_messages.logiciel^" "^Biniki_messages.version^" : "^context#base)
	       ~width:500 ()
	   in
	   let _ = win#connect#destroy ~callback: GMain.Main.quit in
	   
           (* The main box *)
	   let vbox = GPack.vbox ~packing:win#add () in
           (* The ... menubar ! *)
	   let menubar = GMenu.menu_bar ~packing: (vbox#pack ~expand: false) () in
	   let menuFile = GMenu.menu () in
	   let itemFile = GMenu.menu_item ~label: Biniki_messages.mn1 ~packing: menubar#add () in
	   let _ = itemFile#set_submenu menuFile in
	   let itemClose = GMenu.menu_item ~label: Biniki_messages.mn2
	       ~packing: menuFile#add ()
	   in
	   let _ = itemClose#connect#activate win#destroy in

	   let menuHelp = GMenu.menu () in
	   let itemHelp = GMenu.menu_item ~label: Biniki_messages.mn3 ~packing: menubar#add () in
	   let _ = itemHelp#set_submenu menuHelp in
	   let itemAbout = GMenu.menu_item ~label: Biniki_messages.mn4
	       ~packing: menuHelp#add ()
	   in
	   let _ = itemAbout#connect#activate
	       (fun () -> Biniki_misc.message_box Biniki_messages.mn4 Biniki_messages.mAbout)
	   in

	   let _ =
	     match query with
	       None -> ()
	     | Some q ->
                 (* add the query box *)
		 let query_box = new Biniki_query_box.box context ~query: q columns records in
		 let _ = vbox#pack ~expand: true query_box#box in
		 ()
	   in

           (* the box for the combo and the execute-button *)
	   let hbox = GPack.hbox ~packing: (vbox#pack ~expand: false ~padding: 2) () in
           (* The combo box for queries *)
	   let wcombo_queries = GEdit.combo
	       ~popdown_strings: ("" :: context#history_queries)
	       ~value_in_list: false
	       ~ok_if_empty: true
	       ~packing: (hbox#pack ~expand: true ~padding: 2)
	       ()
	   in
	   let wb_execute = GButton.button
	       ~label: Biniki_messages.mExecute
	       ~packing: (hbox#pack ~expand: false ~padding: 2)
	       ()
	   in
	   
	   (* the function called to execute the query in the combo *)
	   let f_exec_query () =
	     let string_query = wcombo_queries#entry#text in
	     window context ~query: string_query ()
	   in
	   let _ = wb_execute#connect#clicked f_exec_query in

	   win#show ();
	   GMain.Main.main ()
      )
    else
      Biniki_misc.message_box Biniki_messages.mErreur Biniki_messages.m0
  with
    Ocamlodbc.SQL_Error s ->
      Biniki_misc.message_box Biniki_messages.mErreur s

