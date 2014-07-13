(*Generated by Lem from initialEnv.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasivesTheory astTheory;

val _ = numLib.prefer_num();



val _ = new_theory "initialEnv"

(*open import Pervasives*)

(*open import Ast*)

(*val mk_binop : string -> op -> dec*)
val _ = Define `
 (mk_binop name prim =  
(Dlet (Pvar name) (Fun "x" (Fun "y" (App prim [Var (Short "x"); Var (Short "y")])))))`;


(*val mk_unop : string -> op -> dec*)
val _ = Define `
 (mk_unop name prim =  
(Dlet (Pvar name) (Fun "x" (App prim [Var (Short "x")]))))`;


(*val prim_types_program : prog*)
val _ = Define `
 (prim_types_program =  
([Tdec (Dtype [(["'a"], "option", [("NONE", []); ("SOME", [Tvar "'a"])])]);
   Tdec (Dtype [(["'a"], "list", [("nil", []); ("::", [Tvar "'a"; Tapp [Tvar "'a"] (TC_name (Short "list"))])])]);
   Tdec (Dexn "Bind" []);
   Tdec (Dexn "Div" []);
   Tdec (Dexn "Eq" []);
   Tdec (Dexn "Subscript" []) ]))`;


(*val basis_program : prog*)
val _ = Define `
 (basis_program =  
([Tdec (mk_binop "+" (Opn Plus));
   Tdec (mk_binop "-" (Opn Minus));
   Tdec (mk_binop "*" (Opn Times));
   Tdec (mk_binop "div" (Opn Divide));
   Tdec (mk_binop "mod" (Opn Modulo));
   Tdec (mk_binop "<" (Opb Lt));
   Tdec (mk_binop ">" (Opb Gt));
   Tdec (mk_binop "<=" (Opb Leq));
   Tdec (mk_binop ">=" (Opb Geq));
   Tdec (mk_binop "=" Equality);
   Tdec (mk_binop ":=" Opassign);
   Tdec (Dlet (Pvar "~") (Fun "x" (App (Opn Minus) [Lit (IntLit(( 0 : int))); Var(Short"x")])));
   Tdec (mk_unop "!" Opderef);
   Tdec (mk_unop "ref" Opref);
   Tmod "Word8" NONE [];
   Tmod "Word8Array" NONE 
     [mk_binop "array" Aalloc;
      mk_binop "sub" Asub;
      mk_unop "length" Alength;
      Dlet (Pvar "update") (Fun "x" (Fun "y" (Fun "z" (App Aupdate [Var (Short "x"); Var (Short "y"); Var (Short "z")])))) ] ]))`;


(*
val init_envC : envC
let init_envC =
  (emp,
   ("NONE", (0, TypeId (Short "option"))) ::
   ("SOME", (1, TypeId (Short "option"))) ::
   ("nil", (0, TypeId (Short "list"))) ::
   ("::", (2, TypeId (Short "list"))) ::
   List.map (fun cn -> (cn, (0, TypeExn (Short cn)))) ["Subscript";"Bind"; "Div"; "Eq"])

(* The initial value environment for the operational semantics *)
val init_env : envE
let init_env =
  [("+", Closure ([],init_envC,[]) "x" (Fun "y" (App (Opn Plus) [Var (Short "x"); Var (Short "y")])));
   ("-", Closure ([],init_envC,[]) "x" (Fun "y" (App (Opn Minus) [Var (Short "x"); Var (Short "y")])));
   ("*", Closure ([],init_envC,[]) "x" (Fun "y" (App (Opn Times) [Var (Short "x"); Var (Short "y")])));
   ("div", Closure ([],init_envC,[]) "x" (Fun "y" (App (Opn Divide) [Var (Short "x"); Var (Short "y")])));
   ("mod", Closure ([],init_envC,[]) "x" (Fun "y" (App (Opn Modulo) [Var (Short "x"); Var (Short "y")])));
   ("<", Closure ([],init_envC,[]) "x" (Fun "y" (App (Opb Lt) [Var (Short "x"); Var (Short "y")])));
   (">", Closure ([],init_envC,[]) "x" (Fun "y" (App (Opb Gt) [Var (Short "x"); Var (Short "y")])));
   ("<=", Closure ([],init_envC,[]) "x" (Fun "y" (App (Opb Leq) [Var (Short "x"); Var (Short "y")])));
   (">=", Closure ([],init_envC,[]) "x" (Fun "y" (App (Opb Geq) [Var (Short "x"); Var (Short "y")])));
   ("=", Closure ([],init_envC,[]) "x" (Fun "y" (App Equality [Var (Short "x"); Var (Short "y")])));
   (":=", Closure ([],init_envC,[]) "x" (Fun "y" (App Opassign [Var (Short "x"); Var (Short "y")])));
   ("~", Closure ([],init_envC,[]) "x" (App (Opn Minus) [Lit (IntLit 0); Var (Short "x")]));
   ("!", Closure ([],init_envC,[]) "x" (App Opderef [Var (Short "x")]));
   ("ref", Closure ([],init_envC,[]) "x" (App Opref [Var (Short "x")]))]


(* The initial type environment for the type system *)
val init_tenv : tenvE
let init_tenv =
  foldr 
    (fun (tn,tvs,t) tenv -> Bind_name tn tvs t tenv) 
    Empty 
    [("+", 0, Tfn Tint (Tfn Tint Tint));
     ("-", 0, Tfn Tint (Tfn Tint Tint));
     ("*", 0, Tfn Tint (Tfn Tint Tint));
     ("div", 0, Tfn Tint (Tfn Tint Tint));
     ("mod", 0, Tfn Tint (Tfn Tint Tint));
     ("<", 0, Tfn Tint (Tfn Tint Tbool));
     (">", 0, Tfn Tint (Tfn Tint Tbool));
     ("<=", 0, Tfn Tint (Tfn Tint Tbool));
     (">=", 0, Tfn Tint (Tfn Tint Tbool));
     ("=", 1, Tfn (Tvar_db 0) (Tfn (Tvar_db 0) Tbool));
     (":=", 1, Tfn (Tref (Tvar_db 0)) (Tfn (Tvar_db 0) Tunit));
     ("~", 0, Tfn Tint Tint);
     ("!", 1, Tfn (Tref (Tvar_db 0)) (Tvar_db 0));
     ("ref", 1, Tfn (Tvar_db 0) (Tref (Tvar_db 0)))]

(* The initial constructor environment for the type system *)
val init_tenvC : tenvC
let init_tenvC =
  (emp,
   ("NONE", (["'a"], [], TypeId (Short "option"))) ::
   ("SOME", (["'a"], [Tvar "'a"], TypeId (Short "option"))) ::
   ("nil", (["'a"], [], TypeId (Short "list"))) ::
   ("::", (["'a"], [Tvar "'a"; Tapp [Tvar "'a"] (TC_name (Short "list"))], TypeId (Short "list"))) ::
   List.map (fun cn -> (cn, ([], [], TypeExn (Short cn)))) ["Subscript";"Bind"; "Div"; "Eq"])

(* The initial mapping of type names to primitive type constructors, for the elaborator *)
val init_type_bindings : tdef_env
let init_type_bindings =
  [("int", TC_int);
   ("bool", TC_bool);
   ("ref", TC_ref);
   ("exn", TC_exn);
   ("unit", TC_unit);
   ("list", TC_name (Short "list"));
   ("option", TC_name (Short "option"))]

(* The types and exceptions that have been declared, for the type soundness invariant *)
val init_type_decs : set tid_or_exn
let init_type_decs = 
  { TypeId (Short "list");
    TypeId (Short "option");
    TypeExn (Short "Subscript");
    TypeExn (Short "Bind");
    TypeExn (Short "Div");
    TypeExn (Short "Eq") }

(* The modules, types, and exceptions that have been declared, for the type system to detect duplicates*)
val init_decls : decls
let init_decls = 
  ({}, { Short "option"; Short "list" }, { Short "Bind"; Short "Div"; Short "Eq" })
*)
val _ = export_theory()

