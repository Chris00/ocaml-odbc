(*[Mo] This module contains the box class, which allows to build
   a box to display the results of a query.[Mo]*)

(*[Cl] This class builds a box to display the results of a query.
   If the query is given, it is displayed.
   The results of the query consist in two lists :
   one list of couples (column name, column type),
   one list of list of strings representing the returned records.
[Cl]*)
class box context ?(query : string option) column_list records =
  let vbox = GPack.vbox () in 
  let wf = GBin.frame
      ~label: (match query with None -> "" | Some q -> q)
      ~packing: (vbox#pack ~expand: true ~padding: 4)
      ()
  in
  let wscroll = GBin.scrolled_window
      ~packing: wf#add
      ()
  in
  let wlist = GList.clist
      ~titles_show: true 
      ~titles: (List.map fst column_list)
      ~packing: (wscroll#add)
      ()
  in
  
  object(self)
    (*[Me] This method returns the vbox widget ready to packed.[Me]*)
    method box = vbox#coerce

    initializer
      (* fill the wlist with the records *)
      let f l =
	let _ = wlist#append l in
	()
      in
      List.iter f records;
      Biniki_misc.autosize_clist wlist;
      let rec iter n (name, typ) =
	wlist#set_column
	  (*~title: (name^"\n"^(Ocamlodbc.SQL_column.string typ))*)
	  ~justification: 
	  (match typ with
	    Ocamlodbc.SQL_numeric
	  | Ocamlodbc.SQL_decimal
	  | Ocamlodbc.SQL_integer
	  | Ocamlodbc.SQL_smallint
	  | Ocamlodbc.SQL_float
	  | Ocamlodbc.SQL_real
	  | Ocamlodbc.SQL_double
	  | Ocamlodbc.SQL_bigint
	  | Ocamlodbc.SQL_tinyint
	  | Ocamlodbc.SQL_bit ->
	      `RIGHT
	  | _ ->
	      `LEFT
	  )
	  n;
	n + 1
      in
      (*let _ = List.fold_left iter 0 column_list in*)
      ()

  end
