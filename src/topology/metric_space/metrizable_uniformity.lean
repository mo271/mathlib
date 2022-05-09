import topology.metric_space.basic

/-!
-/

open set function metric list filter
open_locale nnreal filter uniformity

variables {X : Type*}

namespace pseudo_metric_space

noncomputable def of_prenndist (d : X → X → ℝ≥0) (dist_self : ∀ x, d x x = 0)
  (dist_comm : ∀ x y, d x y = d y x) :
  pseudo_metric_space X :=
{ dist := λ x y, ↑(⨅ l : list X, ((x :: l).zip_with d (l ++ [y])).sum : ℝ≥0),
  dist_self := λ x, (nnreal.coe_eq_zero _).2 $ nonpos_iff_eq_zero.1 $
    (cinfi_le (order_bot.bdd_below _) []).trans_eq $ by simp [dist_self],
  dist_comm := λ x y, nnreal.coe_eq.2 $
    begin
      rw [← reverse_surjective.infi_comp],
      refine congr_arg infi (funext $ λ l, _),
      rw [← sum_reverse, zip_with_distrib_reverse, reverse_append, reverse_reverse,
        reverse_singleton, singleton_append, reverse_cons, reverse_reverse,
        zip_with_comm _ dist_comm],
      simp
    end,
  dist_triangle := λ x y z,
    begin
      rw [← nnreal.coe_add, nnreal.coe_le_coe],
      refine nnreal.le_infi_add_infi (λ lxy lyz, _),
      calc (⨅ l, (zip_with d (x :: l) (l ++ [z])).sum) ≤
        (zip_with d (x :: (lxy ++ y :: lyz)) ((lxy ++ y :: lyz) ++ [z])).sum :
        cinfi_le (order_bot.bdd_below _) (lxy ++ y :: lyz)
      ... = (zip_with d (x :: lxy) (lxy ++ [y])).sum + (zip_with d (y :: lyz) (lyz ++ [z])).sum : _,
      rw [← sum_append, ← zip_with_append, cons_append, ← @singleton_append _ y, append_assoc,
        append_assoc, append_assoc],
      rw [length_cons, length_append, length_singleton]
    end }

lemma dist_of_prenndist_le (d : X → X → ℝ≥0) (dist_self : ∀ x, d x x = 0)
  (dist_comm : ∀ x y, d x y = d y x) (x y : X) :
  @dist X (@pseudo_metric_space.to_has_dist X
    (pseudo_metric_space.of_prenndist d dist_self dist_comm)) x y ≤ d x y :=
nnreal.coe_le_coe.2 $ (cinfi_le (order_bot.bdd_below _) []).trans_eq $ by simp

lemma le_two_mul_dist_of_prenndist (d : X → X → ℝ≥0) (dist_self : ∀ x, d x x = 0)
  (dist_comm : ∀ x y, d x y = d y x)
  (hd : ∀ x₁ x₂ x₃ x₄, d x₁ x₄ ≤ 2 * max (d x₁ x₂) (max (d x₂ x₃) (d x₃ x₄))) (x y : X) :
  ↑(d x y) ≤ 2 * @dist X (@pseudo_metric_space.to_has_dist X
    (pseudo_metric_space.of_prenndist d dist_self dist_comm)) x y :=
begin
  erw [← div_le_iff' (@two_pos ℝ _ _), ← nnreal.coe_two, ← nnreal.coe_div, nnreal.coe_le_coe],
  refine le_cinfi (λ l, nnreal.div_le_of_le_mul' _),
  have hd₀_trans : transitive (λ x y, d x y = 0),
  { intros a b c hab hbc,
    rw ← nonpos_iff_eq_zero,
    simpa [hab, hbc, dist_self] using hd a b c c },
  haveI : is_trans X (λ x y, d x y = 0) := ⟨hd₀_trans⟩,
  induction hn : length l using nat.strong_induction_on with n ihn generalizing x y l,
  simp only at ihn, subst n,
  set L := zip_with d (x :: l) (l ++ [y]),
  have hL_len : length L = length l + 1, by simp,
  cases eq_or_ne (d x y) 0 with hd₀ hd₀, { simp only [hd₀, zero_le] },
  suffices : ∃ z z' : X, d x z ≤ L.sum ∧ d z z' ≤ L.sum ∧ d z' y ≤ L.sum,
  { rcases this with ⟨z, z', hxz, hzz', hz'y⟩,
    exact (hd x z z' y).trans (mul_le_mul_left' (max_le hxz (max_le hzz' hz'y)) _) },
  set s : set ℕ := {m : ℕ | 2 * (take m L).sum ≤ L.sum},
  have hs₀ : 0 ∈ s, by simp [s],
  have hsne : s.nonempty, from ⟨0, hs₀⟩,
  obtain ⟨M, hMl, hMs⟩ : ∃ M ≤ length l, is_greatest s M,
  { have hs_ub : length l ∈ upper_bounds s,
    { intros m hm,
      rw [← not_lt, nat.lt_iff_add_one_le, ← hL_len],
      intro hLm,
      rw [mem_set_of_eq, take_all_of_le hLm, two_mul, add_le_iff_nonpos_left, nonpos_iff_eq_zero,
        sum_eq_zero_iff, ← all₂_iff_forall, all₂_zip_with, ← chain_append_singleton_iff_forall₂]
        at hm; [skip, by simp],
      exact hd₀ (hm.rel (mem_append.2 $ or.inr $ mem_singleton_self _)) },
    have hs_bdd : bdd_above s, from ⟨length l, hs_ub⟩,
    exact ⟨Sup s, cSup_le hsne hs_ub, ⟨nat.Sup_mem hsne hs_bdd, λ k, le_cSup hs_bdd⟩⟩ },
  have hM_lt : M < length L, by rwa [hL_len, nat.lt_succ_iff],
  have hM_ltx : M < length (x :: l), from lt_length_left_of_zip_with hM_lt,
  have hM_lty : M < length (l ++ [y]), from lt_length_right_of_zip_with hM_lt,
  refine ⟨(x :: l).nth_le M hM_ltx, (l ++ [y]).nth_le M hM_lty, _, _, _⟩,
  { cases M, { simp [dist_self] },
    rw nat.succ_le_iff at hMl,
    have hMl' : length (take M l) = M, from (length_take _ _).trans (min_eq_left hMl.le),
    simp only [nth_le],
    refine (ihn _ hMl _ _ _ hMl').trans _,
    convert hMs.1.out,
    rw [zip_with_distrib_take, take, take_succ, nth_append hMl, nth_le_nth hMl,
      ← option.coe_def, option.to_list_some, take_append_of_le_length hMl.le],
    refl },
  { refine single_le_sum (λ x hx, zero_le x) _ (mem_iff_nth_le.2 ⟨M, hM_lt, _⟩),
    apply nth_le_zip_with },
  { rcases hMl.eq_or_lt with rfl|hMl,
    { simp only [nth_le_append_right le_rfl, sub_self, nth_le_singleton, dist_self, zero_le] },
    rw [nth_le_append _ hMl],
    have hlen : length (drop (M + 1) l) = length l - (M + 1), from length_drop _ _,
    have hlen_lt : length l - (M + 1) < length l, from nat.sub_lt_of_pos_le _ _ M.succ_pos hMl,
    refine (ihn _ hlen_lt _ y _ hlen).trans _,
    rw [cons_nth_le_drop_succ],
    have hMs' : L.sum ≤ 2 * (L.take (M + 1)).sum,
      from not_lt.1 (λ h, (hMs.2 h.le).not_lt M.lt_succ_self),
    rw [← sum_take_add_sum_drop L (M + 1), two_mul, add_le_add_iff_left,
      ← add_le_add_iff_right, sum_take_add_sum_drop, ← two_mul] at hMs',
    convert hMs',
    rwa [zip_with_distrib_drop, drop, drop_append_of_le_length] }
end

end pseudo_metric_space

protected lemma uniform_space.metrizable_uniformity (X : Type*) [uniform_space X]
  [is_countably_generated (𝓤 X)] :
  ∃ I : pseudo_metric_space X, I.to_uniform_space = ‹_› :=
begin
  classical,
  obtain ⟨U, hU_symm, hU_comp, hB⟩ : ∃ U : ℕ → set (X × X), (∀ n, symmetric_rel (U n)) ∧
    (∀ ⦃m n⦄, m < n → (U n ○ U n) ○ (U n ○ U n) ⊆ U m) ∧ (𝓤 X).has_antitone_basis U,
  { rcases uniform_space.has_seq_basis X with ⟨V, hB, hV_symm⟩,
    rcases hB.subbasis_with_rel (λ m, hB.tendsto_small_sets.eventually
      (eventually_uniformity_iterate_comp_subset (hB.mem m) 2)) with ⟨φ, hφ_mono, hφ_comp, hφB⟩,
    exact ⟨V ∘ φ, λ n, hV_symm _, hφ_comp, hφB⟩ },
  letI := uniform_space.separation_setoid X,
  set d : X → X → ℝ≥0 := λ x y, if h : ∃ n, (x, y) ∉ U n then (1 / 2) ^ nat.find h else 0,
  have hd₀ : ∀ {x y}, d x y = 0 ↔ x ≈ y,
  { intros x y, dsimp only [d],
    refine iff.trans _ hB.to_has_basis.mem_separation_rel.symm,
    simp only [true_implies_iff],
    split_ifs with h,
    { rw [← not_forall] at h, simp [h, pow_eq_zero_iff'] },
    { simpa only [not_exists, not_not, eq_self_iff_true, true_iff] using h } },
  have hd_symm : ∀ x y, d x y = d y x,
  { intros x y, dsimp only [d],
    simp only [@symmetric_rel.mk_mem_comm _ _ (hU_symm _) x y] },
  have hr : (1 / 2 : ℝ≥0) ∈ Ioo (0 : ℝ≥0) 1,
    from ⟨nnreal.half_pos one_pos, nnreal.half_lt_self one_ne_zero⟩,
  letI := pseudo_metric_space.of_prenndist d (λ x, hd₀.2 (setoid.refl _)) hd_symm, 
  have hdist_le : ∀ x y, dist x y ≤ d x y,
    from pseudo_metric_space.dist_of_prenndist_le _ _ _,
  have hle_d : ∀ {x y : X} {n : ℕ}, (1 / 2) ^ n ≤ d x y ↔ (x, y) ∉ U n,
  { intros x y n,
    simp only [d], split_ifs with h,
    { rw [(strict_anti_pow hr.1 hr.2).le_iff_le, nat.find_le_iff],
      exact ⟨λ ⟨m, hmn, hm⟩ hn, hm (hB.antitone hmn hn), λ h, ⟨n, le_rfl, h⟩⟩ },
    { push_neg at h,
      simp only [h, not_true, (pow_pos hr.1 _).not_le] } },
  have hd_le : ∀ x y, ↑(d x y) ≤ 2 * dist x y,
  { refine pseudo_metric_space.le_two_mul_dist_of_prenndist _ _ _ (λ x₁ x₂ x₃ x₄, _),
    by_cases H : ∃ n, (x₁, x₄) ∉ U n,
    { refine (dif_pos H).trans_le _,
      rw [← nnreal.div_le_iff' two_ne_zero, ← mul_one_div (_ ^ _), ← pow_succ'],
      simp only [le_max_iff, hle_d, ← not_and_distrib],
      rintro ⟨h₁₂, h₂₃, h₃₄⟩,
      refine nat.find_spec H (hU_comp (lt_add_one $ nat.find H) _),
      exact ⟨x₂, ⟨x₁, refl_mem_uniformity (hB.mem _), h₁₂⟩, ⟨x₃, h₂₃, h₃₄⟩⟩ },
    { exact (dif_neg H).trans_le (zero_le _) } },
  refine ⟨infer_instance, uniform_space_eq $
    (uniformity_basis_dist_pow hr.1 hr.2).ext hB.to_has_basis _ _⟩,
  { refine λ n hn, ⟨n, hn, λ x hx, (hdist_le _ _).trans_lt _⟩,
    rwa [← nnreal.coe_pow, nnreal.coe_lt_coe, ← not_le, hle_d, not_not, prod.mk.eta] },
  { refine λ n hn, ⟨n + 1, trivial, λ x hx, _⟩,
    rw [mem_set_of_eq] at hx,
    contrapose! hx,
    refine le_trans _ ((div_le_iff' (@two_pos ℝ _ _)).2 (hd_le x.1 x.2)),
    rwa [← nnreal.coe_two, ← nnreal.coe_div, ← nnreal.coe_pow, nnreal.coe_le_coe, pow_succ',
      mul_one_div, nnreal.div_le_iff two_ne_zero, div_mul_cancel _ (@two_ne_zero ℝ≥0 _ _),
      hle_d, prod.mk.eta] }
end

protected noncomputable def uniform_space.pseudo_metric_space (X : Type*) [uniform_space X]
  [is_countably_generated (𝓤 X)] : pseudo_metric_space X :=
(uniform_space.metrizable_uniformity X).some.replace_uniformity $
  congr_arg _ (uniform_space.metrizable_uniformity X).some_spec.symm

protected noncomputable def uniform_space.metric_space (X : Type*) [uniform_space X]
  [is_countably_generated (𝓤 X)] [separated_space X] : metric_space X :=
@of_t2_pseudo_metric_space X (uniform_space.pseudo_metric_space X) ‹_›
