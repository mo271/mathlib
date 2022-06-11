/-
Copyright (c) 2022 Oliver Nash. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Oliver Nash
-/
import algebra.lie.abelian
import algebra.lie.ideal_operations
import algebra.lie.quotient

/-!
# The centralizer of a Lie submodule and the normalizer of a Lie subalgebra.

Given a Lie module `M` over a Lie subalgebra `L`, the centralizer of a Lie submodule `N ⊆ M` is
the Lie submodule with underlying set `{ m | ∀ (x : L), ⁅x, m⁆ ∈ N }`.

The lattice of Lie submodules thus has two natural operations, the centralizer: `N ↦ N.centralizer`
and the ideal operation: `N ↦ ⁅⊤, N⁆`; these are adjoint, i.e., they form a Galois connection. This
adjointness is the reason that we may define nilpotency in terms of either the upper or lower
central series.

Given a Lie subalgebra `H ⊆ L`, we may regard `H` as a Lie submodule of `L` over `H`, and thus
consider the centralizer. This turns out to be a Lie subalgebra and is known as the normalizer.

## Main definitions

  * `lie_submodule.centralizer`
  * `lie_subalgebra.normalizer`
  * `lie_submodule.gc_top_lie_centralizer`

## Tags

lie algebra, centralizer, normalizer
-/

variables {R L M M' : Type*}
variables [comm_ring R] [lie_ring L] [lie_algebra R L]
variables [add_comm_group M] [module R M] [lie_ring_module L M] [lie_module R L M]
variables [add_comm_group M'] [module R M'] [lie_ring_module L M'] [lie_module R L M']

namespace lie_submodule

variables (N : lie_submodule R L M) {N₁ N₂ : lie_submodule R L M}

/-- The centralizer of a Lie submodule. -/
def centralizer : lie_submodule R L M :=
{ carrier   := { m | ∀ (x : L), ⁅x, m⁆ ∈ N },
  add_mem'  := λ m₁ m₂ hm₁ hm₂ x, by {  rw lie_add, exact N.add_mem' (hm₁ x) (hm₂ x), },
  zero_mem' := λ x, by simp,
  smul_mem' := λ t m hm x, by { rw lie_smul, exact N.smul_mem' t (hm x), },
  lie_mem   := λ x m hm y, by { rw leibniz_lie, exact N.add_mem' (hm ⁅y, x⁆) (N.lie_mem (hm y)), } }

@[simp] lemma mem_centralizer (m : M) :
  m ∈ N.centralizer ↔ ∀ (x : L), ⁅x, m⁆ ∈ N :=
iff.rfl

lemma le_centralizer : N ≤ N.centralizer :=
begin
  intros m hm,
  rw mem_centralizer,
  exact λ x, N.lie_mem hm,
end

lemma centralizer_inf :
  (N₁ ⊓ N₂).centralizer = N₁.centralizer ⊓ N₂.centralizer :=
by { ext, simp [← forall_and_distrib], }

@[mono] lemma monotone_centalizer :
  monotone (centralizer : lie_submodule R L M → lie_submodule R L M) :=
begin
  intros N₁ N₂ h m hm,
  rw mem_centralizer at hm ⊢,
  exact λ x, h (hm x),
end

@[simp] lemma comap_centralizer (f : M' →ₗ⁅R,L⁆ M) :
  N.centralizer.comap f = (N.comap f).centralizer :=
by { ext, simp, }

lemma top_lie_le_iff_le_centralizer (N' : lie_submodule R L M) :
  ⁅(⊤ : lie_ideal R L), N⁆ ≤ N' ↔ N ≤ N'.centralizer :=
by { rw lie_le_iff, tauto, }

lemma gc_top_lie_centralizer :
  galois_connection (λ N : lie_submodule R L M, ⁅(⊤ : lie_ideal R L), N⁆) centralizer :=
top_lie_le_iff_le_centralizer

variables (R L M)

lemma centralizer_bot_eq_max_triv_submodule :
  (⊥ : lie_submodule R L M).centralizer = lie_module.max_triv_submodule R L M :=
rfl

end lie_submodule

namespace lie_subalgebra

variables (H : lie_subalgebra R L)

/-- Regarding a Lie subalgebra `H ⊆ L` as a module over itself, its centralizer is in fact a Lie
subalgebra. This is called the normalizer of the Lie subalgebra. -/
def normalizer : lie_subalgebra R L :=
{ lie_mem' := λ y z hy hz x,
  begin
    rw [coe_bracket_of_module, mem_to_lie_submodule, leibniz_lie, ← lie_skew y, ← sub_eq_add_neg],
    exact H.sub_mem (hz ⟨_, hy x⟩) (hy ⟨_, hz x⟩),
  end,
  .. H.to_lie_submodule.centralizer }

lemma mem_normalizer_iff' (x : L) : x ∈ H.normalizer ↔ ∀ (y : L), (y ∈ H) → ⁅y, x⁆ ∈ H :=
by { rw subtype.forall', refl, }

lemma mem_normalizer_iff (x : L) : x ∈ H.normalizer ↔ ∀ (y : L), (y ∈ H) → ⁅x, y⁆ ∈ H :=
begin
  rw mem_normalizer_iff',
  refine forall₂_congr (λ y hy, _),
  rw [← lie_skew, neg_mem_iff],
end

lemma le_normalizer : H ≤ H.normalizer := H.to_lie_submodule.le_centralizer

lemma coe_centralizer_eq_normalizer :
  (H.to_lie_submodule.centralizer : submodule R L) = H.normalizer :=
rfl

variables {H}

lemma lie_mem_sup_of_mem_normalizer {x y z : L} (hx : x ∈ H.normalizer)
  (hy : y ∈ (R ∙ x) ⊔ ↑H) (hz : z ∈ (R ∙ x) ⊔ ↑H) : ⁅y, z⁆ ∈ (R ∙ x) ⊔ ↑H :=
begin
  rw submodule.mem_sup at hy hz,
  obtain ⟨u₁, hu₁, v, hv : v ∈ H, rfl⟩ := hy,
  obtain ⟨u₂, hu₂, w, hw : w ∈ H, rfl⟩ := hz,
  obtain ⟨t, rfl⟩ := submodule.mem_span_singleton.mp hu₁,
  obtain ⟨s, rfl⟩ := submodule.mem_span_singleton.mp hu₂,
  apply submodule.mem_sup_right,
  simp only [lie_subalgebra.mem_coe_submodule, smul_lie, add_lie, zero_add, lie_add, smul_zero,
    lie_smul, lie_self],
  refine H.add_mem (H.smul_mem s _) (H.add_mem (H.smul_mem t _) (H.lie_mem hv hw)),
  exacts [(H.mem_normalizer_iff' x).mp hx v hv, (H.mem_normalizer_iff x).mp hx w hw],
end

/-- A Lie subalgebra is an ideal of its normalizer. -/
lemma ideal_in_normalizer {x y : L} (hx : x ∈ H.normalizer) (hy : y ∈ H) : ⁅x,y⁆ ∈ H :=
begin
  rw [← lie_skew, neg_mem_iff],
  exact hx ⟨y, hy⟩,
end

/-- A Lie subalgebra `H` is an ideal of any Lie subalgebra `K` containing `H` and contained in the
normalizer of `H`. -/
lemma exists_nested_lie_ideal_of_le_normalizer
  {K : lie_subalgebra R L} (h₁ : H ≤ K) (h₂ : K ≤ H.normalizer) :
  ∃ (I : lie_ideal R K), (I : lie_subalgebra R K) = of_le h₁ :=
begin
  rw exists_nested_lie_ideal_coe_eq_iff,
  exact λ x y hx hy, ideal_in_normalizer (h₂ hx) hy,
end

variables (H)

lemma normalizer_eq_self_iff :
  H.normalizer = H ↔ (lie_module.max_triv_submodule R H $ L ⧸ H.to_lie_submodule) = ⊥ :=
begin
  rw lie_submodule.eq_bot_iff,
  refine ⟨λ h, _, λ h, le_antisymm (λ x hx, _) H.le_normalizer⟩,
  { rintros ⟨x⟩ hx,
    suffices : x ∈ H, by simpa,
    rw [← h, H.mem_normalizer_iff'],
    intros y hy,
    replace hx : ⁅_, lie_submodule.quotient.mk' _ x⁆ = 0 := hx ⟨y, hy⟩,
    rwa [← lie_module_hom.map_lie, lie_submodule.quotient.mk_eq_zero] at hx, },
  { let y := lie_submodule.quotient.mk' H.to_lie_submodule x,
    have hy : y ∈ lie_module.max_triv_submodule R H (L ⧸ H.to_lie_submodule),
    { rintros ⟨z, hz⟩,
      rw [← lie_module_hom.map_lie, lie_submodule.quotient.mk_eq_zero, coe_bracket_of_module,
        submodule.coe_mk, mem_to_lie_submodule],
      exact (H.mem_normalizer_iff' x).mp hx z hz, },
    simpa using h y hy, },
end

end lie_subalgebra
