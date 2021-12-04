/-
Copyright (c) 2021 Grayson Burton. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Grayson Burton, Violeta Hernández Palacios.
-/
import combinatorics.polytopes.flag

namespace polytope

universe u

/-- The diamond property. -/
def diamond (α : Type u) [preorder α] [graded α] : Prop :=
∀ {a b : α}, a < b → graded.grade b = graded.grade a + 2 → ∃ x y, x ≠ y ∧ set.Ioo a b = {x, y}

/-- A prepolytope is a graded partial order satisfying the diamond condition. -/
class prepolytope (α : Type u) extends partial_order α, order_top α, graded α : Type u :=
(diamond' : diamond α)

/-- A polytope is a strongly connected prepolytope. -/
class polytope (α : Type u) extends prepolytope α : Type u :=
(scon : graded.strong_connected α)

/-- The dual of a prepolytope. -/
instance (α : Type u) [prepolytope α] : prepolytope (order_dual α) :=
⟨ begin
  intros a b hab hg,
  unfold graded.grade at hg,
  have : @graded.grade α _ _ a =  @graded.grade α _ _ b + 2 := begin
    have := @graded.grade_le_grade_top α _ _ _ a,
    have := @graded.grade_le_grade_top α _ _ _ b,
    linarith,
  end,
  rcases prepolytope.diamond' hab this with ⟨x, y, hne, hxy⟩,
  refine ⟨x, y, hne, _⟩,
  suffices : set.Ioo a b = @set.Ioo α _ b a, { rwa this },
  refine set.ext (λ _, ⟨_, _⟩),
  repeat { exact (λ h, ⟨h.right, h.left⟩) },
end ⟩

/-- Any graded poset of top grade less or equal to 1 satisfies the diamond property. -/
lemma diamond_of_grade_le_one (α : Type u) [partial_order α] [order_top α] [graded α] :
  graded.grade_top α ≤ 1 → diamond α :=
begin
  intros h _ b _ _,
  have := le_trans (graded.grade_le_grade_top b) h,
  linarith,
end

/-- The nullitope, the unique graded poset of top grade 0. -/
@[reducible] def nullitope : Type := fin 1

/-- The point, the unique graded poset of top grade 1. -/
@[reducible] def point : Type := fin 2

/-- The nullitope is a prepolytope. This is the unique graded poset of top grade 0. -/
instance : prepolytope nullitope :=
⟨ by apply diamond_of_grade_le_one; exact zero_le_one ⟩

/-- The nullitope is a polytope. This is the unique graded poset of top grade 0. -/
instance : polytope nullitope :=
{ scon := by apply graded.scon_of_grade_le_two; exact zero_le_two }

/-- The point as a prepolytope. This is the unique graded poset of top grade 1. -/
instance : prepolytope point :=
⟨ by apply diamond_of_grade_le_one; exact le_rfl ⟩

/-- The point as a polytope. This is the unique graded poset of top grade 1. -/
instance : polytope point :=
{ scon := by apply graded.scon_of_grade_le_two; exact one_le_two }

end polytope
