open Ocamlodbc

let main () =
  let tab = Sys.argv in
    let pszDB = tab.(1) and
    pszUser = tab.(2) in

  let pszPassword = if (Array.length tab) < 4 then  "" else tab.(3) in

  (* Affichage parametre base *)
  print_string ("database : "^pszDB^"\n");
  print_string ("user     : "^pszUser^"\n");
  print_string ("password : "^pszPassword^"\n");

  (* Creation instance de la base *)
  let db = new data_base pszDB pszUser pszPassword in

  (* Initialisation de la base *)
  db#connect() ;

  (* Boucle infinie de traitement *)
  let sortie = ref false and str = ref "" in
  while (not (!sortie = true)) do 
  begin
    print_string "»»» ";
    str := read_line ();
    if !str = "" 
    then
    begin
      sortie := true;
      ()
    end
    else
      (
       let (iRC, l_nom_type, result)  = db#execute_with_info !str in
       if iRC = 0
       then
    	 let p_col row = 
	   List.iter
	     (function (s,col_type) -> 
	       print_string(s^" : "^(Ocamlodbc.SQL_column.string col_type)^"\n")
	     )
	     row
	 in
    	 print_string "Columns : \n";
    	 p_col l_nom_type;
    	 print_newline();
    	 print_newline();
    	 begin
           let p_row row = (List.iter (function s -> print_string (s^" ")) row) in
           let p_rows rows = (List.iter (function row -> p_row row; print_newline()) rows) in
          begin
	    print_string "Results :\n";
            p_rows result;
	    print_newline()
	  end
	 end
       else
         print_int iRC
      )
  end 
  done;
  db#disconnect();
;;
   
try
  main()
with
  SQL_Error(s) -> print_string s; print_newline()
| _ -> print_string "Unknown error.\n"
;;


