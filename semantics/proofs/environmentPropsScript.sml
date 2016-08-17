open preamble;
open astTheory;
open environmentTheory;
open terminationTheory;

val _ = new_theory "environmentProps";

val mk_id_11 = Q.store_thm("mk_id_11[simp]",
  `!a b c d. mk_id a b = mk_id c d ⇔ (a = c) ∧ (b = d)`,
 Induct_on `a`
 >> Cases_on `c`
 >> rw [mk_id_def]
 >> metis_tac []);


(* ----------- Monotonicity for Hol_reln ------------ *)

val eAll_mono = Q.store_thm ("eAll_mono[mono]",
  `(!id x. P id x ⇒ Q id x) ⇒ eAll P e ⇒ eAll Q e`,
  rw [eAll_def]);

val eSubEnv_mono = Q.store_thm ("eSubEnv_mono[mono]",
  `(!x y z. R1 x y z ⇒ R2 x y z) ⇒ (eSubEnv R1 e1 e2 ⇒ eSubEnv R2 e1 e2)`,
 Cases_on `e1`
 >> Cases_on `e2`
 >> simp [eSubEnv_def, eLookup_def]
 >> rw []
 >> metis_tac []);

val eAll2_mono = Q.store_thm ("eAll2_mono[mono]",
  `(!x y z. R1 x y z ⇒ R2 x y z) ⇒ eAll2 R1 e1 e2 ⇒ eAll2 R2 e1 e2`,
 rw [eAll2_def]
 >> irule eSubEnv_mono
 >> rw []
 >- metis_tac []
 >> qexists_tac `\x y z. R1 x z y`
 >> rw []);

(* ---------- Automatic simps involving empty envs -------------- *)

val eLookup_eEmpty = Q.store_thm ("eLookup_eEmpty[simp]",
  `!id. eLookup eEmpty id = NONE`,
 Cases
 >> rw [eLookup_def, eEmpty_def]);

val eAppend_eEmpty = Q.store_thm ("eAppend_eEmpty[simp]",
  `!env. eAppend env eEmpty = env ∧ eAppend eEmpty env = env`,
 Cases
 >> rw [eAppend_def, eEmpty_def]);

val alist_to_env_nil = Q.store_thm ("alist_to_env_nil[simp]",
  `alist_to_env [] = eEmpty`,
 rw [alist_to_env_def, eEmpty_def]);

val eSubEnv_eEmpty = Q.store_thm ("eSubEnv_eEmpty[simp]",
  `!r env. eSubEnv r eEmpty env`,
 rw [eSubEnv_def]
 >> Induct_on `path`
 >> Cases_on `env`
 >> fs [eLookupMod_def, eEmpty_def]);

val eAll_eEmpty = Q.store_thm ("eAll_eEmpty[simp]",
  `!f. eAll f eEmpty`,
 rw [eEmpty_def, eAll_def]);

val eAll2_eEmpty = Q.store_thm ("eAll2_eEmpty[simp]",
  `!f. eAll2 f eEmpty eEmpty`,
 rw [eEmpty_def, eAll2_def]);

val eDom_eEmpty = Q.store_thm ("eDom_eEmpty[simp]",
  `eDom eEmpty = {}`,
 rw [eDom_def, eEmpty_def, EXTENSION, GSPECIFICATION]
 >> pairarg_tac
 >> rw []);

val eMap_eEmpty = Q.store_thm ("eMap_eEmpty[simp]",
  `!f. eMap f eEmpty = eEmpty`,
 rw [eMap_def, eEmpty_def]);

(* ------------- Other simple automatic theorems --------- *)

val alist_to_env_cons = Q.store_thm ("alist_to_env_cons[simp]",
  `!k v l. alist_to_env ((k,v)::l) = eBind k v (alist_to_env l)`,
 rw [alist_to_env_def, eBind_def]);

val eAppend_eBind = Q.store_thm ("eAppend_eBind[simp]",
  `!k v e1 e2. eAppend (eBind k v e1) e2 = eBind k v (eAppend e1 e2)`,
 Cases_on `e1`
 >> Cases_on `e2`
 >> rw [eAppend_def, eBind_def]);

val eAppend_alist_to_env = Q.store_thm ("eAppend_alist_to_env[simp]",
  `!al1 al2. eAppend (alist_to_env al1) (alist_to_env al2) = alist_to_env (al1 ++ al2)`,
 rw [alist_to_env_def, eAppend_def]);

val eAppend_assoc = Q.store_thm ("eAppend_assoc[simp]",
  `!e1 e2 e3. eAppend e1 (eAppend e2 e3) = eAppend (eAppend e1 e2) e3`,
 rpt Cases
 >> rw [eAppend_def]);

val eLookup_eBind = Q.store_thm ("eLookup_eBind[simp]",
  `(!n v e. eLookup (eBind n v e) (Short n) = SOME v) ∧
   (!n n' v e. n ≠ Short n' ⇒ eLookup (eBind n' v e) n = eLookup e n)`,
 rw []
 >> Cases_on `e`
 >> TRY (Cases_on `n`)
 >> rw [eLookup_def, eBind_def]);

val eAppend_eSing = Q.store_thm ("eAppend_eSing[simp]",
  `!n x e. eAppend (eSing n x) e = eBind n x e`,
 rw [eSing_def]
 >> Cases_on `e`
 >> simp [eBind_def, eAppend_def]);

val eLookup_eSing = Q.store_thm ("eLookup_eSing[simp]",
  `!n v id. eLookup (eSing n v) id = if id = Short n then SOME v else NONE`,
 rw [eSing_def, eLookup_def]
 >> Cases_on` id`
 >> fs [eLookup_def]);

val eAll_eSing = Q.store_thm ("eAll_eSing[simp]",
  `!R n v. eAll R (eSing n v) ⇔ R (Short n) v`,
 rw [eAll_def, eSing_def]
 >> eq_tac
 >> rw [eLookup_def]
 >> Cases_on `id`
 >> fs [eLookup_def]);

val eAll2_eSing = Q.store_thm ("eAll2_eSing[simp]",
  `!R n1 v1 n2 v2. eAll2 R (eSing n1 v1) (eSing n2 v2) ⇔ n1 = n2 ∧ R (Short n1) v1 v2`,
 rw [eAll2_def, eSubEnv_def]
 >> eq_tac
 >- metis_tac []
 >> rw []
 >> rw []
 >> Cases_on `path`
 >> fs [eSing_def, eLookupMod_def]);

(* -------------- eLift --------------- *)

val eLookup_eLift = Q.store_thm ("eLookup_eLift",
  `!mn e id.
    eLookup (eLift mn e) id =
    case id of
    | Long mn' id' =>
      if mn = mn' then
        eLookup e id'
      else
        NONE
    | Short _ => NONE`,
 rw [eLift_def]
 >> CASE_TAC
 >> rw [eLookup_def]);

val eLookupMod_eLift = Q.store_thm ("eLookupMod_eLift",
  `!mn e path.
    eLookupMod (eLift mn e) path =
    case path of
    | [] => SOME (eLift mn e)
    | (mn'::path') =>
      if mn = mn' then
        eLookupMod e path'
      else
        NONE`,
 rw [eLift_def]
 >> CASE_TAC
 >> rw [eLookupMod_def]);

(* --------------- eAppend ------------- *)

val eLookup_eAppend_none = Q.store_thm ("eLookup_eAppend_none",
  `∀e1 id e2.
    eLookup e1 id = NONE ∧ eLookup e2 id = NONE
    ⇒
    eLookup (eAppend e1 e2) id = NONE`,
 ho_match_mp_tac eLookup_ind
 >> rw []
 >> Cases_on `e2`
 >> fs [eAppend_def, eLookup_def, ALOOKUP_APPEND]
 >> every_case_tac
 >> fs []);

val eLookup_eAppend_none = Q.store_thm ("eLookup_eAppend_none",
  `∀e1 id e2.
    eLookup (eAppend e1 e2) id = NONE
    ⇔
    (eLookup e1 id = NONE ∧
     (eLookup e2 id = NONE ∨
      ?p1 p2 e3. p1 ≠ [] ∧ id_to_mods id = p1++p2 ∧ eLookupMod e1 p1 = SOME e3))`,
 ho_match_mp_tac eLookup_ind
 >> rw []
 >> Cases_on `e2`
 >> fs [eAppend_def, eLookup_def, ALOOKUP_APPEND]
 >> every_case_tac
 >> fs [id_to_mods_def, eLookupMod_def]
 >> eq_tac
 >> rw []
 >- (
   Cases_on `p1`
   >> fs [eLookupMod_def]
   >> rfs [])
 >> rw [METIS_PROVE [] ``x ∨ y ⇔ ~x ⇒ y``]
 >> qexists_tac `[mn]`
 >> simp [eLookupMod_def]);

val eLookup_eAppend_some = Q.store_thm ("eLookup_eAppend_some",
  `∀e1 id e2 v.
    eLookup (eAppend e1 e2) id = SOME v
    ⇔
    eLookup e1 id = SOME v ∨
    (eLookup e1 id = NONE ∧ eLookup e2 id = SOME v ∧
     !p1 p2. p1 ≠ [] ∧ id_to_mods id = p1++p2 ⇒ eLookupMod e1 p1 = NONE)`,
 ho_match_mp_tac eLookup_ind
 >> rw []
 >> Cases_on `e2`
 >> fs [eAppend_def, eLookup_def, ALOOKUP_APPEND]
 >> every_case_tac
 >> fs [id_to_mods_def]
 >> eq_tac
 >> rw []
 >> fs []
 >- (
   Cases_on `p1`
   >> fs [eLookupMod_def])
 >> first_x_assum (qspec_then `[mn]` mp_tac)
 >> simp [eLookupMod_def]);

val eAppend_to_eBindList = Q.store_thm ("eAppend_to_eBindList",
  `!l. eAppend (alist_to_env l) e = eBindList l e`,
 Induct_on `l`
 >> fs [eBindList_def, alist_to_env_def]
 >> rw []
 >> pairarg_tac
 >> simp []
 >> Cases_on `e`
 >> fs [eAppend_def]
 >> metis_tac [eAppend_def, eBind_def]);

val eLookupMod_eAppend_none = Q.store_thm ("eLookupMod_eAppend_none",
  `!e1 e2 path.
    eLookupMod (eAppend e1 e2) path = NONE
    ⇔
    (eLookupMod e1 path = NONE ∧
     (eLookupMod e2 path = NONE ∨
      ?p1 p2 e3. p1 ≠ [] ∧ path = p1++p2 ∧ eLookupMod e1 p1 = SOME e3))`,
 Induct_on `path`
 >> rw []
 >> Cases_on `e2`
 >> Cases_on `e1`
 >> fs [eAppend_def, eLookupMod_def, ALOOKUP_APPEND]
 >> every_case_tac
 >> fs []
 >> eq_tac
 >> rw []
 >- (
   Cases_on `p1`
   >> fs [eLookupMod_def]
   >> rfs [])
 >> rw [METIS_PROVE [] ``x ∨ y ⇔ ~x ⇒ y``]
 >> qexists_tac `[h]`
 >> simp [eLookupMod_def]);


(* -------------- eAll ---------------- *)

val eAll_T = Q.store_thm ("eALL_T[simp]",
  `!e. eAll (\n x. T) e`,
 rw [eAll_def]);

val eLookup_eAll = Q.store_thm ("eLookup_eAll",
  `!env x P v. eAll P env ∧ eLookup env x = SOME v ⇒ P x v`,
 rw [eAll_def]);

val eAll_eAppend = Q.store_thm ("eAll_eAppend",
  `!f e1 e2. eAll f e1 ∧ eAll f e2 ⇒ eAll f (eAppend e1 e2)`,
 simp [eAll_def, PULL_FORALL]
 >> rpt gen_tac
 >> qspec_tac (`v`, `v`)
 >> qspec_tac (`e2`, `e2`)
 >> qspec_tac (`id`, `id`)
 >> qspec_tac (`e1`, `e1`)
 >> ho_match_mp_tac eLookup_ind
 >> rw []
 >> Cases_on `e2`
 >> fs [eAppend_def, eLookup_def, ALOOKUP_APPEND]
 >> every_case_tac
 >> fs [GSYM PULL_FORALL]
 >- metis_tac [eLookup_def]
 >- metis_tac [eLookup_def]
 >> rw []
 >> rpt (first_x_assum (qspec_then `Long mn id` mp_tac))
 >> simp [eLookup_def]);

val eAll_eBind = Q.store_thm ("eAll_eBind",
  `!P x v e. P (Short x) v ∧ eAll P e ⇒ eAll P (eBind x v e)`,
 rw [eAll_def, eBind_def]
 >> Cases_on `id = Short x`
 >> fs []);

val eAll_eOptBind = Q.store_thm ("eAll_eOptBind",
  `!P x v e. (x = NONE ∨ ?n. x = SOME n ∧ P (Short n) v) ∧ eAll P e ⇒ eAll P (eOptBind x v e)`,
 rw [eAll_def, eOptBind_def]
 >> every_case_tac
 >> fs []
 >> Cases_on `id`
 >> fs [eLookup_def, eBind_def]
 >> Cases_on `a = x`
 >> fs []);

val eAll_alist_to_env = Q.store_thm ("eAll_alist_to_env",
  `!R l. EVERY (λ(n,v). R (Short n) v) l ⇒ eAll R (alist_to_env l)`,
 Induct_on `l`
 >> rw [eAll_def, alist_to_env_def]
 >> pairarg_tac
 >> fs []
 >> Cases_on `id`
 >> fs [eLookup_def]
 >> every_case_tac
 >> fs [EVERY_MEM, LAMBDA_PROD, FORALL_PROD]
 >> rw []
 >> drule ALOOKUP_MEM
 >> metis_tac []);

val eAll_eLift = Q.store_thm ("eAll_eLift[simp]",
  `!R mn e. eAll R (eLift mn e) ⇔ eAll (\id. R (Long mn id)) e`,
 rw [eAll_def, eLookup_eLift]
 >> eq_tac
 >> rw []
 >> every_case_tac
 >> fs []);

(* -------------- eSubEnv ---------------- *)

val eSubEnv_conj = Q.store_thm ("eSubEnv_conj",
  `!P Q e1 e2. eSubEnv (\id x y. P id x y ∧ Q id x y) e1 e2 ⇔ eSubEnv P e1 e2 ∧ eSubEnv Q e1 e2`,
 rw [eSubEnv_def]
 >> eq_tac
 >> rw []
 >> metis_tac [SOME_11]);

val eSubEnv_refl = Q.store_thm ("eSubEnv_refl",
  `!P R. (!n x. P n x ⇒ R n x x) ⇒ !e. eAll P e ⇒ eSubEnv R e e`,
 rw [eSubEnv_def]
 >> metis_tac [eLookup_eAll]);

val eSubEnv_eBind = Q.store_thm ("eSubEnv_eBind",
  `!R x v1 v2 e1 e2.
     R (Short x) v1 v2 ∧ eSubEnv R e1 e2 ⇒ eSubEnv R (eBind x v1 e1) (eBind x v2 e2)`,
 rw [eBind_def, eSubEnv_def]
 >- (
   Cases_on `id = Short x`
   >> fs [])
 >> first_x_assum (qspec_then `path` mp_tac)
 >> Cases_on `path`
 >> fs [eBind_def, eLookupMod_def]
 >> Cases_on `e1`
 >> Cases_on `e2`
 >> fs [eBind_def, eLookupMod_def]);

val eSubEnv_eAppend2 = Q.store_thm ("eSubEnv_eAppend2",
  `!R e1 e2 e2'. eSubEnv R e1 e1 ∧ eSubEnv R e2 e2' ⇒ eSubEnv R (eAppend e1 e2) (eAppend e1 e2')`,
 rw [eSubEnv_def, eLookup_eAppend_some, eLookupMod_eAppend_none]
 >> rw [eSubEnv_def, eLookup_eAppend_some, eLookupMod_eAppend_none]
 >> metis_tac [NOT_SOME_NONE, SOME_11, option_nchotomy]);

val eSubEnv_eAppend_lift = Q.store_thm ("eSubEnv_eAppend_lift",
  `!R mn e1 e1' e2 e2'.
    eSubEnv (\id. R (Long mn id)) e1 e1' ∧
    eSubEnv R e2 e2'
    ⇒
    eSubEnv R (eAppend (eLift mn e1) e2) (eAppend (eLift mn e1') e2')`,
 rw [eSubEnv_def, eLookup_eAppend_some, eLookupMod_eAppend_none,
     eLookupMod_eLift, eLookup_eLift]
 >> rw [eSubEnv_def, eLookup_eAppend_some, eLookupMod_eAppend_none,
     eLookupMod_eLift, eLookup_eLift]
 >> every_case_tac
 >> fs []
 >> rw []
 >> res_tac
 >> fs [id_to_mods_def]
 >> rw []
 >> every_case_tac
 >> fs []
 >- (
   first_x_assum (qspecl_then [`[mn]`, `id_to_mods i`] mp_tac)
   >> simp [eLookupMod_def])
 >- (
   disj2_tac
   >> qexists_tac `[h]`
   >> simp [eLookupMod_def]));

val alist_rel_restr_def = Define `
  (alist_rel_restr R l1 l2 [] ⇔ T) ∧
  (alist_rel_restr R l1 l2 (k1::keys) ⇔
    case ALOOKUP l1 k1 of
    | NONE => F
    | SOME v1 =>
      case ALOOKUP l2 k1 of
      | NONE => F
      | SOME v2 => R k1 v1 v2 ∧ alist_rel_restr R l1 l2 keys)`;

val alist_rel_restr_thm = Q.store_thm ("alist_rel_restr_thm",
  `!R e1 e2 keys.
    alist_rel_restr R e1 e2 keys ⇔
      !k. MEM k keys ⇒ ?v1 v2. ALOOKUP e1 k = SOME v1 ∧ ALOOKUP e2 k = SOME v2 ∧ R k v1 v2`,
 Induct_on `keys`
 >> rw [alist_rel_restr_def]
 >> every_case_tac
 >> fs []
 >> metis_tac [NOT_SOME_NONE, SOME_11, option_nchotomy]);

val alistSub_def = Define `
  alistSub R e1 e2 ⇔ alist_rel_restr R e1 e2 (MAP FST e1)`;

val alistSub_cong = Q.store_thm ("alistSub_cong",
  `!l1 l2 l1' l2' R R'.
    l1 = l1' ∧ l2 = l2' ∧ (!n x y. ALOOKUP l1' n = SOME x ∧ ALOOKUP l2' n = SOME y ⇒ R n x y = R' n x y) ⇒
    (alistSub R l1 l2 ⇔ alistSub R' l1' l2')`,
  rw [alistSub_def]
  >> qspec_tac (`MAP FST l1`, `keys`)
  >> Induct
  >> rw [alist_rel_restr_def]
  >> every_case_tac
  >> metis_tac []);

val _ = DefnBase.export_cong "alistSub_cong";

val eSubEnv_compute_def = tDefine "eSubEnv_compute" `
  eSubEnv_compute path R (Bind e1V e1M) (Bind e2V e2M) ⇔
    alistSub (\k v1 v2. R (mk_id (REVERSE path) k) v1 v2) e1V e2V ∧
    alistSub (\k v1 v2. eSubEnv_compute (k::path) R v1 v2) e1M e2M`
 (wf_rel_tac `measure (\(p,r,env,_). environment_size (\x.0) (\x.0) env)`
 >> rw []
 >> Induct_on `e1M`
 >> rw [environment_size_def]
 >> PairCases_on `h`
 >> fs [ALOOKUP_def]
 >> every_case_tac
 >> fs []
 >> rw [environment_size_def]);

val eLookup_FOLDR_eLift = Q.store_thm ("eLookup_FOLDR_eLift",
  `!e p k. eLookup (FOLDR eLift e p) (mk_id p k) = eLookup e (Short k)`,
 Induct_on `p`
 >> rw [mk_id_def, eLookup_def, eLift_def]);

val mk_id_thm = Q.store_thm ("mk_id_thm",
  `!id. mk_id (id_to_mods id) (id_to_n id) = id`,
 Induct_on `id`
 >> rw [id_to_mods_def, id_to_n_def, mk_id_def]);

val eLookup_FOLDR_eLift_some = Q.store_thm ("eLookup_FOLDR_eLift_some",
  `!e p id v.
    eLookup (FOLDR eLift e p) id = SOME v ⇔
    (p = [] ∧ eLookup e id = SOME v) ∨
    (p ≠ [] ∧ ?p2 n. id = mk_id (p++p2) n ∧ eLookup e (mk_id p2 n) = SOME v)`,
 Induct_on `p`
 >> rw [eLift_def]
 >> Cases_on `id`
 >> rw [eLookup_def, mk_id_def]
 >> Cases_on `p`
 >> rw []
 >> eq_tac
 >> rw []
 >> rw []
 >> qexists_tac `id_to_mods i`
 >> qexists_tac `id_to_n i`
 >> rw [mk_id_thm]);

val eLookupMod_FOLDR_eLift_none = Q.store_thm ("eLookupMod_FOLDR_eLift_none",
  `!e p1 p2. eLookupMod (FOLDR eLift e p1) p2 = NONE ⇔
    (IS_PREFIX p1 p2 ∨ IS_PREFIX p2 p1) ⇒
    ?p3. p2 = p1++p3 ∧ eLookupMod e p3 = NONE`,
 Induct_on `p1`
 >> rw [eLift_def]
 >> Cases_on `p2`
 >> rw [eLookupMod_def, mk_id_def]);

val eSubEnv_compute_thm = Q.store_thm ("envSub_compute_thm",
  `!p R e1 e2.
    eSubEnv R (FOLDR eLift e1 (REVERSE p)) (FOLDR eLift e2 (REVERSE p)) ⇔
    eSubEnv_compute p R e1 e2`,
 ho_match_mp_tac (theorem "eSubEnv_compute_ind")
 >> rw [eSubEnv_def, eSubEnv_compute_def, alistSub_def, alist_rel_restr_thm, eLookup_def]
 >> eq_tac
 >> rw []
 >- (
   `?v1. ALOOKUP e1V k = SOME v1` by metis_tac [option_nchotomy, ALOOKUP_NONE]
   >> last_x_assum (qspec_then `mk_id (REVERSE p) k` mp_tac)
   >> simp [eLookup_FOLDR_eLift, eLookup_def])
 >- (
   `?v1. ALOOKUP e1M k = SOME v1` by metis_tac [option_nchotomy, ALOOKUP_NONE]
   >> last_assum (qspec_then `REVERSE (k::p)` assume_tac)
   >> fs [eLookupMod_FOLDR_eLift, eLookupMod_def]
   >> every_case_tac
   >> fs []
   >> first_x_assum drule
   >> disch_then drule
   >> disch_then (strip_assume_tac o GSYM)
   >> simp []
   >> pop_assum kall_tac
   >> rw []
   >- (
     fs [eLookup_FOLDR_eLift_some]
     >> first_x_assum (qspec_then `mk_id (REVERSE p++[k]++p2) n` mp_tac)
     >> Cases_on `p=[]`
     >> simp [eLookup_def, mk_id_def])
   >- (
     fs [eLookupMod_FOLDR_eLift_none]
     >> rw []
     >> fs []
     >> rw []
     >- (
       `p3 = []` by cheat
       >> fs [eLookupMod_def])
     >> last_x_assum (qspec_then `REVERSE p++[k]++p3` mp_tac)
     >> rw []
     >> fs [eLookupMod_def]
     >> every_case_tac
     >> fs []
     >> rw []
     >> metis_tac [IS_PREFIX_APPEND3, APPEND_ASSOC]))
 >> cheat);

(*
 >- (
   Cases_on `id`
   >> fs [eLookup_def, id_to_n_def, id_to_mods_def]
   >- (
     drule ALOOKUP_MEM
     >> rw []
     >> fs [MEM_MAP, PULL_EXISTS]
     >> first_x_assum drule
     >> simp [])
   >> every_case_tac
   >> fs []
   >> drule ALOOKUP_MEM
   >> strip_tac
   >> fs [MEM_MAP, PULL_EXISTS]
   >> first_x_assum drule
   >> fs []
   >> first_x_assum drule
   >> disch_then drule
   >> disch_then (strip_assume_tac o GSYM)
   >> simp []
   >> rw []
   >> first_x_assum drule
   >> rw []
   >> full_simp_tac std_ss [GSYM APPEND_ASSOC, APPEND])

 >- (
   Cases_on `path`
   >> fs [eLookupMod_def]
   >> every_case_tac
   >> fs []
   >> drule ALOOKUP_MEM
   >> rw []
   >- (
     fs [MEM_MAP, PULL_EXISTS]
     >> first_x_assum drule
     >> \r

 >> fs [eLookup_def]
 *)


(* -------------- eAll2 ---------------- *)

val eAll2_conj = Q.store_thm ("eAll2_conj",
  `!P Q e1 e2. eAll2 (\id x y. P id x y ∧ Q id x y) e1 e2 ⇔ eAll2 P e1 e2 ∧ eAll2 Q e1 e2`,
 rw [eAll2_def, eSubEnv_conj]
 >> metis_tac []);

val eAll2_eLookup1 = Q.store_thm ("eAll2_eLookup1",
  `!R e1 e2 n v1.
    eLookup e1 n = SOME v1 ∧
    eAll2 R e1 e2
    ⇒
    ?v2. eLookup e2 n = SOME v2 ∧ R n v1 v2`,
 rw [eSubEnv_def, eAll2_def]);

val eAll2_eLookup2 = Q.store_thm ("eAll2_eLookup2",
  `!R e1 e2 n v2.
    eLookup e2 n = SOME v2 ∧
    eAll2 R e1 e2
    ⇒
    ?v1. eLookup e1 n = SOME v1 ∧ R n v1 v2`,
 rw [eSubEnv_def, eAll2_def]
 >> metis_tac [NOT_SOME_NONE, option_nchotomy, SOME_11]);

val eAll2_eLookup_none = Q.store_thm ("eAll2_eLookup_none",
  `!R e1 e2 n.
    eAll2 R e1 e2
    ⇒
    (eLookup e1 n = NONE ⇔ eLookup e2 n = NONE)`,
 rw [eSubEnv_def, eAll2_def]
 >> metis_tac [NOT_SOME_NONE, option_nchotomy, SOME_11]);

val eAll2_eBind = Q.store_thm ("eAll2_eBind",
  `!R x v1 v2 e1 e2.
     R (Short x) v1 v2 ∧ eAll2 R e1 e2 ⇒ eAll2 R (eBind x v1 e1) (eBind x v2 e2)`,
 rw [eAll2_def]
 >> irule eSubEnv_eBind
 >> rw []);

val eAll2_eBindList = Q.store_thm ("eAll2_eBindList",
  `!R l1 l2 e1 e2.
     LIST_REL (\(x,y) (x',y'). x = x' ∧ R (Short x) y y') l1 l2 ∧ eAll2 R e1 e2
     ⇒
     eAll2 R (eBindList l1 e1) (eBindList l2 e2)`,
 Induct_on `l1`
 >> rw [eBindList_def]
 >> rw [eBindList_def]
 >> pairarg_tac
 >> rw []
 >> pairarg_tac
 >> rw []
 >> fs [eBindList_def]
 >> irule eAll2_eBind
 >> rw []);

val eAll2_eAppend = Q.store_thm ("eAll2_eAppend",
  `!R e1 e1' e2 e2'.
    eAll2 R e1 e2 ∧ eAll2 R e1' e2' ⇒ eAll2 R (eAppend e1 e1') (eAppend e2 e2')`,
 rw [eAll2_def, eSubEnv_def, eLookup_eAppend_some, eLookupMod_eAppend_none]
 >> metis_tac [NOT_SOME_NONE, SOME_11, option_nchotomy]);

val eAll2_alist_to_env = Q.store_thm ("eAll2_alist_to_env",
  `!R l1 l2. LIST_REL (\(x,y) (x',y'). x = x' ∧ R (Short x) y y') l1 l2 ⇒ eAll2 R (alist_to_env l1) (alist_to_env l2)`,
 Induct_on `l1`
 >> rw []
 >> pairarg_tac
 >> fs []
 >> pairarg_tac
 >> fs []
 >> rw []
 >> irule eAll2_eBind
 >> simp []);

val eAll2_eLift = Q.store_thm ("eAll2_eLift[simp]",
  `!R mn e1 e2. eAll2 R (eLift mn e1) (eLift mn e2) ⇔ eAll2 (\id. R (Long mn id)) e1 e2`,
 rw [eAll2_def, eSubEnv_def]
 >> eq_tac
 >> rw []
 >- (
   last_x_assum (qspec_then `Long mn id` mp_tac)
   >> simp [eLookup_eLift, eLookupMod_eLift])
 >- (
   last_x_assum (qspec_then `mn::path` mp_tac)
   >> simp [eLookup_eLift, eLookupMod_eLift])
 >- (
   first_x_assum (qspec_then `Long mn id` mp_tac)
   >> simp [eLookup_eLift, eLookupMod_eLift])
 >- (
   first_x_assum (qspec_then `mn::path` mp_tac)
   >> simp [eLookup_eLift, eLookupMod_eLift])
 >> pop_assum mp_tac
 >> simp [eLookup_eLift, eLookupMod_eLift]
 >> every_case_tac
 >> fs []);

val _ = export_theory ();
