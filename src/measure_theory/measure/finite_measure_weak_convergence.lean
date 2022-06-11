/-
Copyright (c) 2021 Kalle Kytölä. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kalle Kytölä
-/
import measure_theory.measure.measure_space
import measure_theory.integral.set_integral
import topology.continuous_function.bounded
import topology.algebra.module.weak_dual
import topology.metric_space.thickened_indicator

/-!
# Weak convergence of (finite) measures

This file defines the topology of weak convergence of finite measures and probability measures
on topological spaces. The topology of weak convergence is the coarsest topology w.r.t. which
for every bounded continuous `ℝ≥0`-valued function `f`, the integration of `f` against the
measure is continuous.

TODOs:
* Prove that an equivalent definition of the topologies is obtained requiring continuity of
  integration of bounded continuous `ℝ`-valued functions instead.
* Include the portmanteau theorem on characterizations of weak convergence of (Borel) probability
  measures.

## Main definitions

The main definitions are the
 * types `finite_measure α` and `probability_measure α` with topologies of weak convergence;
 * `to_weak_dual_bcnn : finite_measure α → (weak_dual ℝ≥0 (α →ᵇ ℝ≥0))`
   allowing to interpret a finite measure as a continuous linear functional on the space of
   bounded continuous nonnegative functions on `α`. This is used for the definition of the
   topology of weak convergence.

## Main results

 * Finite measures `μ` on `α` give rise to continuous linear functionals on the space of
   bounded continuous nonnegative functions on `α` via integration:
   `to_weak_dual_bcnn : finite_measure α → (weak_dual ℝ≥0 (α →ᵇ ℝ≥0))`.
 * `tendsto_iff_forall_lintegral_tendsto`: Convergence of finite measures and probability measures
   is characterized by the convergence of integrals of all bounded continuous (nonnegative)
   functions. This essentially shows that the given definition of topology corresponds to the
   common textbook definition of weak convergence of measures.

TODO:
* Portmanteau theorem:
  * `finite_measure.limsup_measure_closed_le_of_tendsto` proves one implication.
    The current formulation assumes `pseudo_emetric_space`. The only reason is to have
    bounded continuous pointwise approximations to the indicator function of a closed set. Clearly
    for example metrizability or pseudo-emetrizability would be sufficient assumptions. The
    typeclass assumptions should be later adjusted in a way that takes into account use cases, but
    the proof will presumably remain essentially the same.
  * Prove the rest of the implications.

## Notations

No new notation is introduced.

## Implementation notes

The topology of weak convergence of finite Borel measures will be defined using a mapping from
`finite_measure α` to `weak_dual ℝ≥0 (α →ᵇ ℝ≥0)`, inheriting the topology from the latter.

The current implementation of `finite_measure α` and `probability_measure α` is directly as
subtypes of `measure α`, and the coercion to a function is the composition `ennreal.to_nnreal`
and the coercion to function of `measure α`. Another alternative would be to use a bijection
with `vector_measure α ℝ≥0` as an intermediate step. The choice of implementation should not have
drastic downstream effects, so it can be changed later if appropriate.

Potential advantages of using the `nnreal`-valued vector measure alternative:
 * The coercion to function would avoid need to compose with `ennreal.to_nnreal`, the
   `nnreal`-valued API could be more directly available.
Potential drawbacks of the vector measure alternative:
 * The coercion to function would lose monotonicity, as non-measurable sets would be defined to
   have measure 0.
 * No integration theory directly. E.g., the topology definition requires `lintegral` w.r.t.
   a coercion to `measure α` in any case.

## References

* [Billingsley, *Convergence of probability measures*][billingsley1999]

## Tags

weak convergence of measures, finite measure, probability measure

-/

noncomputable theory
open measure_theory
open set
open filter
open bounded_continuous_function
open_locale topological_space ennreal nnreal bounded_continuous_function

namespace measure_theory

variables {α : Type*} [measurable_space α]

/-- Finite measures are defined as the subtype of measures that have the property of being finite
measures (i.e., their total mass is finite). -/
def finite_measure (α : Type*) [measurable_space α] : Type* :=
{μ : measure α // is_finite_measure μ}

namespace finite_measure

/-- A finite measure can be interpreted as a measure. -/
instance : has_coe (finite_measure α) (measure_theory.measure α) := coe_subtype

instance is_finite_measure (μ : finite_measure α) :
  is_finite_measure (μ : measure α) := μ.prop

instance : has_coe_to_fun (finite_measure α) (λ _, set α → ℝ≥0) :=
⟨λ μ s, (μ s).to_nnreal⟩

lemma coe_fn_eq_to_nnreal_coe_fn_to_measure (ν : finite_measure α) :
  (ν : set α → ℝ≥0) = λ s, ((ν : measure α) s).to_nnreal := rfl

@[simp] lemma ennreal_coe_fn_eq_coe_fn_to_measure (ν : finite_measure α) (s : set α) :
  (ν s : ℝ≥0∞) = (ν : measure α) s := ennreal.coe_to_nnreal (measure_lt_top ↑ν s).ne

@[simp] lemma val_eq_to_measure (ν : finite_measure α) : ν.val = (ν : measure α) := rfl

lemma coe_injective : function.injective (coe : finite_measure α → measure α) :=
subtype.coe_injective

/-- The (total) mass of a finite measure `μ` is `μ univ`, i.e., the cast to `nnreal` of
`(μ : measure α) univ`. -/
def mass (μ : finite_measure α) : ℝ≥0 := μ univ

@[simp] lemma ennreal_mass {μ : finite_measure α} :
  (μ.mass : ℝ≥0∞) = (μ : measure α) univ := ennreal_coe_fn_eq_coe_fn_to_measure μ set.univ

instance has_zero : has_zero (finite_measure α) :=
{ zero := ⟨0, measure_theory.is_finite_measure_zero⟩ }

instance : inhabited (finite_measure α) := ⟨0⟩

instance : has_add (finite_measure α) :=
{ add := λ μ ν, ⟨μ + ν, measure_theory.is_finite_measure_add⟩ }

variables {R : Type*} [has_scalar R ℝ≥0] [has_scalar R ℝ≥0∞] [is_scalar_tower R ℝ≥0 ℝ≥0∞]
  [is_scalar_tower R ℝ≥0∞ ℝ≥0∞]

instance : has_scalar R (finite_measure α) :=
{ smul := λ (c : R) μ, ⟨c • μ, measure_theory.is_finite_measure_smul_of_nnreal_tower⟩, }

@[simp, norm_cast] lemma coe_zero : (coe : finite_measure α → measure α) 0 = 0 := rfl

@[simp, norm_cast] lemma coe_add (μ ν : finite_measure α) : ↑(μ + ν) = (↑μ + ↑ν : measure α) := rfl

@[simp, norm_cast] lemma coe_smul (c : R) (μ : finite_measure α) :
  ↑(c • μ) = (c • ↑μ : measure α) := rfl

@[simp, norm_cast] lemma coe_fn_zero :
  (⇑(0 : finite_measure α) : set α → ℝ≥0) = (0 : set α → ℝ≥0) := by { funext, refl, }

@[simp, norm_cast] lemma coe_fn_add (μ ν : finite_measure α) :
  (⇑(μ + ν) : set α → ℝ≥0) = (⇑μ + ⇑ν : set α → ℝ≥0) :=
by { funext, simp [← ennreal.coe_eq_coe], }

@[simp, norm_cast] lemma coe_fn_smul [is_scalar_tower R ℝ≥0 ℝ≥0] (c : R) (μ : finite_measure α) :
  (⇑(c • μ) : set α → ℝ≥0) = c • (⇑μ : set α → ℝ≥0) :=
by { funext, simp [← ennreal.coe_eq_coe, ennreal.coe_smul], }

instance : add_comm_monoid (finite_measure α) :=
finite_measure.coe_injective.add_comm_monoid coe coe_zero coe_add (λ _ _, coe_smul _ _)

/-- Coercion is an `add_monoid_hom`. -/
@[simps]
def coe_add_monoid_hom : finite_measure α →+ measure α :=
{ to_fun := coe, map_zero' := coe_zero, map_add' := coe_add }

instance {α : Type*} [measurable_space α] : module ℝ≥0 (finite_measure α) :=
function.injective.module _ coe_add_monoid_hom finite_measure.coe_injective coe_smul

variables [topological_space α]

/-- The pairing of a finite (Borel) measure `μ` with a nonnegative bounded continuous
function is obtained by (Lebesgue) integrating the (test) function against the measure.
This is `finite_measure.test_against_nn`. -/
def test_against_nn (μ : finite_measure α) (f : α →ᵇ ℝ≥0) : ℝ≥0 :=
(∫⁻ x, f x ∂(μ : measure α)).to_nnreal

lemma _root_.bounded_continuous_function.nnreal.to_ennreal_comp_measurable {α : Type*}
  [topological_space α] [measurable_space α] [opens_measurable_space α] (f : α →ᵇ ℝ≥0) :
  measurable (λ x, (f x : ℝ≥0∞)) :=
measurable_coe_nnreal_ennreal.comp f.continuous.measurable

lemma lintegral_lt_top_of_bounded_continuous_to_nnreal (μ : finite_measure α) (f : α →ᵇ ℝ≥0) :
  ∫⁻ x, f x ∂(μ : measure α) < ∞ :=
begin
  apply is_finite_measure.lintegral_lt_top_of_bounded_to_ennreal,
  use nndist f 0,
  intros x,
  have key := bounded_continuous_function.nnreal.upper_bound f x,
  rw ennreal.coe_le_coe,
  have eq : nndist f 0 = ⟨dist f 0, dist_nonneg⟩,
  { ext,
    simp only [real.coe_to_nnreal', max_eq_left_iff, subtype.coe_mk, coe_nndist], },
  rwa eq at key,
end

@[simp] lemma test_against_nn_coe_eq {μ : finite_measure α} {f : α →ᵇ ℝ≥0} :
  (μ.test_against_nn f : ℝ≥0∞) = ∫⁻ x, f x ∂(μ : measure α) :=
ennreal.coe_to_nnreal (lintegral_lt_top_of_bounded_continuous_to_nnreal μ f).ne

lemma test_against_nn_const (μ : finite_measure α) (c : ℝ≥0) :
  μ.test_against_nn (bounded_continuous_function.const α c) = c * μ.mass :=
by simp [← ennreal.coe_eq_coe]

lemma test_against_nn_mono (μ : finite_measure α)
  {f g : α →ᵇ ℝ≥0} (f_le_g : (f : α → ℝ≥0) ≤ g) :
  μ.test_against_nn f ≤ μ.test_against_nn g :=
begin
  simp only [←ennreal.coe_le_coe, test_against_nn_coe_eq],
  apply lintegral_mono,
  exact λ x, ennreal.coe_mono (f_le_g x),
end

variables [opens_measurable_space α]

lemma test_against_nn_add (μ : finite_measure α) (f₁ f₂ : α →ᵇ ℝ≥0) :
  μ.test_against_nn (f₁ + f₂) = μ.test_against_nn f₁ + μ.test_against_nn f₂ :=
begin
  simp only [←ennreal.coe_eq_coe, bounded_continuous_function.coe_add, ennreal.coe_add,
             pi.add_apply, test_against_nn_coe_eq],
  exact lintegral_add_left (bounded_continuous_function.nnreal.to_ennreal_comp_measurable _) _
end

lemma test_against_nn_smul [is_scalar_tower R ℝ≥0 ℝ≥0] [pseudo_metric_space R] [has_zero R]
  [has_bounded_smul R ℝ≥0]
  (μ : finite_measure α) (c : R) (f : α →ᵇ ℝ≥0) :
  μ.test_against_nn (c • f) = c • μ.test_against_nn f :=
begin
  simp only [←ennreal.coe_eq_coe, bounded_continuous_function.coe_smul,
             test_against_nn_coe_eq, ennreal.coe_smul],
  simp_rw [←smul_one_smul ℝ≥0∞ c (f _ : ℝ≥0∞), ←smul_one_smul ℝ≥0∞ c (lintegral _ _ : ℝ≥0∞),
           smul_eq_mul],
  exact @lintegral_const_mul _ _ (μ : measure α) (c • 1)  _
                   (bounded_continuous_function.nnreal.to_ennreal_comp_measurable f),
end

lemma test_against_nn_lipschitz_estimate (μ : finite_measure α) (f g : α →ᵇ ℝ≥0) :
  μ.test_against_nn f ≤ μ.test_against_nn g + (nndist f g) * μ.mass :=
begin
  simp only [←μ.test_against_nn_const (nndist f g), ←test_against_nn_add, ←ennreal.coe_le_coe,
             bounded_continuous_function.coe_add, const_apply, ennreal.coe_add, pi.add_apply,
             coe_nnreal_ennreal_nndist, test_against_nn_coe_eq],
  apply lintegral_mono,
  have le_dist : ∀ x, dist (f x) (g x) ≤ nndist f g :=
  bounded_continuous_function.dist_coe_le_dist,
  intros x,
  have le' : f(x) ≤ g(x) + nndist f g,
  { apply (nnreal.le_add_nndist (f x) (g x)).trans,
    rw add_le_add_iff_left,
    exact dist_le_coe.mp (le_dist x), },
  have le : (f(x) : ℝ≥0∞) ≤ (g(x) : ℝ≥0∞) + (nndist f g),
  by { rw ←ennreal.coe_add, exact ennreal.coe_mono le', },
  rwa [coe_nnreal_ennreal_nndist] at le,
end

lemma test_against_nn_lipschitz (μ : finite_measure α) :
  lipschitz_with μ.mass (λ (f : α →ᵇ ℝ≥0), μ.test_against_nn f) :=
begin
  rw lipschitz_with_iff_dist_le_mul,
  intros f₁ f₂,
  suffices : abs (μ.test_against_nn f₁ - μ.test_against_nn f₂ : ℝ) ≤ μ.mass * (dist f₁ f₂),
  { rwa nnreal.dist_eq, },
  apply abs_le.mpr,
  split,
  { have key' := μ.test_against_nn_lipschitz_estimate f₂ f₁,
    rw mul_comm at key',
    suffices : ↑(μ.test_against_nn f₂) ≤ ↑(μ.test_against_nn f₁) + ↑(μ.mass) * dist f₁ f₂,
    { linarith, },
    have key := nnreal.coe_mono key',
    rwa [nnreal.coe_add, nnreal.coe_mul, nndist_comm] at key, },
  { have key' := μ.test_against_nn_lipschitz_estimate f₁ f₂,
    rw mul_comm at key',
    suffices : ↑(μ.test_against_nn f₁) ≤ ↑(μ.test_against_nn f₂) + ↑(μ.mass) * dist f₁ f₂,
    { linarith, },
    have key := nnreal.coe_mono key',
    rwa [nnreal.coe_add, nnreal.coe_mul] at key, },
end

/-- Finite measures yield elements of the `weak_dual` of bounded continuous nonnegative
functions via `finite_measure.test_against_nn`, i.e., integration. -/
def to_weak_dual_bcnn (μ : finite_measure α) :
  weak_dual ℝ≥0 (α →ᵇ ℝ≥0) :=
{ to_fun := λ f, μ.test_against_nn f,
  map_add' := test_against_nn_add μ,
  map_smul' := test_against_nn_smul μ,
  cont := μ.test_against_nn_lipschitz.continuous, }

@[simp] lemma coe_to_weak_dual_bcnn (μ : finite_measure α) :
  ⇑μ.to_weak_dual_bcnn = μ.test_against_nn := rfl

@[simp] lemma to_weak_dual_bcnn_apply (μ : finite_measure α) (f : α →ᵇ ℝ≥0) :
  μ.to_weak_dual_bcnn f = (∫⁻ x, f x ∂(μ : measure α)).to_nnreal := rfl

/-- The topology of weak convergence on `finite_measures α` is inherited (induced) from the weak-*
topology on `weak_dual ℝ≥0 (α →ᵇ ℝ≥0)` via the function `finite_measures.to_weak_dual_bcnn`. -/
instance : topological_space (finite_measure α) :=
topological_space.induced to_weak_dual_bcnn infer_instance

lemma to_weak_dual_bcnn_continuous :
  continuous (@finite_measure.to_weak_dual_bcnn α _ _ _) :=
continuous_induced_dom

/- Integration of (nonnegative bounded continuous) test functions against finite Borel measures
depends continuously on the measure. -/
lemma continuous_test_against_nn_eval (f : α →ᵇ ℝ≥0) :
  continuous (λ (μ : finite_measure α), μ.test_against_nn f) :=
(by apply (weak_bilin.eval_continuous _ _).comp to_weak_dual_bcnn_continuous :
  continuous ((λ φ : weak_dual ℝ≥0 (α →ᵇ ℝ≥0), φ f) ∘ to_weak_dual_bcnn))

lemma tendsto_iff_weak_star_tendsto {γ : Type*} {F : filter γ}
  {μs : γ → finite_measure α} {μ : finite_measure α} :
  tendsto μs F (𝓝 μ) ↔ tendsto (λ i, (μs(i)).to_weak_dual_bcnn) F (𝓝 μ.to_weak_dual_bcnn) :=
inducing.tendsto_nhds_iff ⟨rfl⟩

theorem tendsto_iff_forall_test_against_nn_tendsto {γ : Type*} {F : filter γ}
  {μs : γ → finite_measure α} {μ : finite_measure α} :
  tendsto μs F (𝓝 μ) ↔
  ∀ (f : α →ᵇ ℝ≥0), tendsto (λ i, (μs(i)).to_weak_dual_bcnn f) F (𝓝 (μ.to_weak_dual_bcnn f)) :=
by { rw [tendsto_iff_weak_star_tendsto, tendsto_iff_forall_eval_tendsto_top_dual_pairing], refl, }

theorem tendsto_iff_forall_lintegral_tendsto {γ : Type*} {F : filter γ}
  {μs : γ → finite_measure α} {μ : finite_measure α} :
  tendsto μs F (𝓝 μ) ↔
  ∀ (f : α →ᵇ ℝ≥0),
    tendsto (λ i, (∫⁻ x, (f x) ∂(μs(i) : measure α))) F (𝓝 ((∫⁻ x, (f x) ∂(μ : measure α)))) :=
begin
  rw tendsto_iff_forall_test_against_nn_tendsto,
  simp_rw [to_weak_dual_bcnn_apply _ _, ←test_against_nn_coe_eq,
           ennreal.tendsto_coe, ennreal.to_nnreal_coe],
end

/-- A bounded convergence theorem for a finite measure:
If bounded continuous non-negative functions are uniformly bounded by a constant and tend to a
limit, then their integrals against the finite measure tend to the integral of the limit.
This formulation assumes:
 * the functions tend to a limit along a countably generated filter;
 * the limit is in the almost everywhere sense;
 * boundedness holds almost everywhere;
 * integration is `lintegral`, i.e., the functions and their integrals are `ℝ≥0∞`-valued.
-/
lemma tendsto_lintegral_nn_filter_of_le_const {ι : Type*} {L : filter ι} [L.is_countably_generated]
  (μ : finite_measure α) {fs : ι → (α →ᵇ ℝ≥0)} {c : ℝ≥0}
  (fs_le_const : ∀ᶠ i in L, ∀ᵐ (a : α) ∂(μ : measure α), fs i a ≤ c) {f : α → ℝ≥0}
  (fs_lim : ∀ᵐ (a : α) ∂(μ : measure α), tendsto (λ i, fs i a) L (𝓝 (f a))) :
  tendsto (λ i, (∫⁻ a, fs i a ∂(μ : measure α))) L (𝓝 (∫⁻ a, (f a) ∂(μ : measure α))) :=
begin
  simpa only using tendsto_lintegral_filter_of_dominated_convergence (λ _, c)
    (eventually_of_forall ((λ i, (ennreal.continuous_coe.comp (fs i).continuous).measurable)))
    _ ((@lintegral_const_lt_top _ _ (μ : measure α) _ _ (@ennreal.coe_ne_top c)).ne) _,
  { simpa only [ennreal.coe_le_coe] using fs_le_const, },
  { simpa only [ennreal.tendsto_coe] using fs_lim, },
end

/-- A bounded convergence theorem for a finite measure:
If a sequence of bounded continuous non-negative functions are uniformly bounded by a constant
and tend pointwise to a limit, then their integrals (`lintegral`) against the finite measure tend
to the integral of the limit.

A related result with more general assumptions is `tendsto_lintegral_nn_filter_of_le_const`.
-/
lemma tendsto_lintegral_nn_of_le_const (μ : finite_measure α) {fs : ℕ → (α →ᵇ ℝ≥0)} {c : ℝ≥0}
  (fs_le_const : ∀ n a, fs n a ≤ c) {f : α → ℝ≥0}
  (fs_lim : ∀ a, tendsto (λ n, fs n a) at_top (𝓝 (f a))) :
  tendsto (λ n, (∫⁻ a, fs n a ∂(μ : measure α))) at_top (𝓝 (∫⁻ a, (f a) ∂(μ : measure α))) :=
tendsto_lintegral_nn_filter_of_le_const μ
  (eventually_of_forall (λ n, eventually_of_forall (fs_le_const n))) (eventually_of_forall fs_lim)

/-- A bounded convergence theorem for a finite measure:
If bounded continuous non-negative functions are uniformly bounded by a constant and tend to a
limit, then their integrals against the finite measure tend to the integral of the limit.
This formulation assumes:
 * the functions tend to a limit along a countably generated filter;
 * the limit is in the almost everywhere sense;
 * boundedness holds almost everywhere;
 * integration is the pairing against non-negative continuous test functions (`test_against_nn`).

A related result using `lintegral` for integration is `tendsto_lintegral_nn_filter_of_le_const`.
-/
lemma tendsto_test_against_nn_filter_of_le_const {ι : Type*} {L : filter ι}
  [L.is_countably_generated] {μ : finite_measure α} {fs : ι → (α →ᵇ ℝ≥0)} {c : ℝ≥0}
  (fs_le_const : ∀ᶠ i in L, ∀ᵐ (a : α) ∂(μ : measure α), fs i a ≤ c) {f : α →ᵇ ℝ≥0}
  (fs_lim : ∀ᵐ (a : α) ∂(μ : measure α), tendsto (λ i, fs i a) L (𝓝 (f a))) :
  tendsto (λ i, μ.test_against_nn (fs i)) L (𝓝 (μ.test_against_nn f)) :=
begin
  apply (ennreal.tendsto_to_nnreal
         (μ.lintegral_lt_top_of_bounded_continuous_to_nnreal f).ne).comp,
  exact finite_measure.tendsto_lintegral_nn_filter_of_le_const μ fs_le_const fs_lim,
end

/-- A bounded convergence theorem for a finite measure:
If a sequence of bounded continuous non-negative functions are uniformly bounded by a constant
and tend pointwise to a limit, then their integrals (`test_against_nn`) against the finite measure
tend to the integral of the limit.

Related results:
 * `tendsto_test_against_nn_filter_of_le_const`: more general assumptions
 * `tendsto_lintegral_nn_of_le_const`: using `lintegral` for integration.
-/
lemma tendsto_test_against_nn_of_le_const {μ : finite_measure α}
  {fs : ℕ → (α →ᵇ ℝ≥0)} {c : ℝ≥0} (fs_le_const : ∀ n a, fs n a ≤ c) {f : α →ᵇ ℝ≥0}
  (fs_lim : ∀ a, tendsto (λ n, fs n a) at_top (𝓝 (f a))) :
  tendsto (λ n, μ.test_against_nn (fs n)) at_top (𝓝 (μ.test_against_nn f)) :=
tendsto_test_against_nn_filter_of_le_const
  (eventually_of_forall (λ n, eventually_of_forall (fs_le_const n))) (eventually_of_forall fs_lim)

end finite_measure

/-- Probability measures are defined as the subtype of measures that have the property of being
probability measures (i.e., their total mass is one). -/
def probability_measure (α : Type*) [measurable_space α] : Type* :=
{μ : measure α // is_probability_measure μ}

namespace probability_measure

instance [inhabited α] : inhabited (probability_measure α) :=
⟨⟨measure.dirac default, measure.dirac.is_probability_measure⟩⟩

/-- A probability measure can be interpreted as a measure. -/
instance : has_coe (probability_measure α) (measure_theory.measure α) := coe_subtype

instance : has_coe_to_fun (probability_measure α) (λ _, set α → ℝ≥0) :=
⟨λ μ s, (μ s).to_nnreal⟩

instance (μ : probability_measure α) : is_probability_measure (μ : measure α) := μ.prop

lemma coe_fn_eq_to_nnreal_coe_fn_to_measure (ν : probability_measure α) :
  (ν : set α → ℝ≥0) = λ s, ((ν : measure α) s).to_nnreal := rfl

@[simp] lemma val_eq_to_measure (ν : probability_measure α) : ν.val = (ν : measure α) := rfl

lemma coe_injective : function.injective (coe : probability_measure α → measure α) :=
subtype.coe_injective

@[simp] lemma coe_fn_univ (ν : probability_measure α) : ν univ = 1 :=
congr_arg ennreal.to_nnreal ν.prop.measure_univ

/-- A probability measure can be interpreted as a finite measure. -/
def to_finite_measure (μ : probability_measure α) : finite_measure α := ⟨μ, infer_instance⟩

@[simp] lemma coe_comp_to_finite_measure_eq_coe (ν : probability_measure α) :
  (ν.to_finite_measure : measure α) = (ν : measure α) := rfl

@[simp] lemma coe_fn_comp_to_finite_measure_eq_coe_fn (ν : probability_measure α) :
  (ν.to_finite_measure : set α → ℝ≥0) = (ν : set α → ℝ≥0) := rfl

@[simp] lemma ennreal_coe_fn_eq_coe_fn_to_measure (ν : probability_measure α) (s : set α) :
  (ν s : ℝ≥0∞) = (ν : measure α) s :=
by { rw [← coe_fn_comp_to_finite_measure_eq_coe_fn,
     finite_measure.ennreal_coe_fn_eq_coe_fn_to_measure], refl, }

@[simp] lemma mass_to_finite_measure (μ : probability_measure α) :
  μ.to_finite_measure.mass = 1 := μ.coe_fn_univ

variables [topological_space α]

lemma lintegral_lt_top_of_bounded_continuous_to_nnreal (μ : probability_measure α) (f : α →ᵇ ℝ≥0) :
  ∫⁻ x, f x ∂(μ : measure α) < ∞ :=
μ.to_finite_measure.lintegral_lt_top_of_bounded_continuous_to_nnreal f

variables [opens_measurable_space α]

lemma test_against_nn_lipschitz (μ : probability_measure α) :
  lipschitz_with 1 (λ (f : α →ᵇ ℝ≥0), μ.to_finite_measure.test_against_nn f) :=
μ.mass_to_finite_measure ▸ μ.to_finite_measure.test_against_nn_lipschitz

/-- The topology of weak convergence on `probability_measures α`. This is inherited (induced) from
the weak-*  topology on `weak_dual ℝ≥0 (α →ᵇ ℝ≥0)` via the function
`probability_measures.to_weak_dual_bcnn`. -/
instance : topological_space (probability_measure α) :=
topological_space.induced to_finite_measure infer_instance

lemma to_finite_measure_continuous :
  continuous (to_finite_measure : probability_measure α → finite_measure α) :=
continuous_induced_dom

/-- Probability measures yield elements of the `weak_dual` of bounded continuous nonnegative
functions via `finite_measure.test_against_nn`, i.e., integration. -/
def to_weak_dual_bcnn : probability_measure α → weak_dual ℝ≥0 (α →ᵇ ℝ≥0) :=
finite_measure.to_weak_dual_bcnn ∘ to_finite_measure

@[simp] lemma coe_to_weak_dual_bcnn (μ : probability_measure α) :
  ⇑μ.to_weak_dual_bcnn = μ.to_finite_measure.test_against_nn := rfl

@[simp] lemma to_weak_dual_bcnn_apply (μ : probability_measure α) (f : α →ᵇ ℝ≥0) :
  μ.to_weak_dual_bcnn f = (∫⁻ x, f x ∂(μ : measure α)).to_nnreal := rfl

lemma to_weak_dual_bcnn_continuous :
  continuous (λ (μ : probability_measure α), μ.to_weak_dual_bcnn) :=
finite_measure.to_weak_dual_bcnn_continuous.comp to_finite_measure_continuous

/- Integration of (nonnegative bounded continuous) test functions against Borel probability
measures depends continuously on the measure. -/
lemma continuous_test_against_nn_eval (f : α →ᵇ ℝ≥0) :
  continuous (λ (μ : probability_measure α), μ.to_finite_measure.test_against_nn f) :=
(finite_measure.continuous_test_against_nn_eval f).comp to_finite_measure_continuous

/- The canonical mapping from probability measures to finite measures is an embedding. -/
lemma to_finite_measure_embedding (α : Type*)
  [measurable_space α] [topological_space α] [opens_measurable_space α] :
  embedding (to_finite_measure : probability_measure α → finite_measure α) :=
{ induced := rfl,
  inj := λ μ ν h, subtype.eq (by convert congr_arg coe h) }

lemma tendsto_nhds_iff_to_finite_measures_tendsto_nhds {δ : Type*}
  (F : filter δ) {μs : δ → probability_measure α} {μ₀ : probability_measure α} :
  tendsto μs F (𝓝 μ₀) ↔ tendsto (to_finite_measure ∘ μs) F (𝓝 (μ₀.to_finite_measure)) :=
embedding.tendsto_nhds_iff (probability_measure.to_finite_measure_embedding α)

/-- The usual definition of weak convergence of probability measures is given in terms of sequences
of probability measures: it is the requirement that the integrals of all continuous bounded
functions against members of the sequence converge. This version is a characterization using
nonnegative bounded continuous functions. -/
theorem tendsto_iff_forall_lintegral_tendsto {γ : Type*} {F : filter γ}
  {μs : γ → probability_measure α} {μ : probability_measure α} :
  tendsto μs F (𝓝 μ) ↔
  ∀ (f : α →ᵇ ℝ≥0), tendsto (λ i, (∫⁻ x, (f x) ∂(μs(i) : measure α))) F
    (𝓝 ((∫⁻ x, (f x) ∂(μ : measure α)))) :=
begin
  rw tendsto_nhds_iff_to_finite_measures_tendsto_nhds,
  exact finite_measure.tendsto_iff_forall_lintegral_tendsto,
end

end probability_measure

section convergence_implies_limsup_closed_le

/-- If bounded continuous functions tend to the indicator of a measurable set and are
uniformly bounded, then their integrals against a finite measure tend to the measure of the set.
This formulation assumes:
 * the functions tend to a limit along a countably generated filter;
 * the limit is in the almost everywhere sense;
 * boundedness holds almost everywhere.
-/
lemma measure_of_cont_bdd_of_tendsto_filter_indicator {ι : Type*} {L : filter ι}
  [L.is_countably_generated] [topological_space α] [opens_measurable_space α]
  (μ : finite_measure α) {c : ℝ≥0} {E : set α} (E_mble : measurable_set E)
  (fs : ι → (α →ᵇ ℝ≥0)) (fs_bdd : ∀ᶠ i in L, ∀ᵐ (a : α) ∂(μ : measure α), fs i a ≤ c)
  (fs_lim : ∀ᵐ (a : α) ∂(μ : measure α),
            tendsto (λ (i : ι), (coe_fn : (α →ᵇ ℝ≥0) → (α → ℝ≥0)) (fs i) a) L
                    (𝓝 (indicator E (λ x, (1 : ℝ≥0)) a))) :
  tendsto (λ n, lintegral (μ : measure α) (λ a, fs n a)) L (𝓝 ((μ : measure α) E)) :=
begin
  convert finite_measure.tendsto_lintegral_nn_filter_of_le_const μ fs_bdd fs_lim,
  have aux : ∀ a, indicator E (λ x, (1 : ℝ≥0∞)) a = ↑(indicator E (λ x, (1 : ℝ≥0)) a),
  from λ a, by simp only [ennreal.coe_indicator, ennreal.coe_one],
  simp_rw [←aux, lintegral_indicator _ E_mble],
  simp only [lintegral_one, measure.restrict_apply, measurable_set.univ, univ_inter],
end

/-- If a sequence of bounded continuous functions tends to the indicator of a measurable set and
the functions are uniformly bounded, then their integrals against a finite measure tend to the
measure of the set.

A similar result with more general assumptions is `measure_of_cont_bdd_of_tendsto_filter_indicator`.
-/
lemma measure_of_cont_bdd_of_tendsto_indicator
  [topological_space α] [opens_measurable_space α]
  (μ : finite_measure α) {c : ℝ≥0} {E : set α} (E_mble : measurable_set E)
  (fs : ℕ → (α →ᵇ ℝ≥0)) (fs_bdd : ∀ n a, fs n a ≤ c)
  (fs_lim : tendsto (λ (n : ℕ), (coe_fn : (α →ᵇ ℝ≥0) → (α → ℝ≥0)) (fs n))
            at_top (𝓝 (indicator E (λ x, (1 : ℝ≥0))))) :
  tendsto (λ n, lintegral (μ : measure α) (λ a, fs n a)) at_top (𝓝 ((μ : measure α) E)) :=
begin
  have fs_lim' : ∀ a, tendsto (λ (n : ℕ), (fs n a : ℝ≥0))
                 at_top (𝓝 (indicator E (λ x, (1 : ℝ≥0)) a)),
  by { rw tendsto_pi_nhds at fs_lim, exact λ a, fs_lim a, },
  apply measure_of_cont_bdd_of_tendsto_filter_indicator μ E_mble fs
      (eventually_of_forall (λ n, eventually_of_forall (fs_bdd n))) (eventually_of_forall fs_lim'),
end

/-- The integrals of thickenined indicators of a closed set against a finite measure tend to the
measure of the closed set if the thickening radii tend to zero.
-/
lemma tendsto_lintegral_thickened_indicator_of_is_closed
  {α : Type*} [measurable_space α] [pseudo_emetric_space α] [opens_measurable_space α]
  (μ : finite_measure α) {F : set α} (F_closed : is_closed F) {δs : ℕ → ℝ}
  (δs_pos : ∀ n, 0 < δs n) (δs_lim : tendsto δs at_top (𝓝 0)) :
  tendsto (λ n, lintegral (μ : measure α) (λ a, (thickened_indicator (δs_pos n) F a : ℝ≥0∞)))
          at_top (𝓝 ((μ : measure α) F)) :=
begin
  apply measure_of_cont_bdd_of_tendsto_indicator μ F_closed.measurable_set
          (λ n, thickened_indicator (δs_pos n) F)
          (λ n a, thickened_indicator_le_one (δs_pos n) F a),
  have key := thickened_indicator_tendsto_indicator_closure δs_pos δs_lim F,
  rwa F_closed.closure_eq at key,
end

/-- One implication of the portmanteau theorem:
Weak convergence of finite measures implies that the limsup of the measures of any closed set is
at most the measure of the closed set under the limit measure.
-/
lemma finite_measure.limsup_measure_closed_le_of_tendsto
  {α ι : Type*} {L : filter ι}
  [measurable_space α] [pseudo_emetric_space α] [opens_measurable_space α]
  {μ : finite_measure α} {μs : ι → finite_measure α}
  (μs_lim : tendsto μs L (𝓝 μ)) {F : set α} (F_closed : is_closed F) :
  L.limsup (λ i, (μs i : measure α) F) ≤ (μ : measure α) F :=
begin
  by_cases L = ⊥,
  { simp only [h, limsup, filter.map_bot, Limsup_bot, ennreal.bot_eq_zero, zero_le], },
  apply ennreal.le_of_forall_pos_le_add,
  intros ε ε_pos μ_F_finite,
  set δs := λ (n : ℕ), (1 : ℝ) / (n+1) with def_δs,
  have δs_pos : ∀ n, 0 < δs n, from λ n, nat.one_div_pos_of_nat,
  have δs_lim : tendsto δs at_top (𝓝 0), from tendsto_one_div_add_at_top_nhds_0_nat,
  have key₁ := tendsto_lintegral_thickened_indicator_of_is_closed μ F_closed δs_pos δs_lim,
  have room₁ : (μ : measure α) F < (μ : measure α) F + ε / 2,
  { apply ennreal.lt_add_right (measure_lt_top (μ : measure α) F).ne
          ((ennreal.div_pos_iff.mpr
              ⟨(ennreal.coe_pos.mpr ε_pos).ne.symm, ennreal.two_ne_top⟩).ne.symm), },
  rcases eventually_at_top.mp (eventually_lt_of_tendsto_lt room₁ key₁) with ⟨M, hM⟩,
  have key₂ := finite_measure.tendsto_iff_forall_lintegral_tendsto.mp
                μs_lim (thickened_indicator (δs_pos M) F),
  have room₂ : lintegral (μ : measure α) (λ a, thickened_indicator (δs_pos M) F a)
                < lintegral (μ : measure α) (λ a, thickened_indicator (δs_pos M) F a) + ε / 2,
  { apply ennreal.lt_add_right
          (finite_measure.lintegral_lt_top_of_bounded_continuous_to_nnreal μ _).ne
          ((ennreal.div_pos_iff.mpr
              ⟨(ennreal.coe_pos.mpr ε_pos).ne.symm, ennreal.two_ne_top⟩).ne.symm), },
  have ev_near := eventually.mono (eventually_lt_of_tendsto_lt room₂ key₂) (λ n, le_of_lt),
  have aux := λ n, le_trans (measure_le_lintegral_thickened_indicator
                            (μs n : measure α) F_closed.measurable_set (δs_pos M)),
  have ev_near' := eventually.mono ev_near aux,
  apply (filter.limsup_le_limsup ev_near').trans,
  haveI : ne_bot L, from ⟨h⟩,
  rw limsup_const,
  apply le_trans (add_le_add (hM M rfl.le).le (le_refl (ε/2 : ℝ≥0∞))),
  simp only [add_assoc, ennreal.add_halves, le_refl],
end

end convergence_implies_limsup_closed_le

end measure_theory
