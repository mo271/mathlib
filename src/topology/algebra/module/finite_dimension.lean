/-
Copyright (c) 2022 Anatole Dedecker. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Sébastien Gouëzel, Anatole Dedecker
-/
import analysis.locally_convex.balanced_core_hull

/-!
# Finite dimensional topological vector spaces over complete fields

Let `𝕜` be a nondiscrete and complete normed field, and `E` a topological vector space (TVS) over
`𝕜` (i.e we have `[add_comm_group E] [module 𝕜 E] [topological_space E] [topological_add_group E]`
and `[has_continuous_smul 𝕜 E]`).

If `E` is finite dimensional and Hausdorff, then all linear maps from `E` to any other TVS are
continuous.

When `E` is a normed space, this gets us the equivalence of norms in finite dimension.

## Main results :

* `linear_map.continuous_iff_is_closed_ker` : a linear form is continuous if and only if its kernel
  is closed.
* `linear_map.continuous_of_finite_dimensional` : a linear map on a finite-dimensional Hausdorff
  space over a complete field is continuous.

## TODO

Generalize more of `analysis/normed_space/finite_dimension` to general TVSs.

## Implementation detail

The main result from which everything follows is the fact that, if `ξ : ι → E` is a finite basis,
then `ξ.equiv_fun : E →ₗ (ι → 𝕜)` is continuous. However, for technical reasons, it is easier to
prove this when `ι` and `E` live ine the same universe. So we start by doing that as a private
lemma, then we deduce `linear_map.continuous_of_finite_dimensional` from it, and then the general
result follows as `continuous_equiv_fun_basis`.

-/

universes u v w x

noncomputable theory

open set finite_dimensional topological_space filter
open_locale big_operators

section semiring

variables {ι 𝕜 F : Type*} [fintype ι] [semiring 𝕜] [topological_space 𝕜]
  [add_comm_monoid F] [module 𝕜 F] [topological_space F]
  [has_continuous_add F] [has_continuous_smul 𝕜 F]

/-- A linear map on `ι → 𝕜` (where `ι` is a fintype) is continuous -/
lemma linear_map.continuous_on_pi (f : (ι → 𝕜) →ₗ[𝕜] F) : continuous f :=
begin
  classical,
  -- for the proof, write `f` in the standard basis, and use that each coordinate is a continuous
  -- function.
  have : (f : (ι → 𝕜) → F) =
         (λx, ∑ i : ι, x i • (f (λ j, if i = j then 1 else 0))),
    by { ext x, exact f.pi_apply_eq_sum_univ x },
  rw this,
  refine continuous_finset_sum _ (λi hi, _),
  exact (continuous_apply i).smul continuous_const
end

end semiring

section field

variables {ι 𝕜 E F : Type*} [fintype ι] [field 𝕜] [topological_space 𝕜]
  [add_comm_group E] [module 𝕜 E] [topological_space E]
  [add_comm_group F] [module 𝕜 F] [topological_space F]
  [topological_add_group F] [has_continuous_smul 𝕜 F]

/-- The space of continuous linear maps between finite-dimensional spaces is finite-dimensional. -/
instance [finite_dimensional 𝕜 E] [finite_dimensional 𝕜 F] :
  finite_dimensional 𝕜 (E →L[𝕜] F) :=
finite_dimensional.of_injective
  (continuous_linear_map.coe_lm 𝕜 : (E →L[𝕜] F) →ₗ[𝕜] (E →ₗ[𝕜] F))
  continuous_linear_map.coe_injective

end field

section normed_field

variables {𝕜 : Type u} [hnorm : nondiscrete_normed_field 𝕜]
  {E : Type v} [add_comm_group E] [module 𝕜 E] [topological_space E]
  [topological_add_group E] [has_continuous_smul 𝕜 E]
  {F : Type w} [add_comm_group F] [module 𝕜 F] [topological_space F]
  [topological_add_group F] [has_continuous_smul 𝕜 F]
  {F' : Type x} [add_comm_group F'] [module 𝕜 F'] [topological_space F']
  [topological_add_group F'] [has_continuous_smul 𝕜 F']

include hnorm

/-- If `𝕜` is a nondiscrete normed field, any T2 topology on `𝕜` which makes it a topological vector
    space over itself (with the norm topology) is *equal* to the norm topology. -/
lemma unique_topology_of_t2 {t : topological_space 𝕜}
  (h₁ : @topological_add_group 𝕜 t _)
  (h₂ : @has_continuous_smul 𝕜 𝕜 _ hnorm.to_uniform_space.to_topological_space t)
  (h₃ : @t2_space 𝕜 t) :
  t = hnorm.to_uniform_space.to_topological_space :=
begin
  -- Let `𝓣₀` denote the topology on `𝕜` induced by the norm, and `𝓣` be any T2 vector
  -- topology on `𝕜`. To show that `𝓣₀ = 𝓣`, it suffices to show that they have the same
  -- neighborhoods of 0.
  refine topological_add_group.ext h₁ infer_instance (le_antisymm _ _),
  { -- To show `𝓣 ≤ 𝓣₀`, we have to show that closed balls are `𝓣`-neighborhoods of 0.
    rw metric.nhds_basis_closed_ball.ge_iff,
    -- Let `ε > 0`. Since `𝕜` is nondiscrete, we have `0 < ∥ξ₀∥ < ε` for some `ξ₀ : 𝕜`.
    intros ε hε,
    rcases normed_field.exists_norm_lt 𝕜 hε with ⟨ξ₀, hξ₀, hξ₀ε⟩,
    -- Since `ξ₀ ≠ 0` and `𝓣` is T2, we know that `{ξ₀}ᶜ` is a `𝓣`-neighborhood of 0.
    have : {ξ₀}ᶜ ∈ @nhds 𝕜 t 0 :=
      is_open.mem_nhds is_open_compl_singleton (ne.symm $ norm_ne_zero_iff.mp hξ₀.ne.symm),
    -- Thus, its balanced core `𝓑` is too. Let's show that the closed ball of radius `ε` contains
    -- `𝓑`, which will imply that the closed ball is indeed a `𝓣`-neighborhood of 0.
    have : balanced_core 𝕜 {ξ₀}ᶜ ∈ @nhds 𝕜 t 0 := balanced_core_mem_nhds_zero this,
    refine mem_of_superset this (λ ξ hξ, _),
    -- Let `ξ ∈ 𝓑`. We want to show `∥ξ∥ < ε`. If `ξ = 0`, this is trivial.
    by_cases hξ0 : ξ = 0,
    { rw hξ0,
      exact metric.mem_closed_ball_self hε.le },
    { rw [mem_closed_ball_zero_iff],
      -- Now suppose `ξ ≠ 0`. By contradiction, let's assume `ε < ∥ξ∥`, and show that
      -- `ξ₀ ∈ 𝓑 ⊆ {ξ₀}ᶜ`, which is a contradiction.
      by_contra' h,
      suffices : (ξ₀ * ξ⁻¹) • ξ ∈ balanced_core 𝕜 {ξ₀}ᶜ,
      { rw [smul_eq_mul 𝕜, mul_assoc, inv_mul_cancel hξ0, mul_one] at this,
        exact not_mem_compl_iff.mpr (mem_singleton ξ₀) ((balanced_core_subset _) this) },
      -- For that, we use that `𝓑` is balanced : since `∥ξ₀∥ < ε < ∥ξ∥`, we have `∥ξ₀ / ξ∥ ≤ 1`,
      -- hence `ξ₀ = (ξ₀ / ξ) • ξ ∈ 𝓑` because `ξ ∈ 𝓑`.
      refine balanced_mem (balanced_core_balanced _) hξ _,
      rw [norm_mul, norm_inv, mul_inv_le_iff (norm_pos_iff.mpr hξ0), mul_one],
      exact (hξ₀ε.trans h).le } },
  { -- Finally, to show `𝓣₀ ≤ 𝓣`, we simply argue that `id = (λ x, x • 1)` is continuous from
    -- `(𝕜, 𝓣₀)` to `(𝕜, 𝓣)` because `(•) : (𝕜, 𝓣₀) × (𝕜, 𝓣) → (𝕜, 𝓣)` is continuous.
    calc (@nhds 𝕜 hnorm.to_uniform_space.to_topological_space 0)
        = map id (@nhds 𝕜 hnorm.to_uniform_space.to_topological_space 0) : map_id.symm
    ... = map (λ x, id x • 1) (@nhds 𝕜 hnorm.to_uniform_space.to_topological_space 0) :
        by conv_rhs {congr, funext, rw [smul_eq_mul, mul_one]}; refl
    ... ≤ (@nhds 𝕜 t ((0 : 𝕜) • 1)) :
        @tendsto.smul_const _ _ _ hnorm.to_uniform_space.to_topological_space t _ _ _ _ _
          tendsto_id (1 : 𝕜)
    ... = (@nhds 𝕜 t 0) : by rw zero_smul }
end

/-- Any linear form on a topological vector space over a nondiscrete normed field is continuous if
    its kernel is closed. -/
lemma linear_map.continuous_of_is_closed_ker (l : E →ₗ[𝕜] 𝕜) (hl : is_closed (l.ker : set E)) :
  continuous l :=
begin
  -- `l` is either constant or surjective. If it is constant, the result is trivial.
  by_cases H : finrank 𝕜 l.range = 0,
  { rw [finrank_eq_zero, linear_map.range_eq_bot] at H,
    rw H,
    exact continuous_zero },
  { -- In the case where `l` is surjective, we factor it as `φ : (E ⧸ l.ker) ≃ₗ[𝕜] 𝕜`. Note that
    -- `E ⧸ l.ker` is T2 since `l.ker` is closed.
    have : finrank 𝕜 l.range = 1,
      from le_antisymm (finrank_self 𝕜 ▸ l.range.finrank_le) (zero_lt_iff.mpr H),
    have hi : function.injective (l.ker.liftq l (le_refl _)),
    { rw [← linear_map.ker_eq_bot],
      exact submodule.ker_liftq_eq_bot _ _ _ (le_refl _) },
    have hs : function.surjective (l.ker.liftq l (le_refl _)),
    { rw [← linear_map.range_eq_top, submodule.range_liftq],
      exact eq_top_of_finrank_eq ((finrank_self 𝕜).symm ▸ this) },
    let φ : (E ⧸ l.ker) ≃ₗ[𝕜] 𝕜 := linear_equiv.of_bijective (l.ker.liftq l (le_refl _)) hi hs,
    have hlφ : (l : E → 𝕜) = φ ∘ l.ker.mkq,
      by ext; refl,
    -- Since the quotient map `E →ₗ[𝕜] (E ⧸ l.ker)` is continuous, the continuity of `l` will follow
    -- form the continuity of `φ`.
    suffices : continuous φ.to_equiv,
    { rw hlφ,
      exact this.comp continuous_quot_mk },
    -- The pullback by `φ.symm` of the quotient topology is a T2 topology on `𝕜`, because `φ.symm`
    -- is injective. Since `φ.symm` is linear, it is also a vector space topology.
    -- Hence, we know that it is equal to the topology induced by the norm.
    have : induced φ.to_equiv.symm infer_instance = hnorm.to_uniform_space.to_topological_space,
    { refine unique_topology_of_t2 (topological_add_group_induced φ.symm.to_linear_map)
        (has_continuous_smul_induced φ.symm.to_linear_map) _,
      rw t2_space_iff,
      exact λ x y hxy, @separated_by_continuous _ _ (induced _ _) _ _ _
        continuous_induced_dom _ _ (φ.to_equiv.symm.injective.ne hxy) },
    -- Finally, the pullback by `φ.symm` is exactly the pushforward by `φ`, so we have to prove
    -- that `φ` is continuous when `𝕜` is endowed with the pushforward by `φ` of the quotient
    -- topology, which is trivial by definition of the pushforward.
    rw [this.symm, equiv.induced_symm],
    exact continuous_coinduced_rng }
end

/-- Any linear form on a topological vector space over a nondiscrete normed field is continuous if
    and only if its kernel is closed. -/
lemma linear_map.continuous_iff_is_closed_ker (l : E →ₗ[𝕜] 𝕜) :
  continuous l ↔ is_closed (l.ker : set E) :=
⟨λ h, is_closed_singleton.preimage h, l.continuous_of_is_closed_ker⟩

variables [complete_space 𝕜]

/-- This version imposes `ι` and `E` to live in the same universe, so you should instead use
`continuous_equiv_fun_basis` which gives the same result without universe restrictions. -/
private lemma continuous_equiv_fun_basis_aux [ht2 : t2_space E] {ι : Type v} [fintype ι]
  (ξ : basis ι 𝕜 E) : continuous ξ.equiv_fun :=
begin
  letI : uniform_space E := topological_add_group.to_uniform_space E,
  letI : uniform_add_group E := topological_add_group_is_uniform,
  letI : separated_space E := separated_iff_t2.mpr ht2,
  unfreezingI { induction hn : fintype.card ι with n IH generalizing ι E },
  { rw fintype.card_eq_zero_iff at hn,
    exact continuous_of_const (λ x y, funext hn.elim) },
  { haveI : finite_dimensional 𝕜 E := of_fintype_basis ξ,
    -- first step: thanks to the induction hypothesis, any n-dimensional subspace is equivalent
    -- to a standard space of dimension n, hence it is complete and therefore closed.
    have H₁ : ∀s : submodule 𝕜 E, finrank 𝕜 s = n → is_closed (s : set E),
    { assume s s_dim,
      letI : uniform_add_group s := s.to_add_subgroup.uniform_add_group,
      let b := basis.of_vector_space 𝕜 s,
      have U : uniform_embedding b.equiv_fun.symm.to_equiv,
      { have : fintype.card (basis.of_vector_space_index 𝕜 s) = n,
          by { rw ← s_dim, exact (finrank_eq_card_basis b).symm },
        have : continuous b.equiv_fun := IH b this,
        exact b.equiv_fun.symm.uniform_embedding b.equiv_fun.symm.to_linear_map.continuous_on_pi
          this },
      have : is_complete (s : set E),
        from complete_space_coe_iff_is_complete.1 ((complete_space_congr U).1 (by apply_instance)),
      exact this.is_closed },
    -- second step: any linear form is continuous, as its kernel is closed by the first step
    have H₂ : ∀f : E →ₗ[𝕜] 𝕜, continuous f,
    { assume f,
      by_cases H : finrank 𝕜 f.range = 0,
      { rw [finrank_eq_zero, linear_map.range_eq_bot] at H,
        rw H,
        exact continuous_zero },
      { have : finrank 𝕜 f.ker = n,
        { have Z := f.finrank_range_add_finrank_ker,
          rw [finrank_eq_card_basis ξ, hn] at Z,
          have : finrank 𝕜 f.range = 1,
            from le_antisymm (finrank_self 𝕜 ▸ f.range.finrank_le) (zero_lt_iff.mpr H),
          rw [this, add_comm, nat.add_one] at Z,
          exact nat.succ.inj Z },
        have : is_closed (f.ker : set E),
          from H₁ _ this,
        exact linear_map.continuous_of_is_closed_ker f this } },
    rw continuous_pi_iff,
    intros i,
    change continuous (ξ.coord i),
    exact H₂ (ξ.coord i) },
end

/-- Any linear map on a finite dimensional space over a complete field is continuous. -/
theorem linear_map.continuous_of_finite_dimensional [t2_space E] [finite_dimensional 𝕜 E]
  (f : E →ₗ[𝕜] F') :
  continuous f :=
begin
  -- for the proof, go to a model vector space `b → 𝕜` thanks to `continuous_equiv_fun_basis`, and
  -- argue that all linear maps there are continuous.
  let b := basis.of_vector_space 𝕜 E,
  have A : continuous b.equiv_fun :=
    continuous_equiv_fun_basis_aux b,
  have B : continuous (f.comp (b.equiv_fun.symm : (basis.of_vector_space_index 𝕜 E → 𝕜) →ₗ[𝕜] E)) :=
    linear_map.continuous_on_pi _,
  have : continuous ((f.comp (b.equiv_fun.symm : (basis.of_vector_space_index 𝕜 E → 𝕜) →ₗ[𝕜] E))
                      ∘ b.equiv_fun) := B.comp A,
  convert this,
  ext x,
  dsimp,
  rw [basis.equiv_fun_symm_apply, basis.sum_repr]
end

/-- In finite dimensions over a non-discrete complete normed field, the canonical identification
(in terms of a basis) with `𝕜^n` (endowed with the product topology) is continuous.
This is the key fact wich makes all linear maps from a T2 finite dimensional TVS over such a field
continuous (see `linear_map.continuous_of_finite_dimensional`), which in turn implies that all
norms are equivalent in finite dimensions. -/
theorem continuous_equiv_fun_basis [t2_space E] {ι : Type*} [fintype ι] (ξ : basis ι 𝕜 E) :
  continuous ξ.equiv_fun :=
begin
  haveI : finite_dimensional 𝕜 E := of_fintype_basis ξ,
  exact ξ.equiv_fun.to_linear_map.continuous_of_finite_dimensional
end

namespace linear_map

variables [t2_space E] [finite_dimensional 𝕜 E]

/-- The continuous linear map induced by a linear map on a finite dimensional space -/
def to_continuous_linear_map : (E →ₗ[𝕜] F') ≃ₗ[𝕜] E →L[𝕜] F' :=
{ to_fun := λ f, ⟨f, f.continuous_of_finite_dimensional⟩,
  inv_fun := coe,
  map_add' := λ f g, rfl,
  map_smul' := λ c f, rfl,
  left_inv := λ f, rfl,
  right_inv := λ f, continuous_linear_map.coe_injective rfl }

@[simp] lemma coe_to_continuous_linear_map' (f : E →ₗ[𝕜] F') :
  ⇑f.to_continuous_linear_map = f := rfl

@[simp] lemma coe_to_continuous_linear_map (f : E →ₗ[𝕜] F') :
  (f.to_continuous_linear_map : E →ₗ[𝕜] F') = f := rfl

@[simp] lemma coe_to_continuous_linear_map_symm :
  ⇑(to_continuous_linear_map : (E →ₗ[𝕜] F') ≃ₗ[𝕜] E →L[𝕜] F').symm = coe := rfl

end linear_map

namespace linear_equiv

variables [t2_space E] [t2_space F] [finite_dimensional 𝕜 E]

/-- The continuous linear equivalence induced by a linear equivalence on a finite dimensional
space. -/
def to_continuous_linear_equiv (e : E ≃ₗ[𝕜] F) : E ≃L[𝕜] F :=
{ continuous_to_fun := e.to_linear_map.continuous_of_finite_dimensional,
  continuous_inv_fun := begin
    haveI : finite_dimensional 𝕜 F := e.finite_dimensional,
    exact e.symm.to_linear_map.continuous_of_finite_dimensional
  end,
  ..e }

@[simp] lemma coe_to_continuous_linear_equiv (e : E ≃ₗ[𝕜] F) :
  (e.to_continuous_linear_equiv : E →ₗ[𝕜] F) = e := rfl

@[simp] lemma coe_to_continuous_linear_equiv' (e : E ≃ₗ[𝕜] F) :
  (e.to_continuous_linear_equiv : E → F) = e := rfl

@[simp] lemma coe_to_continuous_linear_equiv_symm (e : E ≃ₗ[𝕜] F) :
  (e.to_continuous_linear_equiv.symm : F →ₗ[𝕜] E) = e.symm := rfl

@[simp] lemma coe_to_continuous_linear_equiv_symm' (e : E ≃ₗ[𝕜] F) :
  (e.to_continuous_linear_equiv.symm : F → E) = e.symm := rfl

@[simp] lemma to_linear_equiv_to_continuous_linear_equiv (e : E ≃ₗ[𝕜] F) :
  e.to_continuous_linear_equiv.to_linear_equiv = e :=
by { ext x, refl }

@[simp] lemma to_linear_equiv_to_continuous_linear_equiv_symm (e : E ≃ₗ[𝕜] F) :
  e.to_continuous_linear_equiv.symm.to_linear_equiv = e.symm :=
by { ext x, refl }

end linear_equiv

namespace continuous_linear_map

variables [t2_space E] [finite_dimensional 𝕜 E]

/-- Builds a continuous linear equivalence from a continuous linear map on a finite-dimensional
vector space whose determinant is nonzero. -/
def to_continuous_linear_equiv_of_det_ne_zero
  (f : E →L[𝕜] E) (hf : f.det ≠ 0) : E ≃L[𝕜] E :=
((f : E →ₗ[𝕜] E).equiv_of_det_ne_zero hf).to_continuous_linear_equiv

@[simp] lemma coe_to_continuous_linear_equiv_of_det_ne_zero (f : E →L[𝕜] E) (hf : f.det ≠ 0) :
  (f.to_continuous_linear_equiv_of_det_ne_zero hf : E →L[𝕜] E) = f :=
by { ext x, refl }

@[simp] lemma to_continuous_linear_equiv_of_det_ne_zero_apply
  (f : E →L[𝕜] E) (hf : f.det ≠ 0) (x : E) :
  f.to_continuous_linear_equiv_of_det_ne_zero hf x = f x :=
rfl

end continuous_linear_map

end normed_field
