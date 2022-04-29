/-
Copyright (c) 2021 Amelia Livingston. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Amelia Livingston
-/
import algebra.group_action_hom
import data.fin_simplicial_complex
import algebra.monoid_algebra.basic
import algebra.group.cohomology.lemmas
import linear_algebra.basis

/-!
# Group rings

This file defines the group ring `ℤ[G]` of a group `G`.

This is the free abelian group on the elements of `G`, with multiplication induced by
multiplication in `G.` A `G`-module `M` is also a `ℤ[G]`-module.

We develop an API allowing us to show `ℤ[Gⁿ]` is a free `ℤ[G]`-module for `n ≥ 1`. This
will be used to construct a projective resolution of the trivial `ℤ[G]`-module `ℤ`.

## Implementation notes

Although `group_ring G` is just `monoid_algebra ℤ G`, we make the definition `group_ring`
so Lean finds the right instances for this setting, and so we can separate material relevant
to group cohomology into the namespace `group_ring`.

## Tags

group ring, group cohomology, monoid algebra
-/

noncomputable theory

/-- The group ring `ℤ[G]` of a group `G` (although this is defined
  for any type `G`). -/
def group_ring (G : Type*) := monoid_algebra ℤ G

namespace group_ring

instance {G : Type*} : inhabited (group_ring G) :=
by unfold group_ring; apply_instance

instance {G : Type*} : add_comm_group (group_ring G) :=
finsupp.add_comm_group

instance {G : Type*} [monoid G] : ring (group_ring G) :=
{ ..monoid_algebra.semiring, ..group_ring.add_comm_group }

/-- The natural inclusion `G → ℤ[G]`. -/
def of (G : Type*) [monoid G] : G →* group_ring G :=
monoid_algebra.of ℤ G

section

variables {G : Type*} [monoid G]

@[simp] lemma of_apply (g : G) :
  of G g = finsupp.single g (1 : ℤ) := rfl

lemma zsmul_single_one (g : G) (r : ℤ) :
  r • (of G g) = finsupp.single g r :=
by simp only [mul_one, finsupp.smul_single', zsmul_eq_smul, of_apply]

@[elab_as_eliminator]
lemma induction_on {p : group_ring G → Prop} (f : group_ring G)
  (hM : ∀ g, p (of G g)) (hadd : ∀ f g : group_ring G, p f → p g → p (f + g))
  (hsmul : ∀ (r : ℤ) f, p f → p (r • f)) : p f :=
monoid_algebra.induction_on _ hM hadd hsmul

lemma ext {P : Type*} [add_comm_group P] (f : group_ring G →+ P)
  (g : group_ring G →+ P) (H : ∀ x, f (of G x) = g (of G x)) {x} :
  f x = g x :=
begin
  congr,
  refine finsupp.add_hom_ext (λ y n, _),
  simp only [←zsmul_single_one, add_monoid_hom.map_zsmul, H],
end

/-- Makes a `ℤ[G]`-linear map from a `G`-linear hom of `ℤ[G]`-modules. -/
def mk_linear {P : Type*} {P' : Type*} [add_comm_group P] [add_comm_group P']
  [module (group_ring G) P] [module (group_ring G) P'] (f : P →+ P')
  (H : ∀ g x, f (of G g • x) = of G g • f x) : P →ₗ[group_ring G] P' :=
{ map_smul' := λ z,
  begin
  refine z.induction_on (by exact H) _ _,
  { intros a b ha hb x,
    dsimp at ⊢ ha hb,
    simp only [add_smul, f.map_add, ha, hb] },
  { intros r a ha x,
    dsimp at ⊢ ha,
    simp only [smul_assoc, f.map_zsmul, ha] }
  end, ..f }

@[simp] lemma mk_linear_apply {P : Type*} {P' : Type*} [add_comm_group P] [add_comm_group P']
  [module (group_ring G) P] [module (group_ring G) P'] (f : P →+ P')
  {H : ∀ g x, f (of G g • x) = of G g • f x} {x : P} :
  mk_linear f H x = f x := rfl

/-- Makes a `ℤ[G]`-linear isomorphism from a `G`-linear isomorphism of `ℤ[G]`-modules. -/
def mk_equiv {P : Type*} {P' : Type*} [add_comm_group P] [add_comm_group P']
  [module (group_ring G) P] [module (group_ring G) P'] (f : P ≃+ P')
  (H : ∀ g x, f (of G g • x) = of G g • f x) : P ≃ₗ[group_ring G] P' :=
{ ..f, ..mk_linear f.to_add_monoid_hom H }

@[simp] lemma mk_equiv_apply {P : Type*} {P' : Type*} [add_comm_group P] [add_comm_group P']
  [module (group_ring G) P] [module (group_ring G) P'] (f : P ≃+ P')
  {H : ∀ g x, f (of G g • x) = of G g • f x} {x : P} :
  mk_equiv f H x = f x := rfl

instance {G : Type*} [monoid G] {M : Type*} [add_comm_group M]
  [H : distrib_mul_action G M] : smul_comm_class ℤ G M :=
⟨λ n g m, (distrib_mul_action.smul_zsmul g n m).symm⟩

/-- `ℤ[G]`-module instance on an `G`-module `M`. -/
def to_module {M : Type*} [add_comm_group M]
  [H : distrib_mul_action G M] : module (group_ring G) M :=
monoid_algebra.total_to_module

end

variables {G : Type*} [group G] {n : ℕ}

instance {H : Type*} [mul_action G H] : distrib_mul_action G (group_ring H) :=
finsupp.comap_distrib_mul_action

lemma map_smul_of_map_smul_of {H : Type*} [monoid H] [module (group_ring G) (group_ring H)]
  {P : Type*} [add_comm_group P] [module (group_ring G) P] (f : group_ring H →+ P)
  (h : ∀ (g : G) (x : H), f (of G g • of _ x) = of G g • f (of _ x)) (g : group_ring G)
  (x : group_ring H) : f (g • x) = g • f x :=
begin
  convert (mk_linear f _).map_smul g x,
  intros a b,
  refine b.induction_on (by exact h a) _ _,
  { intros s t hs ht,
    simp only [smul_add, f.map_add, hs, ht] },
  { intros r s hs,
    simp only [smul_algebra_smul_comm, f.map_zsmul, hs] }
end

instance : module (group_ring G) (group_ring (fin n → G)) :=
group_ring.to_module

instance (M : submodule (group_ring G) (group_ring (fin n → G))) :
  has_coe M (group_ring (fin n → G)) :=
{ coe := λ m, m.1 }

lemma smul_def (g : group_ring G) (h : group_ring (fin n → G)) :
  g • h = finsupp.total G (group_ring (fin n → G)) ℤ (λ x, x • h) g :=
rfl

lemma of_smul_of (g : G) (x : fin n → G) :
  of G g • of (fin n → G) x = of (fin n → G) (g • x) :=
show finsupp.total _ _ _ _ _ = _, by simp

lemma single_smul_single (g : G) (x : fin n → G) (i j : ℤ) :
  ((•) : group_ring G → group_ring (fin n → G) → group_ring (fin n → G))
  (finsupp.single g i) (finsupp.single x j) = finsupp.single (g • x) (i * j) :=
show finsupp.total _ _ _ _ _ = _, by simp


variables (G)

/-- The natural `ℤ[G]`-linear isomorphism `ℤ[G¹] ≅ ℤ[G]` -/
def dom_one_equiv : group_ring (fin 1 → G) ≃ₗ[group_ring G] group_ring G :=
mk_equiv (finsupp.dom_congr (fin.dom_one_equiv G)) $ λ g x, finsupp.ext $ λ c,
by { dsimp, simpa [smul_def] }

variables {G}

lemma dom_one_equiv_single {g : fin 1 → G} {m : ℤ} :
  dom_one_equiv G (finsupp.single g m) = finsupp.single (g 0) m :=
begin
  erw [finsupp.dom_congr_apply, finsupp.equiv_map_domain_single],
  refl,
end

/-- The hom sending `ℤ[Gⁿ] → ℤ[Gⁿ⁺¹]` sending `(g₁, ..., gₙ) ↦ (r, g₁, ..., gₙ)` -/
def cons {G : Type*} (n : ℕ) (r : G) :
  group_ring (fin n → G) →+ group_ring (fin (n + 1) → G) :=
finsupp.map_domain.add_monoid_hom (@fin.cons n (λ i, G) r)

lemma cons_of {n : ℕ} {r : G} (g : fin n → G) :
  cons n r (of _ g) = of (fin (n + 1) → G) (fin.cons r g) :=
finsupp.map_domain_single

variables (G n)

/-- The quotient of `Gⁿ⁺¹` by the left action of `G` -/
abbreviation orbit_quot := quotient (mul_action.orbit_rel G (fin (n + 1) → G))

/-- Helper function; sends `g ∈ Gⁿ⁺¹`, `n ∈ ℤ` to `(n • g₀) • g` as an element of `ℤ[Gⁿ⁺¹] → ℤ[G]` -/
def to_basis_add_hom_aux (g : fin (n + 1) → G) : ℤ →+ ((fin (n + 1) → G) →₀ group_ring G) :=
{ to_fun := λ m, finsupp.single g (finsupp.single (g 0) m),
    map_zero' := by simp only [finsupp.single_zero],
    map_add' := λ x y, by simp only [finsupp.single_add]}

/-- The map sending `g = (g₀, ..., gₙ) ∈ ℤ[Gⁿ⁺¹]` to `g₀ • ⟦g⟧`, as an element of the free
  `ℤ[G]`-module on the set `Gⁿ⁺¹` modulo the left action of `G`. -/
def to_basis_add_hom :
  group_ring (fin (n + 1) → G) →+ (orbit_quot G n →₀ group_ring G) :=
(@finsupp.map_domain.add_monoid_hom (fin (n + 1) → G) (orbit_quot G n)
  (group_ring G) _ quotient.mk').comp
(finsupp.lift_add_hom $ to_basis_add_hom_aux G n)

variables {G n}

lemma to_basis_add_hom_of (g : fin (n + 1) → G) :
  to_basis_add_hom G n (of _ g) = finsupp.single (quotient.mk' g : orbit_quot G n) (of G (g 0)) :=
begin
  unfold to_basis_add_hom,
  simp only [finsupp.lift_add_hom_apply_single, add_monoid_hom.coe_comp,
    function.comp_app, of_apply],
  exact finsupp.map_domain_single,
end

variables (G n)

/-- The `ℤ[G]`-linear map on `ℤ[Gⁿ⁺¹]` sending `g` to `g₀ • ⟦g⟧` as an element of the free
  `ℤ[G]`-module on the set `Gⁿ⁺¹` modulo the left action of `G`. -/
noncomputable def to_basis :
  group_ring (fin (n + 1) → G) →ₗ[group_ring G] (orbit_quot G n →₀ group_ring G) :=
mk_linear (to_basis_add_hom G n) $ λ x g,
begin
  refine map_smul_of_map_smul_of (to_basis_add_hom G n) _ _ _,
  intros g y,
  simp only [of_smul_of, to_basis_add_hom_of, ←of_apply],
  simp [smul_def, @quotient.sound' _ (mul_action.orbit_rel G _) _ y (set.mem_range_self g)],
end

variables {G n}

/-- Helper function sending `x ∈ Gⁿ⁺¹`, `g ∈ G`, `n ∈ ℤ` to `n • (g • x₀⁻¹ • x)`. -/
def of_basis_aux (x : fin (n + 1) → G) (g : G) : ℤ →+ (group_ring (fin (n + 1) → G)) :=
{ to_fun := finsupp.single_add_hom (g • (x 0)⁻¹ • x),
  map_zero' := finsupp.single_zero,
  map_add' := λ _ _, finsupp.single_add }

variables (G n)

/-- Inverse of `to_basis` from the free `ℤ[G]`-module on `Gⁿ⁺¹/G` to `ℤ[Gⁿ⁺¹]`,
  sending `⟦g⟧ ∈ Gⁿ⁺¹/G` to `g₀⁻¹ • g ∈ ℤ[Gⁿ⁺¹]` -/
def of_basis : (orbit_quot G n →₀ (group_ring G))
  →ₗ[group_ring G] group_ring (fin (n + 1) → G) :=
finsupp.lift (group_ring (fin (n + 1) → G)) (group_ring G) (orbit_quot G n)
  (λ y, quotient.lift_on' y (λ x, of _ ((x 0)⁻¹ • x)) $
  begin
    rintros a b ⟨c, rfl⟩,
    dsimp,
    congr' 1,
    ext i,
    simp [mul_assoc]
  end)

lemma left_inverse (x : group_ring (fin (n + 1) → G)) :
  of_basis G n (to_basis G n x) = x :=
begin
  refine ext ((of_basis G n).comp (to_basis G n)).to_add_monoid_hom
    (add_monoid_hom.id _) _,
  { intro g,
    dsimp,
    erw to_basis_add_hom_of,
    unfold of_basis,
    simpa only [quotient.lift_on'_mk', smul_inv_smul, of_smul_of, zero_smul,
      finsupp.sum_single_index, finsupp.lift_apply] },
end

lemma right_inverse (x : orbit_quot G n →₀ group_ring G) :
  to_basis G n (of_basis G n x) = x :=
begin
  refine x.induction_linear _ _ _,
  { simp only [linear_map.map_zero] },
  { intros f g hf hg,
    simp only [linear_map.map_add, hf, hg] },
  { intros a b,
    refine quotient.induction_on' a (λ c, _),
    unfold of_basis,
    simp only [quotient.lift_on'_mk', zero_smul, of_apply,
      finsupp.sum_single_index, linear_map.map_smul, finsupp.lift_apply],
    erw to_basis_add_hom_of,
    simp only [finsupp.smul_single', smul_eq_mul, of_apply,
      pi.smul_apply, mul_left_inv],
    erw mul_one,
    congr' 1,
    exact quotient.sound' (mul_action.mem_orbit _ _) }
end

/-- An isomorphism of `ℤ[Gⁿ⁺¹]` with the free `ℤ[G]`-module on the set `Gⁿ⁺¹`
  modulo the left action of `G`, given by `to_basis`. -/
def basis : basis (orbit_quot G n) (group_ring G) (group_ring (fin (n + 1) → G)) :=
{ repr :=
  { inv_fun := of_basis G n,
    left_inv := left_inverse G n,
    right_inv := right_inverse G n, ..to_basis G n } }

end group_ring