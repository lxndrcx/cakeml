(*Generated by Lem from decLang.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasivesTheory libTheory astTheory semanticPrimitivesTheory lem_list_extraTheory bigStepTheory conLangTheory;

val _ = numLib.prefer_num();



val _ = new_theory "decLang"

(* Removes declarations. Follows conLang.
 *
 * The AST of decLang differs from conLang in that there is no declarations
 * level, the program is represented by an expressions.
 *
 * The values of decLang are the same as conLang.
 *
 * The semantics of decLang differ in that the global environment is now
 * store-like rather than environment-like. The expressions for extending and
 * initialising it modify the global environment (instead of just rasing a
 * type error).
 *
 * The translator to decLang maps a declaration to an expression that sets of
 * the global environment in the right way. If evaluating the expression
 * results in an exception, then the exception is handled, and a SOME
 * containing the exception is returned. Otherwise, a NONE is returned.
 *
 *)

(*open import Pervasives*)
(*open import Lib*)
(*open import Ast*)
(*open import SemanticPrimitives*)
(*open import List_extra*)
(*open import BigStep*)
(*open import ConLang*)

(*val init_globals : list varN -> nat -> exp_i2*)
 val _ = Define `
 (init_globals [] idx = (Con_i2 NONE []))
/\ (init_globals (x::vars) idx =  
(Let_i2 NONE (App_i2 (Init_global_var_i2 idx) [Var_local_i2 x]) (init_globals vars (idx + 1))))`;


(*val init_global_funs : nat -> list (varN * varN * exp_i2) -> exp_i2*)
 val _ = Define `
 (init_global_funs next [] = (Con_i2 NONE []))
/\ (init_global_funs next ((f,x,e)::funs) =  
(Let_i2 NONE (App_i2 (Init_global_var_i2 next) [Fun_i2 x e]) (init_global_funs (next+ 1) funs)))`;


(*val decs_to_i3 : nat -> list dec_i2 -> exp_i2*)
 val _ = Define `
 (decs_to_i3 next [] = (Con_i2 NONE []))
/\ (decs_to_i3 next (d::ds) =  
((case d of
      Dlet_i2 n e =>
        let vars = (GENLIST (\ n .   STRCAT"x" (num_to_dec_string n)) n) in
          Let_i2 NONE (Mat_i2 e [(Pcon_i2 NONE (MAP Pvar_i2 vars), init_globals vars next)]) (decs_to_i3 (next+n) ds)
    | Dletrec_i2 funs =>
        let n = (LENGTH funs) in
          Let_i2 NONE (init_global_funs next funs) (decs_to_i3 (next+n) ds)
  )))`;


(*val prompt_to_i3 : (nat * tid_or_exn) -> (nat * tid_or_exn) -> nat -> prompt_i2 -> nat * exp_i2*)
val _ = Define `
 (prompt_to_i3 none_tag some_tag next prompt =  
((case prompt of
      Prompt_i2 ds =>
        let n = (num_defs ds) in
          ((next+n), Let_i2 NONE (Extend_global_i2 n) (Handle_i2 (Let_i2 NONE (decs_to_i3 next ds) (Con_i2 (SOME none_tag) [])) [(Pvar_i2 "x", Con_i2 (SOME some_tag) [Var_local_i2 "x"])]))
  )))`;


(*val prog_to_i3 : (nat * tid_or_exn) -> (nat * tid_or_exn) -> nat -> list prompt_i2 -> nat * exp_i2*)
 val prog_to_i3_defn = Hol_defn "prog_to_i3" `

(prog_to_i3 none_tag some_tag next [] = (next, Con_i2 (SOME none_tag) []))
/\
(prog_to_i3 none_tag some_tag next (p::ps) =  
(let (next',p') = (prompt_to_i3 none_tag some_tag next p) in
  let (next'',ps') = (prog_to_i3 none_tag some_tag next' ps) in
    (next'',Mat_i2 p' [(Pcon_i2 (SOME none_tag) [], ps'); (Pvar_i2 "x", Var_local_i2 "x")])))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn prog_to_i3_defn;

val _ = type_abbrev((*  'a *) "count_store_genv" , ``: 'a count_store_trace # ( 'a option) list``);
val _ = type_abbrev((*  'a *) "store_genv" , ``: 'a store_trace # ( 'a option) list``);

(*val do_app_i3 : count_store_genv v_i2 -> op_i2 -> list v_i2 -> maybe (count_store_genv v_i2 * result v_i2 v_i2)*)
val _ = Define `
 (do_app_i3 ((count,s,t),genv) op vs =  
((case (op,vs) of
      (Op_i2 op, vs) =>
        (case do_app_i2 (s,t) (Op_i2 op) vs of
            NONE => NONE
          | SOME ((s,t),r) => SOME (((count,s,t),genv),r)
        ) 
    | (Init_global_var_i2 idx, [v]) =>
        if idx < LENGTH genv then
          (case EL idx genv of
              NONE => SOME (((count,s,t), LUPDATE (SOME v) idx genv), (Rval (Conv_i2 NONE [])))
            | SOME x => NONE
          )
        else
          NONE
    | _ => NONE
  )))`;


val _ = type_abbrev( "all_env_i3" , ``: exh_ctors_env # (varN, v_i2) alist``);

val _ = Hol_reln ` (! ck env l s.
T
==>
evaluate_i3 ck env s (Lit_i2 l) (s, Rval (Litv_i2 l)))

/\ (! ck env e s1 s2 v.
(evaluate_i3 ck s1 env e (s2, Rval v))
==>
evaluate_i3 ck s1 env (Raise_i2 e) (s2, Rerr (Rraise v)))

/\ (! ck env e s1 s2 err.
(evaluate_i3 ck s1 env e (s2, Rerr err))
==>
evaluate_i3 ck s1 env (Raise_i2 e) (s2, Rerr err))

/\ (! ck s1 s2 env e v pes.
(evaluate_i3 ck s1 env e (s2, Rval v))
==>
evaluate_i3 ck s1 env (Handle_i2 e pes) (s2, Rval v))

/\ (! ck s1 s2 env e pes v bv.
(evaluate_i3 ck env s1 e (s2, Rerr (Rraise v)) /\
evaluate_match_i3 ck env s2 v pes v bv)
==>
evaluate_i3 ck env s1 (Handle_i2 e pes) bv)

/\ (! ck s1 s2 env e pes a.
(evaluate_i3 ck env s1 e (s2, Rerr (Rabort a)))
==>
evaluate_i3 ck env s1 (Handle_i2 e pes) (s2, Rerr (Rabort a)))

/\ (! ck env tag es vs s s'.
(evaluate_list_i3 ck env s (REVERSE es) (s', Rval vs))
==>
evaluate_i3 ck env s (Con_i2 tag es) (s', Rval (Conv_i2 tag (REVERSE vs))))

/\ (! ck env tag es err s s'.
(evaluate_list_i3 ck env s (REVERSE es) (s', Rerr err))
==>
evaluate_i3 ck env s (Con_i2 tag es) (s', Rerr err))

/\ (! ck exh env n v s.
(ALOOKUP env n = SOME v)
==>
evaluate_i3 ck (exh,env) s (Var_local_i2 n) (s, Rval v))

/\ (! ck env n v s genv.
((LENGTH genv > n) /\
(EL n genv = SOME v))
==>
evaluate_i3 ck env (s,genv) (Var_global_i2 n) ((s,genv), Rval v))

/\ (! ck exh env n e s.
T
==>
evaluate_i3 ck (exh,env) s (Fun_i2 n e) (s, Rval (Closure_i2 env n e)))

/\ (! ck exh genv env es vs env' e bv s1 s2 t2 count genv'.
(evaluate_list_i3 ck (exh,env) (s1,genv) (REVERSE es) (((count,s2,t2),genv'), Rval vs) /\
(do_opapp_i2 (REVERSE vs) = SOME (env', e)) /\
(ck ==> ~ (count =( 0))) /\
evaluate_i3 ck (exh,env') (((if ck then count -  1 else count),s2,t2),genv') e bv)
==>
evaluate_i3 ck (exh,env) (s1,genv) (App_i2 (Op_i2 Opapp) es) bv)

/\ (! ck env es vs env' e s1 s2 t2 count genv.
(evaluate_list_i3 ck env s1 (REVERSE es) (((count,s2,t2), genv), Rval vs) /\
(do_opapp_i2 (REVERSE vs) = SOME (env', e)) /\
(count = 0) /\
ck)
==>
evaluate_i3 ck env s1 (App_i2 (Op_i2 Opapp) es) ((( 0,s2,t2),genv), Rerr (Rabort Rtimeout_error)))

/\ (! ck env s1 op es s2 vs s3 res.
(evaluate_list_i3 ck env s1 (REVERSE es) (s2, Rval vs) /\
(do_app_i3 s2 op (REVERSE vs) = SOME (s3, res)) /\
(op <> Op_i2 Opapp))
==>
evaluate_i3 ck env s1 (App_i2 op es) (s3, res))

/\ (! ck env s1 op es s2 err.
(evaluate_list_i3 ck env s1 (REVERSE es) (s2, Rerr err))
==>
evaluate_i3 ck env s1 (App_i2 op es) (s2, Rerr err))

/\ (! ck env e1 e2 e3 v e' bv s1 s2.
(evaluate_i3 ck env s1 e1 (s2, Rval v) /\
(do_if_i2 v e2 e3 = SOME e') /\
evaluate_i3 ck env s2 e' bv)
==>
evaluate_i3 ck env s1 (If_i2 e1 e2 e3) bv)

/\ (! ck env e1 e2 e3 err s s'.
(evaluate_i3 ck env s e1 (s', Rerr err))
==>
evaluate_i3 ck env s (If_i2 e1 e2 e3) (s', Rerr err))

/\ (! ck env e pes v bv s1 s2.
(evaluate_i3 ck env s1 e (s2, Rval v) /\
evaluate_match_i3 ck env s2 v pes (Conv_i2 (SOME (bind_tag, (TypeExn (Short "Bind")))) []) bv)
==>
evaluate_i3 ck env s1 (Mat_i2 e pes) bv)

/\ (! ck env e pes err s s'.
(evaluate_i3 ck env s e (s', Rerr err))
==>
evaluate_i3 ck env s (Mat_i2 e pes) (s', Rerr err))

/\ (! ck exh env n e1 e2 v bv s1 s2.
(evaluate_i3 ck (exh,env) s1 e1 (s2, Rval v) /\
evaluate_i3 ck (exh,opt_bind n v env) s2 e2 bv)
==>
evaluate_i3 ck (exh,env) s1 (Let_i2 n e1 e2) bv)

/\ (! ck env n e1 e2 err s s'.
(evaluate_i3 ck env s e1 (s', Rerr err))
==>
evaluate_i3 ck env s (Let_i2 n e1 e2) (s', Rerr err))

/\ (! ck exh env funs e bv s.
(ALL_DISTINCT (MAP (\ (x,y,z) .  x) funs) /\
evaluate_i3 ck (exh,build_rec_env_i2 funs env env) s e bv)
==>
evaluate_i3 ck (exh,env) s (Letrec_i2 funs e) bv)

/\ (! ck env n s genv.
T
==>
evaluate_i3 ck env (s,genv) (Extend_global_i2 n) ((s,(genv++GENLIST (\ x .  NONE) n)), Rval (Conv_i2 NONE [])))

/\ (! ck env s.
T
==>
evaluate_list_i3 ck env s [] (s, Rval []))

/\ (! ck env e es v vs s1 s2 s3.
(evaluate_i3 ck env s1 e (s2, Rval v) /\
evaluate_list_i3 ck env s2 es (s3, Rval vs))
==>
evaluate_list_i3 ck env s1 (e::es) (s3, Rval (v::vs)))

/\ (! ck env e es err s s'.
(evaluate_i3 ck env s e (s', Rerr err))
==>
evaluate_list_i3 ck env s (e::es) (s', Rerr err))

/\ (! ck env e es v err s1 s2 s3.
(evaluate_i3 ck env s1 e (s2, Rval v) /\
evaluate_list_i3 ck env s2 es (s3, Rerr err))
==>
evaluate_list_i3 ck env s1 (e::es) (s3, Rerr err))

/\ (! ck env v s err_v.
T
==>
evaluate_match_i3 ck env s v [] err_v (s, Rerr (Rraise err_v)))

/\ (! ck exh env env' v p pes e bv s t count genv err_v.
(ALL_DISTINCT (pat_bindings_i2 p []) /\
(pmatch_i2 exh s p v env = Match env') /\
evaluate_i3 ck (exh,env') ((count,s,t),genv) e bv)
==>
evaluate_match_i3 ck (exh,env) ((count,s,t),genv) v ((p,e)::pes) err_v bv)

/\ (! ck exh genv env v p e pes bv s t count err_v.
(ALL_DISTINCT (pat_bindings_i2 p []) /\
(pmatch_i2 exh s p v env = No_match) /\
evaluate_match_i3 ck (exh,env) ((count,s,t),genv) v pes err_v bv)
==>
evaluate_match_i3 ck (exh,env) ((count,s,t),genv) v ((p,e)::pes) err_v bv)`;
val _ = export_theory()

