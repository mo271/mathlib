/-
Copyright (c) 2022 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison
-/
import representation_theory.Rep
import algebra.category.FinVect.limits
import category_theory.preadditive.schur

/-!
# `fdRep k G` is the category of finite dimensional `k`-linear representations of `G`.

If `V : fdRep k G`, there is a coercion that allows you to treat `V` as a type,
and this type comes equipped with `module k V` and `finite_dimensional k V` instances.
Also `V.ρ` gives the homomorphism `G →* (V →ₗ[k] V)`.

Conversely, given a homomorphism `ρ : G →* (V →ₗ[k] V)`,
you can construct the bundled representation as `Rep.of ρ`.

We verify that `fdRep k G` is a `k`-linear monoidal category, and rigid when `G` is a group.

`fdRep k G` has all finite limits.

## TODO
* `fdRep k G ≌ { V : Rep k G // finite_dimensional k V }`
* Upgrade the right rigid structure to a rigid structure (this just needs to be done for `FinVect`).
* `fdRep k G` has all finite colimits.
* `fdRep k G` is abelian.
* `fdRep k G ≌ FinVect (monoid_algebra k G)` (this will require generalising `FinVect` first).
-/

universes u

open category_theory
open category_theory.limits

/-- The category of finite dimensional `k`-linear representations of a monoid `G`. -/
@[derive [large_category, concrete_category, preadditive, has_finite_limits]]
abbreviation fdRep (k G : Type u) [field k] [monoid G] :=
Action (FinVect.{u} k) (Mon.of G)

namespace fdRep

variables {k G : Type u} [field k] [monoid G]

instance : linear k (fdRep k G) := by apply_instance

instance : has_coe_to_sort (fdRep k G) (Type u) := concrete_category.has_coe_to_sort _

instance (V : fdRep k G) : add_comm_group V :=
by { change add_comm_group ((forget₂ (fdRep k G) (FinVect k)).obj V), apply_instance, }

instance (V : fdRep k G) : module k V :=
by { change module k ((forget₂ (fdRep k G) (FinVect k)).obj V), apply_instance, }

instance (V : fdRep k G) : finite_dimensional k V :=
by { change finite_dimensional k ((forget₂ (fdRep k G) (FinVect k)).obj V), apply_instance, }

/-- All hom spaces are finite dimensional. -/
instance (V W : fdRep k G) : finite_dimensional k (V ⟶ W) :=
finite_dimensional.of_injective
  ((forget₂ (fdRep k G) (FinVect k)).map_linear_map k) (functor.map_injective _)

-- This works well with the new design for representations:
example (V : fdRep k G) : G →* (V →ₗ[k] V) := V.ρ

/-- Lift an unbundled representation to `Rep`. -/
@[simps ρ]
def of {V : Type u} [add_comm_group V] [module k V] [finite_dimensional k V]
  (ρ : G →* (V →ₗ[k] V)) : Rep k G :=
⟨FinVect.of k V, ρ⟩

instance : has_forget₂ (fdRep k G) (Rep k G) :=
{ forget₂ := (forget₂ (FinVect k) (Module k)).map_Action (Mon.of G), }

-- Verify that the monoidal structure is available.
example : monoidal_category (fdRep k G) := by apply_instance
example : monoidal_preadditive (fdRep k G) := by apply_instance
example : monoidal_linear k (fdRep k G) := by apply_instance

open finite_dimensional

-- Verify that Schur's lemma applies out of the box.
example [is_alg_closed k] (V W : fdRep k G) [simple V] [simple W] :
  finrank k (V ⟶ W) = 1 ↔ nonempty (V ≅ W) :=
finrank_hom_simple_simple_eq_one_iff k V W
example [is_alg_closed k] (V W : fdRep k G) [simple V] [simple W] :
  finrank k (V ⟶ W) = 0 ↔ is_empty (V ≅ W) :=
finrank_hom_simple_simple_eq_zero_iff k V W

end fdRep

namespace fdRep
variables {k G : Type u} [field k] [group G]

-- Verify that the rigid structure is available when the monoid is a group.
noncomputable instance : right_rigid_category (fdRep k G) :=
by { change right_rigid_category (Action (FinVect k) (Group.of G)), apply_instance, }

end fdRep