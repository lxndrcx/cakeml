(*
  Translate the final part of the compiler backend for 64-bit targets.
*)
open preamble;
open terminationTheory
open ml_translatorLib ml_translatorTheory;
open to_word64ProgTheory std_preludeTheory;

val _ = new_theory "to_target64Prog"

val _ = translation_extends "to_word64Prog";

val _ = ml_translatorLib.ml_prog_update (ml_progLib.open_module "to_target64Prog");

val RW = REWRITE_RULE

val _ = add_preferred_thy "-";

val NOT_NIL_AND_LEMMA = Q.prove(
  `(b <> [] /\ x) = if b = [] then F else x`,
  Cases_on `b` THEN FULL_SIMP_TAC std_ss []);

val extra_preprocessing = ref [MEMBER_INTRO,MAP];

val matches = ref ([]: term list);
val inst_tyargs = ref ([]:hol_type list);

fun def_of_const tm = let
  val res = dest_thy_const tm handle HOL_ERR _ =>
              failwith ("Unable to translate: " ^ term_to_string tm)
  val name = (#Name res)
  fun def_from_thy thy name =
    DB.fetch thy (name ^ "_pmatch") handle HOL_ERR _ =>
    DB.fetch thy (name ^ "_def") handle HOL_ERR _ =>
    DB.fetch thy (name ^ "_DEF") handle HOL_ERR _ =>
    DB.fetch thy (name ^ "_thm") handle HOL_ERR _ =>
    DB.fetch thy name
  val def = def_from_thy (#Thy res) name handle HOL_ERR _ =>
            failwith ("Unable to find definition of " ^ name)

  val insts = if exists (fn term => can (find_term (can (match_term term))) (concl def)) (!matches) then map (fn x => x |-> ``:64``) (!inst_tyargs)  else []

  val def = def |> RW (!extra_preprocessing)
                |> INST_TYPE insts
                |> CONV_RULE (DEPTH_CONV BETA_CONV)
                (* TODO: This ss messes up defs containing if-then-else
                with constant branches
                |> SIMP_RULE bool_ss [IN_INSERT,NOT_IN_EMPTY]*)
                |> REWRITE_RULE [NOT_NIL_AND_LEMMA]
  in def end

val _ = (find_def_for_const := def_of_const);

val _ = use_long_names:=true;

val spec64 = INST_TYPE[alpha|->``:64``]

val conv64 = GEN_ALL o CONV_RULE (wordsLib.WORD_CONV) o spec64 o SPEC_ALL

val conv64_RHS = GEN_ALL o CONV_RULE (RHS_CONV wordsLib.WORD_CONV) o spec64 o SPEC_ALL

val gconv = CONV_RULE (DEPTH_CONV wordsLib.WORD_GROUND_CONV)

val econv = CONV_RULE wordsLib.WORD_EVAL_CONV

val _ = matches:= [``foo:'a wordLang$prog``,``foo:'a wordLang$exp``,``foo:'a word``,``foo: 'a reg_imm``,``foo:'a arith``,``foo: 'a addr``,``foo:'a stackLang$prog``]

val _ = inst_tyargs := [alpha]

open word_to_stackTheory

val _ = translate (conv64 write_bitmap_def|> (RW (!extra_preprocessing)))

(* TODO: The paired let trips up the translator's single line def mechanism, unable to find a smaller failing example yet *)
val _ = translate (conv64 (wLive_def |> SIMP_RULE std_ss [LET_THM]))

(* TODO: the name is messed up (pair_) *)
val _ = translate PAIR_MAP

val _ = translate parmoveTheory.fstep_def

val parmove_fstep_side = Q.prove(`
  ∀x. parmove_fstep_side x ⇔ T`,
  EVAL_TAC>>rw[]>>Cases_on`v18`>>fs[]) |> update_precondition

val _ = translate (spec64 word_to_stackTheory.wMove_def)

val _ = translate (spec64 call_dest_def)

val _ = translate (wInst_def |> conv64)
val _ = translate (spec64 comp_def)

val _ = translate (compile_word_to_stack_def |> INST_TYPE [beta |-> ``:64``])

val _ = translate (compile_def |> INST_TYPE [alpha|->``:64``,beta|->``:64``]);

open stack_allocTheory

val inline_simp = SIMP_RULE std_ss [bytes_in_word_def,
                                    backend_commonTheory.word_shift_def]
val _ = translate (SetNewTrigger_def |> inline_simp |> conv64)
val _ = translate (conv64 clear_top_inst_def)
val _ = translate (memcpy_code_def |> inline_simp |> conv64)
val _ = translate (word_gc_move_code_def |> inline_simp |> conv64)

val _ = translate (word_gc_move_bitmap_code_def |> inline_simp |> conv64);
val _ = translate (word_gc_move_bitmaps_code_def |> inline_simp |> conv64);
val _ = translate (word_gc_move_roots_bitmaps_code_def |> inline_simp |> conv64);
val _ = translate (word_gc_move_list_code_def |> inline_simp |> conv64);
val _ = translate (word_gc_move_loop_code_def |> inline_simp |> conv64);

val _ = translate (stack_allocTheory.word_gen_gc_move_code_def |> inline_simp |> conv64);
val _ = translate (stack_allocTheory.word_gen_gc_move_bitmap_code_def |> inline_simp |> conv64);
val _ = translate (stack_allocTheory.word_gen_gc_move_bitmaps_code_def |> inline_simp |> conv64);
val _ = translate (stack_allocTheory.word_gen_gc_move_roots_bitmaps_code_def |> inline_simp |> conv64);
val _ = translate (stack_allocTheory.word_gen_gc_move_list_code_def |> inline_simp |> conv64);
val _ = translate (stack_allocTheory.word_gen_gc_move_data_code_def |> inline_simp |> conv64);
val _ = translate (stack_allocTheory.word_gen_gc_move_refs_code_def |> inline_simp |> conv64);
val _ = translate (stack_allocTheory.word_gen_gc_move_loop_code_def |> inline_simp |> conv64);
val _ = translate (stack_allocTheory.word_gen_gc_partial_move_code_def |> inline_simp |> conv64);
val _ = translate (stack_allocTheory.word_gen_gc_partial_move_bitmap_code_def |> inline_simp |> conv64);
val _ = translate (stack_allocTheory.word_gen_gc_partial_move_bitmaps_code_def |> inline_simp |> conv64);
val _ = translate (stack_allocTheory.word_gen_gc_partial_move_roots_bitmaps_code_def |> inline_simp |> conv64);
val _ = translate (stack_allocTheory.word_gen_gc_partial_move_list_code_def |> inline_simp |> conv64);
val _ = translate (stack_allocTheory.word_gen_gc_partial_move_ref_list_code_def |> inline_simp |> conv64);
val _ = translate (stack_allocTheory.word_gen_gc_partial_move_data_code_def |> inline_simp |> conv64);
val r = translate (stack_allocTheory.word_gc_partial_or_full_def |> inline_simp |> conv64);
val r = translate (stack_allocTheory.word_gc_code_def |> inline_simp |> conv64);

val _ = translate (spec64 stubs_def);

val _ = translate (spec64 comp_def(*pmatch*));

val _ = translate (spec64 compile_def);

(*
val stack_alloc_comp_side = Q.prove(`
  ∀n m prog. stack_alloc_comp_side n m prog ⇔ T`,
`(∀prog n m. stack_alloc_comp_side n m prog ⇔ T) ∧
 (∀opt prog (x:num) (y:num) (z:num) n m. opt = SOME(prog,x,y,z) ⇒ stack_alloc_comp_side n m prog ⇔ T) ∧
 (∀opt prog (x:num) (y:num) (z:num) n m. opt = (prog,x,y,z) ⇒ stack_alloc_comp_side n m prog ⇔ T) ∧
 (∀opt prog (x:num) (y:num) n m. opt = SOME(prog,x,y) ⇒ stack_alloc_comp_side n m prog ⇔ T) ∧
 (∀opt prog (x:num) (y:num) n m. opt = (prog,x,y) ⇒ stack_alloc_comp_side n m prog ⇔ T)`
  suffices_by fs[]
  >> ho_match_mp_tac(TypeBase.induction_of ``:64 stackLang$prog``)
  >> fs[]
  >> rpt strip_tac
  >> rw[Once(fetch "-" "stack_alloc_comp_side_def")]
  >> fs[]
  >> metis_tac[option_nchotomy, pair_CASES]) |> update_precondition

val stack_alloc_prog_comp_side = Q.prove(`∀prog. stack_alloc_prog_comp_side prog ⇔ T`,
  fs[fetch "-" "stack_alloc_prog_comp_side_def", stack_alloc_comp_side]) |> update_precondition;

val stack_alloc_compile_side = Q.prove(`∀conf prog. stack_alloc_compile_side conf prog ⇔ T`,
  fs[fetch "-" "stack_alloc_compile_side_def", stack_alloc_prog_comp_side]) |> update_precondition;
*)

open stack_removeTheory

(* Might be better to inline this *)
val _ = translate (conv64 word_offset_def)
val _ = translate (conv64 store_offset_def |> SIMP_RULE std_ss [word_mul_def,word_2comp_def] |> conv64)

val _ = translate (comp_def |> inline_simp |> conv64)

val _ = translate (prog_comp_def |> INST_TYPE [beta|->``:64``])

val _ = translate (store_list_code_def |> inline_simp |> conv64)
val _ = translate (init_memory_def |> inline_simp |> conv64)
val _ = translate (init_code_def |> inline_simp |> conv64 |> SIMP_RULE std_ss [word_mul_def]|>gconv|>SIMP_RULE std_ss[w2n_n2w] |> conv64)

val _ = translate (spec64 compile_def)

open stack_namesTheory

val _ = translate (spec64 comp_def)
val _ = translate (prog_comp_def |> INST_TYPE [beta |-> ``:64``])
val _ = translate (compile_def |> INST_TYPE [beta |-> ``:64``])

open stack_to_labTheory

val _ = matches := [``foo:'a labLang$prog``,``foo:'a
  labLang$sec``,``foo:'a labLang$line``,``foo:'a
  labLang$asm_with_lab``,``foo:'a labLang$line list``,``foo:'a
  inst``,``foo:'a asm_config``] @ (!matches)

val _ = translate (flatten_def |> spec64)

val _ = translate (compile_def |> spec64)

open lab_filterTheory lab_to_targetTheory asmTheory
open monadic_encTheory
open ml_monad_translatorLib;

(* The record types used for the monadic state and exceptions *)
val state_type = ``:enc_state_64``;
val exn_type   = ``:monadic_enc$state_exn``;
val _          = register_exn_type exn_type;

val STATE_EXN_TYPE_def =  theorem "MONADIC_ENC_STATE_EXN_TYPE_def"
val exn_ri_def         = STATE_EXN_TYPE_def;
val store_hprop_name   = "ENC_STATE_64";

(* Accessor functions are defined (and used) previously together
   with exceptions, etc. *)

val exn_functions = [
    (raise_Fail_def, handle_Fail_def),
    (raise_Subscript_def, handle_Subscript_def)
];

val refs_manip_list = [] : (string * thm * thm) list;
val rarrays_manip_list = [] : (string * thm * thm * thm * thm * thm * thm) list;
val farrays_manip_list = [
    ("hash_tab", get_hash_tab_def, set_hash_tab_def, hash_tab_length_def, hash_tab_sub_def, update_hash_tab_def)];

val add_type_theories  = ([] : string list);
val store_pinv_def_opt = NONE : thm option;

val _ = translate (hash_reg_imm_def |> INST_TYPE [alpha|->``:64``])
val _ = translate hash_binop_def
val _ = translate hash_cmp_def
val _ = translate hash_shift_def
val _ = translate (hash_arith_def |> INST_TYPE [alpha|->``:64``])
val _ = translate hash_memop_def
val _ = translate hash_fp_def
val _ = translate (hash_inst_def |> INST_TYPE [alpha|->``:64``])
val _ = translate (hash_asm_def |> INST_TYPE [alpha|->``:64``])

(* Initialization *)

val res = start_dynamic_init_fixed_store_translation
            refs_manip_list
            rarrays_manip_list
            farrays_manip_list
            store_hprop_name
            state_type
            exn_ri_def
            exn_functions
            add_type_theories
            store_pinv_def_opt;

val _ = translate (lab_inst_def |> INST_TYPE [alpha |-> ``:64``])
val _ = translate (cbw_to_asm_def |> INST_TYPE [alpha |-> ``:64``])
val _ = m_translate lookup_insert_table_def;
val _ = m_translate enc_line_hash_def;

val _ = ParseExtras.temp_tight_equality();
val _ = monadsyntax.temp_add_monadsyntax()

val _ = temp_overload_on ("monad_bind", ``st_ex_bind``);
val _ = temp_overload_on ("monad_unitbind", ``\x y. st_ex_bind x (\z. y)``);
val _ = temp_overload_on ("monad_ignore_bind", ``\x y. st_ex_bind x (\z. y)``);
val _ = temp_overload_on ("return", ``st_ex_return``);

val enc_line_hash_ls_def = Define`
  (enc_line_hash_ls enc skip_len n [] = return []) ∧
  (enc_line_hash_ls enc skip_len n (x::xs) =
  do
    fx <- enc_line_hash enc skip_len n x;
    fxs <- enc_line_hash_ls enc skip_len n xs;
    return (fx::fxs)
  od)`

val _ = m_translate enc_line_hash_ls_def;

val enc_sec_hash_ls_def = Define`
  (enc_sec_hash_ls enc skip_len n [] = return []) ∧
  (enc_sec_hash_ls enc skip_len n (x::xs) =
  case x of Section k ys =>
  do
    ls <- enc_line_hash_ls enc skip_len n ys;
    rest <- enc_sec_hash_ls enc skip_len n xs;
    return (Section k ls::rest)
  od)`

val _ = m_translate enc_sec_hash_ls_def;

val enc_sec_hash_ls_full_def = Define`
  enc_sec_hash_ls_full enc n xs =
  enc_sec_hash_ls enc (LENGTH (enc (Inst Skip))) n xs`

val _ = m_translate enc_sec_hash_ls_full_def;

val enc_line_hash_eq = Q.prove(`
  ∀ls s.
  st_ex_MAP (enc_line_hash enc n l) ls s =
  enc_line_hash_ls enc n l ls s`,
  Induct>>rw[]>>EVAL_TAC>>
  simp[]);

val enc_sec_hash_eq = Q.prove(`
  ∀xs s.
   st_ex_MAP (enc_sec_hash enc (LENGTH (enc (Inst Skip))) n) xs s =
   enc_sec_hash_ls enc (LENGTH (enc (Inst Skip))) n xs s`,
  Induct>>rw[]>>EVAL_TAC>>
  Cases_on`h`>>EVAL_TAC>>
  simp[enc_line_hash_eq]>>
  every_case_tac>>fs[]);

val enc_secs_aux_trans_def = Q.prove(
 `∀enc n xs st.
     enc_secs_aux enc n xs =
     run_ienc_state_64 (enc_sec_hash_ls_full enc n xs)
       <| hash_tab := (n,[]) |>`,
  simp[enc_secs_aux_def,enc_sec_hash_ls_full_def,run_ienc_state_64_def]>>
  rw[enc_sec_list_hash_def]>>
  AP_THM_TAC>>
  AP_TERM_TAC>>
  metis_tac[enc_sec_hash_eq]);

val _ = m_translate_run enc_secs_aux_trans_def;

val _ = translate enc_secs_def;

val to_target64prog_enc_line_hash_ls_side_def = Q.prove(`
  ∀a b c d e.
  d ≠ 0 ⇒
  to_target64prog_enc_line_hash_ls_side a b c d e ⇔ T`,
  Induct_on`e`>>
  simp[Once (fetch "-" "to_target64prog_enc_line_hash_ls_side_def")]>>
  EVAL_TAC>>rw[]>>fs[]);

val to_target64prog_enc_sec_hash_ls_side_def = Q.prove(`
  ∀a b c d e.
  d ≠ 0 ⇒
  to_target64prog_enc_sec_hash_ls_side a b c d e ⇔ T`,
  Induct_on`e`>>
  simp[Once (fetch "-" "to_target64prog_enc_sec_hash_ls_side_def")]>>
  metis_tac[to_target64prog_enc_line_hash_ls_side_def]);

Theorem monadic_enc_enc_secs_side_def
  `monadic_enc_enc_secs_side a b c ⇔ T`
  (EVAL_TAC>>
  rw[]>>
  metis_tac[to_target64prog_enc_sec_hash_ls_side_def,DECIDE``1n ≠ 0``])
  |> update_precondition;

val _ = translate (spec64 filter_skip_def)

val _ = translate (get_jump_offset_def |>INST_TYPE [alpha|->``:64``,beta |-> ``:64``])

val word_2compl_eq = prove(
  ``!w:'a word. -w = 0w - w``,
  fs []);

val _ = translate (conv64 reg_imm_ok_def |> SIMP_RULE std_ss [IN_INSERT,NOT_IN_EMPTY,
                                               word_2compl_eq])

val _ = translate (conv64 arith_ok_def |> SIMP_RULE std_ss [IN_INSERT,NOT_IN_EMPTY])

val _ = translate (fp_ok_def |> conv64)
val _ = translate (conv64 inst_ok_def |> SIMP_RULE std_ss [IN_INSERT,NOT_IN_EMPTY])

(* TODO: there may be a better rewrite for aligned (in to_word64Prog's translation of offset_ok) *)

val _ = translate (spec64 asmTheory.asm_ok_def)

val _ = translate (spec64 remove_labels_def |> REWRITE_RULE [GSYM monadic_encTheory.enc_secs_correct])

val _ = translate (spec64 compile_def)

val () = Feedback.set_trace "TheoryPP.include_docs" 0;

val _ = ml_translatorLib.ml_prog_update (ml_progLib.close_module NONE);

val _ = (ml_translatorLib.clean_on_exit := true);

val _ = export_theory();
