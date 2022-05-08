/-
Copyright (c) 2022 Rémy Degenne. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Rémy Degenne
-/

import probability.martingale

/-!
# Draft
-/

open_locale measure_theory
open topological_space

namespace measure_theory

section stopping

variables {α E ι : Type*} {m : measurable_space α} {μ : measure α}
  {𝒢 : filtration ℕ m} {τ σ : α → ℕ}
  [normed_group E] [normed_space ℝ E] [complete_space E]

lemma measurable_set_inter_le_iff [linear_order ι] {f : filtration ι m} {τ : α → ι}
  (hτ : is_stopping_time f τ) (s : set α) (i : ι) :
  measurable_set[hτ.measurable_space] (s ∩ {x | τ x ≤ i})
    ↔ measurable_set[(hτ.min_const i).measurable_space] (s ∩ {x | τ x ≤ i}) :=
begin
  rw [is_stopping_time.measurable_set_min_iff hτ (is_stopping_time_const _ i),
    is_stopping_time.measurable_space_const, is_stopping_time.measurable_set],
  refine ⟨λ h, ⟨h, _⟩, λ h j, h.1 j⟩,
  specialize h i,
  rwa [set.inter_assoc, set.inter_self] at h,
end

lemma measurable_set_inter_le' [linear_order ι] [topological_space ι]
  [second_countable_topology ι] [order_topology ι]
  [measurable_space ι] [borel_space ι] {f : filtration ι m} {τ σ : α → ι}
  (hτ : is_stopping_time f τ) (hσ : is_stopping_time f σ)
  (s : set α) (h : measurable_set[hτ.measurable_space] (s ∩ {x | τ x ≤ σ x})) :
  measurable_set[(hτ.min hσ).measurable_space] (s ∩ {x | τ x ≤ σ x}) :=
begin
  have : s ∩ {x | τ x ≤ σ x} = s ∩ {x | τ x ≤ σ x} ∩ {x | τ x ≤ σ x},
   by rw [set.inter_assoc, set.inter_self],
  rw this,
  exact is_stopping_time.measurable_set_inter_le _ _ _ h,
end

lemma measurable_set_inter_le_iff' [linear_order ι] [topological_space ι]
  [second_countable_topology ι] [order_topology ι]
  [measurable_space ι] [borel_space ι] {f : filtration ι m} {τ σ : α → ι}
  (hτ : is_stopping_time f τ) (hσ : is_stopping_time f σ)
  (s : set α) :
  measurable_set[hτ.measurable_space] (s ∩ {x | τ x ≤ σ x})
    ↔ measurable_set[(hτ.min hσ).measurable_space] (s ∩ {x | τ x ≤ σ x}) :=
begin
  refine ⟨λ h, measurable_set_inter_le' hτ hσ s h, λ h, _⟩,
  rw is_stopping_time.measurable_set_min_iff at h,
  exact h.1,
end

lemma measurable_set_le_stopping_time (hτ : is_stopping_time 𝒢 τ) (hσ : is_stopping_time 𝒢 σ) :
  measurable_set[hτ.measurable_space] {x | τ x ≤ σ x} :=
begin
  rw hτ.measurable_set,
  intro j,
  have : {x | τ x ≤ σ x} ∩ {x | τ x ≤ j} = {x | min (τ x) j ≤ min (σ x) j} ∩ {x | τ x ≤ j},
  { ext1 x,
    simp only [set.mem_inter_eq, set.mem_set_of_eq, min_le_iff, le_min_iff, le_refl, and_true,
      and.congr_left_iff],
    intro h,
    simp only [h, or_self, and_true],
    by_cases hj : j ≤ σ x,
    { simp only [hj, h.trans hj, or_self], },
    { simp only [hj, or_false], }, },
  rw this,
  refine measurable_set.inter _ (hτ.measurable_set_le j),
  apply measurable_set_le,
  { exact (hτ.min_const j).measurable_of_le (λ _, min_le_right _ _), },
  { exact (hσ.min_const j).measurable_of_le (λ _, min_le_right _ _), },
end

lemma measurable_set_eq_fun_of_encodable {m : measurable_space α} {E} [measurable_space E]
  [encodable E] [measurable_singleton_class E] {f g : α → E}
  (hf : measurable f) (hg : measurable g) :
  measurable_set {x | f x = g x} :=
begin
  have : {x | f x = g x} = ⋃ j, {x | f x = j} ∩ {x | g x = j},
  { ext1 x, simp only [set.mem_set_of_eq, set.mem_Union, set.mem_inter_eq, exists_eq_right'], },
  rw this,
  refine measurable_set.Union (λ j, measurable_set.inter _ _),
  { exact hf (measurable_set_singleton j), },
  { exact hg (measurable_set_singleton j), },
end

lemma measurable_set_eq_stopping_time (hτ : is_stopping_time 𝒢 τ) (hσ : is_stopping_time 𝒢 σ) :
  measurable_set[hτ.measurable_space] {x | τ x = σ x} :=
begin
  rw hτ.measurable_set,
  intro j,
  have : {x | τ x = σ x} ∩ {x | τ x ≤ j}
    = {x | min (τ x) j = min (σ x) j} ∩ {x | τ x ≤ j} ∩ {x | σ x ≤ j},
  { ext1 x,
    simp only [set.mem_inter_eq, set.mem_set_of_eq],
    refine ⟨λ h, ⟨⟨_, h.2⟩, _⟩, λ h, ⟨_, h.1.2⟩⟩,
    { rw h.1, },
    { rw ← h.1, exact h.2, },
    { cases h with h' hσ_le,
      cases h' with h_eq hτ_le,
      rwa [min_eq_left hτ_le, min_eq_left hσ_le] at h_eq, }, },
  rw this,
  refine measurable_set.inter ( measurable_set.inter _ (hτ.measurable_set_le j))
    (hσ.measurable_set_le j),
  apply measurable_set_eq_fun_of_encodable,
  { exact (hτ.min_const j).measurable_of_le (λ _, min_le_right _ _), },
  { exact (hσ.min_const j).measurable_of_le (λ _, min_le_right _ _), },
end

lemma condexp_indicator_stopping_time_eq [sigma_finite_filtration μ 𝒢] {f : α → E}
  (hτ : is_stopping_time 𝒢 τ) [sigma_finite (μ.trim hτ.measurable_space_le)]
  {i : ℕ} (hf : integrable f μ) :
  μ[f | hτ.measurable_space] =ᵐ[μ.restrict {x | τ x = i}] μ[f | 𝒢 i] :=
begin
  refine condexp_indicator_eq_todo hτ.measurable_space_le (𝒢.le i) hf (hτ.measurable_set_eq' i)
    (λ t, _),
  rw [set.inter_comm _ t, is_stopping_time.measurable_set_inter_eq_iff],
end

lemma condexp_indicator_stopping_time_le {f : α → E}
  (hτ : is_stopping_time 𝒢 τ) (hσ : is_stopping_time 𝒢 σ)
  [sigma_finite (μ.trim hτ.measurable_space_le)]
  [sigma_finite (μ.trim (hτ.min hσ).measurable_space_le)]
  (hf : integrable f μ) :
  μ[f | hτ.measurable_space] =ᵐ[μ.restrict {x | τ x ≤ σ x}] μ[f | (hτ.min hσ).measurable_space] :=
begin
  refine condexp_indicator_eq_todo hτ.measurable_space_le (hτ.min hσ).measurable_space_le hf
    (measurable_set_le_stopping_time hτ hσ) (λ t, _),
  rw [set.inter_comm _ t, measurable_set_inter_le_iff'],
end

lemma condexp_indicator_stopping_time_le_const {f : α → E}
  (hτ : is_stopping_time 𝒢 τ) [sigma_finite (μ.trim hτ.measurable_space_le)]
  [∀ i, sigma_finite (μ.trim (hτ.min_const i).measurable_space_le)]
  {i : ℕ} (hf : integrable f μ) :
  μ[f | hτ.measurable_space]
    =ᵐ[μ.restrict {x | τ x ≤ i}] μ[f | (hτ.min_const i).measurable_space] :=
begin
  refine condexp_indicator_eq_todo hτ.measurable_space_le (hτ.min_const i).measurable_space_le hf
    (hτ.measurable_set_le' i) (λ t, _),
  rw [set.inter_comm _ t, measurable_set_inter_le_iff],
end

lemma condexp_indicator_todo [sigma_finite_filtration μ 𝒢] {f : ℕ → α → E} (h : martingale f 𝒢 μ)
  (hτ : is_stopping_time 𝒢 τ) [sigma_finite (μ.trim hτ.measurable_space_le)]
  {i n : ℕ} (hin : i ≤ n) :
  f i =ᵐ[μ.restrict {x | τ x = i}] μ[f n | hτ.measurable_space] :=
begin
  have hfi_eq_restrict : f i =ᵐ[μ.restrict {x | τ x = i}] μ[f n | 𝒢 i],
    from ae_restrict_of_ae (h.condexp_ae_eq hin).symm,
  refine hfi_eq_restrict.trans _,
  refine condexp_indicator_eq_todo (𝒢.le i) hτ.measurable_space_le (h.integrable n)
    (hτ.measurable_set_eq i) (λ t, _),
  rw [set.inter_comm _ t, is_stopping_time.measurable_set_inter_eq_iff],
end

lemma is_stopping_time.measurable_space_min_const (hτ : is_stopping_time 𝒢 τ) {i : ℕ} :
  (hτ.min_const i).measurable_space = hτ.measurable_space ⊓ 𝒢 i :=
by rw [hτ.measurable_space_min (is_stopping_time_const _ i),
  is_stopping_time.measurable_space_const]

lemma is_stopping_time.measurable_set_min_const_iff (hτ : is_stopping_time 𝒢 τ) (s : set α)
  {i : ℕ} :
  measurable_set[(hτ.min_const i).measurable_space] s
    ↔ measurable_set[hτ.measurable_space] s ∧ measurable_set[𝒢 i] s :=
by rw [is_stopping_time.measurable_space_min_const, measurable_space.measurable_set_inf]

lemma strongly_measurable_stopped_value_of_le {E} [topological_space E] {f : ℕ → α → E}
  (h : prog_measurable 𝒢 f) (hτ : is_stopping_time 𝒢 τ) {n : ℕ} (hτ_le : ∀ x, τ x ≤ n) :
  strongly_measurable[𝒢 n] (stopped_value f τ) :=
begin
  have : stopped_value f τ = (λ (p : set.Iic n × α), f ↑(p.fst) p.snd) ∘ (λ x, (⟨τ x, hτ_le x⟩, x)),
  { ext1 x, simp only [stopped_value, function.comp_app, subtype.coe_mk], },
  rw this,
  refine strongly_measurable.comp_measurable (h n) _,
  exact (hτ.measurable_of_le hτ_le).subtype_mk.prod_mk measurable_id,
end

lemma measurable_stopped_value {E} {f : ℕ → α → E} [topological_space E] [metrizable_space E]
  [measurable_space E] [borel_space E]
  (hf_prog : prog_measurable 𝒢 f) (hτ : is_stopping_time 𝒢 τ) :
  measurable[hτ.measurable_space] (stopped_value f τ) :=
begin
  have h_str_meas : ∀ i, strongly_measurable[𝒢 i] (stopped_value f (λ x, min (τ x) i)),
    from λ i, strongly_measurable_stopped_value_of_le hf_prog (hτ.min_const i)
      (λ _, min_le_right _ _),
  intros t ht,
  rw hτ.measurable_set,
  intros i,
  have : stopped_value f τ ⁻¹' t ∩ {x : α | τ x ≤ i}
    = stopped_value f (λ x, min (τ x) i) ⁻¹' t ∩ {x : α | τ x ≤ i},
  { ext1 x,
    simp only [stopped_value, set.mem_inter_eq, set.mem_preimage, set.mem_set_of_eq,
      and.congr_left_iff],
    intro h,
    rw min_eq_left h, },
  rw this,
  refine measurable_set.inter _ (hτ.measurable_set_le i),
  exact (h_str_meas i).measurable ht,
end

lemma martingale.stopped_value_eq_of_le_const [sigma_finite_filtration μ 𝒢] {f : ℕ → α → E}
  (h : martingale f 𝒢 μ) (hτ : is_stopping_time 𝒢 τ) {n : ℕ}
  (hτ_le : ∀ x, τ x ≤ n)
  [sigma_finite (μ.trim hτ.measurable_space_le)] :
  stopped_value f τ =ᵐ[μ] μ[f n | hτ.measurable_space] :=
begin
  rw [stopped_value_eq hτ_le],
  swap, apply_instance,
  simp only [finset.sum_apply],
  have h_fi_eq_condexp : ∀ i, i ∈ {j | j ≤ n} → {x | τ x = i}.indicator (f i)
    =ᵐ[μ] {x | τ x = i}.indicator (μ[f n | hτ.measurable_space]),
  { intros i hin,
    rw ← ae_eq_restrict_iff_indicator_ae_eq (𝒢.le i _ (hτ.measurable_set_eq i)),
    exact condexp_indicator_todo h hτ hin, },
  have : (λ x, (finset.range (n + 1)).sum (λ i, {x : α | τ x = i}.indicator (f i) x))
    =ᵐ[μ] (λ x, (finset.range (n + 1)).sum (λ i, {x : α | τ x = i}.indicator
      (μ[f n | hτ.measurable_space]) x)),
  { simp_rw filter.eventually_eq at h_fi_eq_condexp,
    rw ← filter.eventually_all_finite (set.finite_le_nat n) at h_fi_eq_condexp,
    filter_upwards [h_fi_eq_condexp] with x hx,
    refine finset.sum_congr rfl (λ i hi, _),
    rw [finset.mem_range, nat.lt_succ_iff] at hi,
    exact hx i hi, },
  refine this.trans (filter.eventually_of_forall (λ x, _)),
  rw [finset.sum_indicator_eq_sum_filter, finset.sum_const],
  suffices : (finset.filter (λ (i : ℕ), x ∈ {x : α | τ x = i}) (finset.range (n + 1))).card = 1,
    by rw [this, one_nsmul],
  simp_rw [set.mem_set_of_eq, finset.filter_eq, finset.mem_range, nat.lt_succ_iff,
    if_pos (hτ_le x), finset.card_singleton],
end

lemma martingale.stopped_value_eq_of_le [sigma_finite_filtration μ 𝒢] {f : ℕ → α → E}
  (h : martingale f 𝒢 μ)
  (hτ : is_stopping_time 𝒢 τ) (hσ : is_stopping_time 𝒢 σ) {n : ℕ}
  (hσ_le_τ : σ ≤ τ) (hτ_le : ∀ x, τ x ≤ n)
  [sigma_finite (μ.trim hτ.measurable_space_le)] [sigma_finite (μ.trim hσ.measurable_space_le)] :
  stopped_value f σ =ᵐ[μ] μ[stopped_value f τ | hσ.measurable_space] :=
begin
  have : μ[stopped_value f τ|hσ.measurable_space]
      =ᵐ[μ] μ[μ[f n|hτ.measurable_space] | hσ.measurable_space],
    from condexp_congr_ae (h.stopped_value_eq_of_le_const hτ hτ_le),
  refine filter.eventually_eq.trans _ this.symm,
  refine filter.eventually_eq.trans _ (condexp_condexp_of_le _ _).symm,
  { exact h.stopped_value_eq_of_le_const hσ (λ x, (hσ_le_τ x).trans (hτ_le x)), },
  { exact is_stopping_time.measurable_space_mono _ _ hσ_le_τ, },
  { exact hτ.measurable_space_le, },
  { apply_instance, },
end

end stopping

end measure_theory
