/-
Copyright (c) 2020 Kyle Miller. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Kyle Miller
-/
import combinatorics.simple_graph.basic
import combinatorics.simple_graph.subgraph
import tactic.omega
/-!

# Graph connectivity

In a simple graph,

* A *walk* is a finite sequence of adjacent vertices, and can be
  thought of equally well as a sequence of edges.

* A *trail* is a walk whose edges each appear no more than once.

* A *path* is a trail whose vertices appear no more than once.

* A *cycle* is a nonempty trail whose first and last vertices are the
  same and whose vertices except for the first appear no more than once.

**Warning:** graph theorists mean something different by "path" than do
homotopy theorists.  A "walk" in graph theory is a "path" in homotopy
theory.

Some definitions and theorems have inspiration from multigraph
counterparts in [Chou1994].

## Main definitions

* `simple_graph.walk`

## Tags
walks

-/

universes u

namespace simple_graph
variables {V : Type u} (G : simple_graph V)

/-- A walk is a sequence of adjacent vertices.  For vertices `u v : V`,
the type `walk u v` consists of all walks starting at `u` and ending at `v`.

We say that a walk *visits* the vertices it contains.  The set of vertices a
walk visits is `simple_graph.walk.support`. -/
inductive walk : V → V → Type u
| nil {u : V} : walk u u
| cons {u v w: V} (h : G.adj u v) (p : walk v w) : walk u w

attribute [refl] walk.nil

instance walk.inhabited (v : V) : inhabited (G.walk v v) := ⟨by refl⟩

namespace walk
variables {G}

/-- The length of a walk is the number of edges along it. -/
def length : Π {u v : V}, G.walk u v → ℕ
| _ _ nil := 0
| _ _ (cons _ q) := q.length.succ

/-- The concatenation of two compatible walks. -/
@[trans]
def concat : Π {u v w : V}, G.walk u v → G.walk v w → G.walk u w
| _ _ _ nil q := q
| _ _ _ (cons h p) q := cons h (p.concat q)

/-- The concatenation of the reverse of the first walk with the second walk. -/
protected def reverse_aux : Π {u v w : V}, G.walk u v → G.walk u w → G.walk v w
| _ _ _ nil q := q
| _ _ _ (cons h p) q := reverse_aux p (cons (G.sym h) q)

/-- Reverse the orientation of a walk. -/
@[symm]
def reverse {u v : V} (w : G.walk u v) : G.walk v u := w.reverse_aux nil

/-- Get the `n`th vertex from a path, where `n` is generally expected to be
between `0` and `p.length`, inclusive.
If `n` is greater than the length of the path, the result is the path's endpoint. -/
def get_vert : Π {u v : V} (p : G.walk u v) (n : ℕ), V
| u v nil _ := u
| u v (cons _ _) 0 := u
| u v (cons _ q) (n+1) := q.get_vert n

@[simp] lemma cons_concat {u v w x : V} (h : G.adj u v) (p : G.walk v w) (q : G.walk w x) :
  (cons h p).concat q = cons h (p.concat q) := rfl

@[simp] lemma cons_nil_concat {u v w : V} (h : G.adj u v) (p : G.walk v w) :
  (cons h nil).concat p = cons h p := rfl

@[simp] lemma concat_nil : Π {u v : V} (p : G.walk u v), p.concat nil = p
| _ _ nil := rfl
| _ _ (cons h p) := by rw [cons_concat, concat_nil]

@[simp] lemma nil_concat {u v : V} (p : G.walk u v) : nil.concat p = p := rfl

lemma concat_assoc : Π {u v w x : V} (p : G.walk u v) (q : G.walk v w) (r : G.walk w x),
  p.concat (q.concat r) = (p.concat q).concat r
| _ _ _ _ nil _ _ := rfl
| _ _ _ _ (cons h p') q r := by { dsimp only [concat], rw concat_assoc, }

@[simp] lemma nil_reverse {u : V} : (nil : G.walk u u).reverse = nil := rfl

lemma singleton_reverse {u v : V} (h : G.adj u v) :
  (cons h nil).reverse = cons (G.sym h) nil := rfl

@[simp]
protected lemma reverse_aux_eq_reverse_concat {u v w : V} (p : G.walk u v) (q : G.walk u w) :
  p.reverse_aux q = p.reverse.concat q :=
begin
  induction p generalizing q w,
  { refl },
  { dsimp [walk.reverse_aux, walk.reverse],
    repeat { rw p_ih },
    rw ←concat_assoc,
    refl, }
end

@[simp] lemma concat_reverse {u v w : V} (p : G.walk u v) (q : G.walk v w) :
  (p.concat q).reverse = q.reverse.concat p.reverse :=
begin
  induction p generalizing q w,
  { simp },
  { dsimp only [cons_concat, reverse, walk.reverse_aux],
    simp only [p_ih, walk.reverse_aux_eq_reverse_concat, concat_nil],
    rw concat_assoc, }
end

@[simp] lemma cons_reverse {u v w : V} (h : G.adj u v) (p : G.walk v w) :
  (cons h p).reverse = p.reverse.concat (cons (G.sym h) nil) :=
begin
  dsimp [reverse, walk.reverse_aux],
  simp only [walk.reverse_aux_eq_reverse_concat, concat_nil],
end

@[simp] lemma reverse_reverse : Π {u v : V} (p : G.walk u v), p.reverse.reverse = p
| _ _ nil := rfl
| _ _ (cons h p) := by simp [reverse_reverse]

@[simp] lemma nil_length {u : V} : (nil : G.walk u u).length = 0 := rfl

@[simp] lemma cons_length {u v w : V} (h : G.adj u v) (p : G.walk v w) :
  (cons h p).length = p.length + 1 := rfl

@[simp] lemma concat_length : Π {u v w : V} (p : G.walk u v) (q : G.walk v w),
  (p.concat q).length = p.length + q.length
| _ _ _ nil _ := by simp
| _ _ _ (cons _ p') _ := by simp [concat_length, add_left_comm, add_comm]

protected lemma reverse_aux_length {u v w : V} (p : G.walk u v) (q : G.walk u w) :
  (p.reverse_aux q).length = p.length + q.length :=
begin
  induction p,
  { simp [walk.reverse_aux], },
  { dunfold reverse_aux, rw p_ih, simp only [cons_length], ring, },
end

@[simp] lemma reverse_length {u v : V} (p : G.walk u v) : p.reverse.length = p.length :=
by convert walk.reverse_aux_length p nil

variables [decidable_eq V]

/-- The `support` of a walk is the multiset of vertices it visits. -/
def support : Π {u v : V}, G.walk u v → multiset V
| u v nil := {u}
| u v (cons h p) := u ::ₘ p.support

/-- The `edges` of a walk is the multiset of edges it visits. -/
def edges : Π {u v : V}, G.walk u v → multiset G.edge_set
| u v nil := ∅
| u v (cons h p) := ⟨⟦(u, _)⟧, h⟩ ::ₘ p.edges

lemma edge_vert_mem_support {t u v w : V} (ha : G.adj t u) (p : G.walk v w)
  (he : (⟨⟦(t, u)⟧, ha⟩ : G.edge_set) ∈ p.edges) :
  t ∈ p.support :=
begin
  induction p,
  { exfalso,
    simpa [edges] using he, },
  { simp only [support, multiset.mem_cons],
    simp only [edges, multiset.mem_cons, quotient.eq] at he,
    cases he,
    { cases he,
      { exact or.inl rfl, },
      { cases p_p; simp [support], }, },
    { exact or.inr (p_ih he), } },
end

/-- A *trail* is a walk with no repeating edges. -/
def is_trail {u v : V} (p : G.walk u v) : Prop := p.edges.nodup

/-- A *path* is a trail with no repeating vertices. -/
def is_path {u v : V} (p : G.walk u v) : Prop := p.is_trail ∧ p.support.nodup

/-- A *cycle* at `u : V` is a nonempty trail whose only repeating vertex is `u`. -/
def is_cycle {u : V} (p : G.walk u u) : Prop :=
p ≠ nil ∧ p.is_trail ∧ (p.support.erase u).nodup

lemma is_trail_of_path {u : V} {p : G.walk u u} (h : p.is_path) : p.is_trail := h.1

lemma is_trail_of_cycle {u : V} {p : G.walk u u} (h : p.is_cycle) : p.is_trail := h.2.1

lemma trail_count_le_one {u v : V} (p : G.walk u v) (h : p.is_trail) (e : G.edge_set) :
  p.edges.count e ≤ 1 :=
multiset.nodup_iff_count_le_one.mp h e

lemma trail_count_eq_one {u v : V} (p : G.walk u v) (h : p.is_trail) {e : G.edge_set} (he : e ∈ p.edges) :
  p.edges.count e = 1 :=
multiset.count_eq_one_of_mem h he

@[simp] lemma nil_is_trail {u : V} : (nil : G.walk u u).is_trail :=
by simp [is_trail, edges]

@[simp] lemma nil_is_path {u : V} : (nil : G.walk u u).is_path :=
by simp [is_path, support]

lemma is_trail_of_cons_is_trail {u v w : V} {h : G.adj u v} {p : G.walk v w} (h : (cons h p).is_trail) :
  p.is_trail :=
begin
  rw [is_trail, edges, multiset.nodup_cons] at h,
  exact h.2,
end

lemma is_path_of_cons_is_path {u v w : V} {h : G.adj u v} {p : G.walk v w} (h : (cons h p).is_path) :
  p.is_path :=
begin
  rw [is_path, support, multiset.nodup_cons] at h,
  exact ⟨is_trail_of_cons_is_trail h.1, h.2.2⟩,
end

lemma cons_is_trail_iff {u v w : V} (h : G.adj u v) (p : G.walk v w) :
  (cons h p).is_trail ↔ p.is_trail ∧ (⟨⟦(u, v)⟧, h⟩ : G.edge_set) ∉ p.edges :=
by simp only [is_trail, edges, and_comm, iff_self, multiset.nodup_cons]

lemma cons_is_path_iff {u v w : V} (h : G.adj u v) (p : G.walk v w) :
  (cons h p).is_path ↔ p.is_path ∧ u ∉ p.support :=
begin
  simp only [is_path, is_trail, edges, support, multiset.nodup_cons],
  split,
  { rintro ⟨⟨h1, hen⟩, hns, hsn⟩,
    exact ⟨⟨hen, hsn⟩, hns⟩, },
  { rintro ⟨⟨hen, hsn⟩, hns⟩,
    simp only [hen, hsn, hns, and_true, not_false_iff],
    intro he,
    apply hns,
    exact edge_vert_mem_support h p he, },
end

end walk

/-- Two vertices are *reachable* if there is a walk between them. -/
def reachable (u v : V) : Prop := nonempty (G.walk u v)

variables {G}

protected lemma reachable.elim {p : Prop} {u v : V}
  (h : G.reachable u v) (hp : G.walk u v → p) : p :=
nonempty.elim h hp

@[refl] lemma reachable.refl {u : V} : G.reachable u u := by { fsplit, refl }

@[symm] lemma reachable.symm {u v : V} (huv : G.reachable u v) : G.reachable v u :=
huv.elim (λ p, ⟨p.reverse⟩)

@[trans] lemma reachable.trans {u v w : V} (huv : G.reachable u v) (hvw : G.reachable v w) :
  G.reachable u w :=
huv.elim (λ puv, hvw.elim (λ pvw, ⟨puv.concat pvw⟩))

variables (G)

lemma reachable_is_equivalence : equivalence G.reachable :=
mk_equivalence _ (@reachable.refl _ G) (@reachable.symm _ G) (@reachable.trans _ G)

/-- The equivalence relation on vertices given by `simple_graph.reachable`. -/
def reachable_setoid : setoid V := setoid.mk _ G.reachable_is_equivalence

/-- The connected components of a graph are elements of the quotient of vertices by
the `simple_graph.reachable` relation. -/
def connected_component := quot G.reachable

/-- A graph is connected is every pair of vertices is reachable from one another. -/
def is_connected : Prop := ∀ (u v : V), G.reachable u v

/-- Gives the connected component containing a particular vertex. -/
def connected_component_of (v : V) : G.connected_component := quot.mk G.reachable v

instance connected_components.inhabited [inhabited V] : inhabited G.connected_component :=
⟨G.connected_component_of (default _)⟩

lemma connected_component.subsingleton_of_is_connected (h : G.is_connected) :
  subsingleton G.connected_component :=
⟨λ c d, quot.ind (λ v d, quot.ind (λ w, quot.sound (h v w)) d) c d⟩

section walk_to_path
variables [decidable_eq V]

/-- The type of paths between two vertices. -/
abbreviation path (u v : V) := {p : G.walk u v // p.is_path}

namespace walk
variables {G}

@[simp] lemma nil_support {u : V} : (nil : G.walk u u).support = {u} := rfl

@[simp] lemma cons_support {u v w : V} (h : G.adj u v) (p : G.walk v w) :
  (cons h p).support = u ::ₘ p.support := rfl

@[simp] lemma start_mem_support {u v : V} (p : G.walk u v) : u ∈ p.support :=
by cases p; simp [support]

@[simp] lemma end_mem_support : ∀ {u v : V} (p : G.walk u v), v ∈ p.support
| _ _ nil := by simp
| _ _ (cons h p) := by simp [p.end_mem_support]

@[simp]
lemma concat_support {u v w : V} (p : G.walk u v) (p' : G.walk v w) :
  (p.concat p').support = p.support + p'.support - {v} :=
begin
  induction p,
  { simp, },
  { simp only [cons_concat, cons_support, p_ih, multiset.singleton_eq_singleton,
      multiset.sub_zero, multiset.sub_cons, multiset.cons_add],
    rw [←multiset.singleton_add, ←multiset.singleton_add],
    have h₁ : p_w ∈ p'.support := p'.start_mem_support,
    have h₂ : p_w ∈ p_p.support + p'.support, simp [multiset.mem_add, h₁],
    rw multiset.erase_add_right_pos _ h₂, },
end

@[simp]
lemma reverse_support {u v : V} (p : G.walk u v) : p.reverse.support = p.support :=
begin
  induction p,
  { trivial, },
  { simp [p_ih], },
end

@[simp] lemma nil_edges {u : V} : (nil : G.walk u u).edges = ∅ := rfl

@[simp] lemma cons_edges {u v w : V} (h : G.adj u v) (p : G.walk v w) :
  (cons h p).edges = (⟨⟦(u, v)⟧, h⟩ : G.edge_set) ::ₘ p.edges := rfl

@[simp]
lemma concat_edges {u v w : V} (p : G.walk u v) (p' : G.walk v w) :
  (p.concat p').edges = p.edges + p'.edges :=
begin
  induction p,
  { simp, },
  { simp [p_ih], },
end

@[simp]
lemma reverse_edges {u v : V} (p : G.walk u v) : p.reverse.edges = p.edges :=
begin
  induction p,
  { trivial },
  { simp [p_ih, -quotient.eq],
    exact sym2.eq_swap, },
end

/-- Given a walk and a vertex in the walk's support, create a walk starting from that vertex.

The resulting walk begins at the last instance of that vertex in the original walk. -/
def subwalk_from : Π {u v w : V} (p : G.walk u v), w ∈ p.support → G.walk w v
| _ _ w nil h :=
  by { rw [nil_support, multiset.singleton_eq_singleton, multiset.mem_singleton] at h, subst w }
| u v w (@cons _ _ _ x _ ha p) hs := begin
  rw [cons_support, multiset.mem_cons] at hs,
  by_cases hw : w = u,
  { subst w,
    exact cons ha p, },
  { have : w ∈ p.support := hs.cases_on (λ hw', (hw hw').elim) id,
    exact p.subwalk_from this, },
end

/-- Given a walk, produces a walk with the same endpoints and no repeated vertices or edges. -/
def to_path_aux : Π {u v : V}, G.walk u v → G.walk u v
| u v nil := nil
| u v (@cons _ _ _ x _ ha p) :=
  let p' := p.to_path_aux
  in if hs : u ∈ p'.support
     then p'.subwalk_from hs
     else cons ha p'

lemma subwalk_from_is_path {u v w : V} (p : G.walk u v) (h : p.is_path) (hs : w ∈ p.support) :
  (p.subwalk_from hs).is_path :=
begin
  induction p,
  { rw [nil_support, multiset.singleton_eq_singleton, multiset.mem_singleton] at hs,
    subst w,
    exact h, },
  { rw [cons_support, multiset.mem_cons] at hs,
    simp only [subwalk_from],
    split_ifs with hw hw,
    { subst w,
      exact h, },
    { cases hs with hs₁ hs₂,
      { exact (hw hs₁).elim },
      { apply p_ih,
        exact is_path_of_cons_is_path h, }, }, },
end

lemma to_path_aux_is_path {u v : V} (p : G.walk u v) : p.to_path_aux.is_path :=
begin
  induction p,
  { simp [to_path_aux], },
  { simp [to_path_aux],
    split_ifs,
    { exact subwalk_from_is_path _ p_ih _, },
    { rw cons_is_path_iff,
      exact ⟨p_ih, h⟩, }, },
end

/-- Given a walk, produces a path with the same endpoints using `simple_graph.walk.to_path_aux`. -/
def to_path {u v : V} (p : G.walk u v) : G.path u v := ⟨p.to_path_aux, to_path_aux_is_path p⟩

@[simp] lemma path_is_path {u v : V} (p : G.path u v) : is_path (p : G.walk u v) := p.property

@[simp] lemma path_is_trail {u v : V} (p : G.path u v) : is_trail (p : G.walk u v) := p.property.1

lemma to_path_avoids.aux1 {u v w : V} (e : G.edge_set)
  (p : G.walk v w) (hp : e ∉ p.edges) (hu : u ∈ p.support) :
  e ∉ walk.edges (walk.subwalk_from p hu) :=
begin
  induction p,
  { simp [subwalk_from],
    generalize_proofs,
    subst u,
    exact hp, },
  { simp [subwalk_from],
    split_ifs,
    { subst u,
      simpa using hp, },
    { apply p_ih,
      simp at hp,
      push_neg at hp,
      exact hp.2, }, },
end

lemma to_path_avoids {v w : V} (e : G.edge_set)
  (p : G.walk v w) (hp : e ∉ p.edges) :
  e ∉ walk.edges (p.to_path : G.walk v w) :=
begin
  simp only [to_path, subtype.coe_mk],
  induction p,
  { simp [to_path_aux], },
  { simp [to_path_aux],
    split_ifs,
    { apply to_path_avoids.aux1,
      apply p_ih,
      simp at hp,
      push_neg at hp,
      exact hp.2, },
    { simp [to_path_aux],
      push_neg,
      simp at hp,
      push_neg at hp,
      use hp.1,
      apply p_ih,
      exact hp.2, }, },
end


lemma reverse_trail {u v : V} (p : G.walk u v) (h : p.is_trail) : p.reverse.is_trail :=
by simpa [is_trail] using h

@[simp] lemma reverse_trail_iff {u v : V} (p : G.walk u v) : p.reverse.is_trail ↔ p.is_trail :=
begin
  split,
  { intro h,
    convert reverse_trail _ h,
    rw reverse_reverse, },
  { exact reverse_trail p, },
end

lemma is_trail_of_concat_left {u v w : V} (p : G.walk u v) (q : G.walk v w) (h : (p.concat q).is_trail) :
  p.is_trail :=
begin
  induction p,
  { simp, },
  { simp [cons_is_trail_iff],
    simp [cons_is_trail_iff] at h,
    split,
    apply p_ih _ h.1,
    intro h',
    apply h.2,
    exact or.inl h', },
end

lemma is_trail_of_concat_right {u v w : V} (p : G.walk u v) (q : G.walk v w) (h : (p.concat q).is_trail) :
  q.is_trail :=
begin
  rw [←reverse_trail_iff, concat_reverse] at h,
  rw ←reverse_trail_iff,
  exact is_trail_of_concat_left _ _ h,
end

lemma reverse_path {u v : V} (p : G.walk u v) (h : p.is_path) : p.reverse.is_path :=
by simpa [is_path] using h

@[simp] lemma reverse_path_iff {u v : V} (p : G.walk u v) : p.reverse.is_path ↔ p.is_path :=
begin
  split,
  { intro h,
    convert reverse_path _ h,
    rw reverse_reverse, },
  { exact reverse_path p, },
end

def split_at_vertex_fst : Π {v w : V} (p : G.walk v w) (u : V) (h : u ∈ p.support), G.walk v u
| v w nil u h := begin
  simp only [multiset.singleton_eq_singleton, nil_support, multiset.mem_singleton] at h,
  subst h,
end
| v w (cons r p) u h :=
  if hx : v = u then
    by subst u
  else
  begin
    simp only [multiset.mem_cons, cons_support] at h,
    have : u ∈ p.support := h.cases_on (λ h', (hx h'.symm).elim) id,
    exact cons r (split_at_vertex_fst p _ this),
  end

def split_at_vertex_snd : Π {v w : V} (p : G.walk v w) (u : V) (h : u ∈ p.support), G.walk u w
| v w nil u h := begin
  simp only [multiset.singleton_eq_singleton, nil_support, multiset.mem_singleton] at h,
  subst h,
end
| v w (cons r p) u h :=
  if hx : v = u then
    by { subst u, exact cons r p }
  else
  begin
    simp only [multiset.mem_cons, cons_support] at h,
    have : u ∈ p.support := h.cases_on (λ h', (hx h'.symm).elim) id,
    exact split_at_vertex_snd p _ this,
  end

@[simp]
lemma split_at_vertex_spec {u v w : V} (p : G.walk v w) (h : u ∈ p.support) :
  (p.split_at_vertex_fst u h).concat (p.split_at_vertex_snd u h) = p :=
begin
  induction p,
  { simp only [split_at_vertex_fst, split_at_vertex_snd],
    generalize_proofs,
    subst u,
    refl, },
  { simp at h,
    cases h,
    { subst u,
      simp [split_at_vertex_fst, split_at_vertex_snd], },
    { by_cases hvu : p_u = u,
      subst p_u,
      simp [split_at_vertex_fst, split_at_vertex_snd],
      simp [split_at_vertex_fst, split_at_vertex_snd, hvu, p_ih], }, },
end

lemma split_at_vertex_support {u v w : V} (p : G.walk v w) (h : u ∈ p.support) :
  (p.split_at_vertex_fst u h).support + (p.split_at_vertex_snd u h).support
    = p.support + {u} :=
begin
  induction p,
  { simp [split_at_vertex_fst, split_at_vertex_snd],
    generalize_proofs,
    subst p,
    refl, },
  { simp [split_at_vertex_fst, split_at_vertex_snd],
    split_ifs,
    { subst p_u,
      simp, },
    { simp [p_ih],
      rw multiset.cons_swap, }, },
end

lemma split_at_vertex_edges {u v w : V} (p : G.walk v w) (h : u ∈ p.support) :
  (p.split_at_vertex_fst u h).edges + (p.split_at_vertex_snd u h).edges
    = p.edges :=
begin
  induction p,
  { simp [split_at_vertex_fst, split_at_vertex_snd],
    generalize_proofs,
    subst p,
    simp, },
  { simp [split_at_vertex_fst, split_at_vertex_snd],
    split_ifs,
    { subst p_u,
      simp, },
    { simp [p_ih], }, },
end

lemma split_at_vertex_fst_is_trail {u v w : V} (p : G.walk v w) (hc : p.is_trail) (h : u ∈ p.support) :
  (p.split_at_vertex_fst u h).is_trail :=
begin
  induction p,
  { simp [split_at_vertex_fst],
    generalize_proofs,
    subst p,
    exact hc, },
  { simp [split_at_vertex_fst],
    split_ifs,
    { subst u,
      simp, },
    { simp [cons_is_trail_iff] at hc ⊢,
      simp at h,
      cases h,
      { exact (h_1 h_2.symm).elim, },
      { cases hc with hc1 hc2,
        simp [p_ih hc1 h_2],
        rw ←split_at_vertex_edges _ h_2 at hc2,
        intro h,
        apply hc2,
        rw multiset.mem_add,
        exact or.inl h, }, }, },
end

lemma split_at_vertex_snd_is_trail {u v w : V} (p : G.walk v w) (hc : p.is_trail) (h : u ∈ p.support) :
  (p.split_at_vertex_snd u h).is_trail :=
begin
  induction p,
  { simp [split_at_vertex_snd],
    generalize_proofs,
    subst p,
    exact hc, },
  { simp [split_at_vertex_snd],
    split_ifs,
    { subst u,
      simp [hc], },
    { simp [cons_is_trail_iff] at hc ⊢,
      simp at h,
      cases h,
      { exact (h_1 h_2.symm).elim, },
      { cases hc with hc1 hc2,
        simp [p_ih hc1 h_2], }, }, },
end

/-- Rotate a loop walk such that it is centered at the given vertex. -/
def rotate {u v : V} (c : G.walk v v) (h : u ∈ c.support) : G.walk u u :=
(c.split_at_vertex_snd u h).concat (c.split_at_vertex_fst u h)

@[simp]
lemma rotate_support {u v : V} (c : G.walk v v) (h : u ∈ c.support) :
  (c.rotate h).support = c.support + {u} - {v} :=
begin
  simp only [rotate, multiset.singleton_eq_singleton, add_zero, multiset.sub_zero,
    concat_support, multiset.sub_cons, multiset.add_cons],
  rw [add_comm, split_at_vertex_support, add_comm],
  refl,
end

@[simp]
lemma rotate_edges {u v : V} (c : G.walk v v) (h : u ∈ c.support) :
  (c.rotate h).edges = c.edges :=
begin
  simp [rotate, concat_edges],
  rw [add_comm, split_at_vertex_edges],
end

lemma rotate_trail {u v : V} (c : G.walk v v) (hc : c.is_trail) (h : u ∈ c.support) :
  (c.rotate h).is_trail :=
by simpa [is_trail] using hc

lemma rotate_cycle {u v : V} (c : G.walk v v) (hc : c.is_cycle) (h : u ∈ c.support) :
  (c.rotate h).is_cycle :=
begin
  split,
  { cases c,
    { exfalso,
      simpa [is_cycle] using hc, },
    { simp [rotate, split_at_vertex_snd, split_at_vertex_fst],
      split_ifs,
      { subst u,
        simp, },
      { intro hcon,
        have hcon' := congr_arg walk.length hcon,
        simpa using hcon', }, }, },
  split,
  { apply rotate_trail,
    exact is_trail_of_cycle hc, },
  { simp,
    by_cases huv : u = v; simp [huv, hc.2.2], },
end

/-- Get the vertex immediately after the split point, where if the very last vertex was the split
point we use the first vertex (wrapping around). -/
def vertex_after_split {u v w : V} (c : G.walk v w) (h : u ∈ c.support) : V :=
match v, w, c.split_at_vertex_snd u h with
| _, _, nil := v
| _, _, (@cons _ _ _ x _ r p) := x
end

end walk

namespace path
variables {G}

/-- The empty path at a vertex. -/
@[refl] def nil {u : V} : G.path u u := ⟨walk.nil, by simp⟩

/-- The length-1 path given by a pair of adjacent vertices. -/
def singleton {u v : V} (h : G.adj u v) : G.path u v :=
⟨walk.cons h walk.nil, by simp [walk.is_path, walk.is_trail, walk.edges, G.ne_of_adj h]⟩

@[symm] def reverse {u v : V} (p : G.path u v) : G.path v u :=
⟨walk.reverse p, walk.reverse_path p p.property⟩

end path

section map
variables {G} {V' : Type*} {G' : simple_graph V'} [decidable_eq V']

/-- Given a graph homomorphism, map walks to walks. -/
def walk.map (f : G →g G') : Π {u v : V}, G.walk u v → G'.walk (f u) (f v)
| _ _ walk.nil := walk.nil
| _ _ (walk.cons h p) := walk.cons (f.map_adj h) (walk.map p)

lemma walk.map_concat (f : G →g G') {u v w : V} (p : G.walk u v) (q : G.walk v w) :
  (p.concat q).map f = (p.map f).concat (q.map f) :=
begin
  induction p,
  { refl, },
  { simp [walk.map, p_ih], },
end

@[simp]
lemma walk.map_support_eq (f : G →g G') {u v : V} (p : G.walk u v) :
  (p.map f).support = p.support.map f :=
begin
  induction p,
  { refl, },
  { simp [walk.map, p_ih], },
end

@[simp]
lemma walk.map_edges_eq (f : G →g G') {u v : V} (p : G.walk u v) :
  (p.map f).edges = p.edges.map f.map_edge_set :=
begin
  induction p,
  { refl, },
  { simp only [walk.map, walk.edges, p_ih, multiset.map_cons, multiset.cons_inj_left],
    refl, },
end

/-- Given an injective graph homomorphism, map paths to paths. -/
def path.map (f : G →g G') (hinj : function.injective f) {u v : V} (p : G.path u v) :
  G'.path (f u) (f v) :=
⟨walk.map f p, begin
  cases p with p hp,
  induction p,
  { simp [walk.map], },
  { rw walk.cons_is_path_iff at hp,
    specialize p_ih hp.1,
    rw subtype.coe_mk at p_ih,
    simp only [walk.map, walk.cons_is_path_iff, p_ih, not_exists, true_and,
      walk.map_support_eq, not_and, multiset.mem_map, subtype.coe_mk],
    intros x hx hf,
    have := hinj hf,
    subst x,
    exact hp.2 hx, },
end⟩

end map

end walk_to_path

namespace walk
variables {G}

/-- Whether or not the path `p` is a prefix of the path `q`. -/
def prefix_of [decidable_eq V] : Π {u v w : V} (p : G.walk u v) (q : G.walk u w), Prop
| u v w nil _ := true
| u v w (cons _ _) nil := false
| u v w (@cons _ _ _ x _ r p) (@cons _ _ _ y _ s q) :=
  if h : x = y
  then by { subst y, exact prefix_of p q }
  else false

end walk

section
variables [decidable_eq V]

/-- A graph is *acyclic* (or a *forest*) if it has no cycles.

A characterization: `simple_graph.is_acyclic_iff`.-/
def is_acyclic : Prop := ∀ (v : V) (c : G.walk v v), ¬c.is_cycle

/-- A *tree* is a connected acyclic graph. -/
def is_tree : Prop := G.is_connected ∧ G.is_acyclic

namespace subgraph
variables {G} (H : subgraph G)

/-- A subgraph is connected if it is connected as a simple graph. -/
abbreviation is_connected : Prop := H.coe.is_connected

/-- An edge of a subgraph is a bridge edge if, after removing it, its incident vertices
are no longer reachable. -/
def is_bridge {v w : V} (h : H.adj v w) : Prop :=
¬(H.delete_edges {⟦(v, w)⟧}).spanning_coe.reachable v w

end subgraph

/-- An edge of a graph is a bridge if, after removing it, its incident vertices
are no longer reachable.

Characterizations of bridges:
`simple_graph.is_bridge_iff_walks_contain`
`is_bridge_iff_no_cycle_contains` -/
def is_bridge {v w : V} (h : G.adj v w) : Prop := (⊤ : G.subgraph).is_bridge h

/-- Given a walk that avoids an edge, create a walk in the subgraph with that deleted. -/
def walk_of_avoiding_walk {v w : V} (e : G.edge_set)
  (p : G.walk v w) (hp : e ∉ p.edges) :
  ((⊤ : G.subgraph).delete_edges {e}).spanning_coe.walk v w :=
begin
  induction p,
  { refl, },
  { cases e with e he,
    simp only [walk.edges, multiset.mem_cons, subtype.mk_eq_mk] at hp,
    push_neg at hp,
    apply walk.cons _ (p_ih _),
    use p_h,
    simp only [set.mem_singleton_iff, subtype.coe_mk],
    exact hp.1.symm,
    exact hp.2, },
end

lemma is_bridge_iff_walks_contain {v w : V} (h : G.adj v w) :
  G.is_bridge h ↔ ∀ (p : G.walk v w), (⟨⟦(v, w)⟧, h⟩ : G.edge_set) ∈ p.edges :=
begin
  split,
  { intros hb p,
    by_contra he,
    apply hb,
    exact ⟨walk_of_avoiding_walk _ _ p he⟩, },
  { intro hpe,
    rintro ⟨p'⟩,
    specialize hpe (p'.map (subgraph.map_spanning_top _)),
    simp only [set_coe.exists, walk.map_edges_eq, multiset.mem_map] at hpe,
    obtain ⟨z, zmem, he, hd⟩ := hpe,
    simp only [subgraph.map_spanning_top, hom.map_edge_set, rel_hom.coe_fn_mk,
      id.def, subtype.coe_mk, sym2.map_id] at hd,
    subst z,
    simpa [subgraph.spanning_coe] using zmem, },
end

lemma is_bridge_iff_no_cycle_contains.aux1
  {u v w : V}
  (h : G.adj v w)
  (c : G.walk u u)
  (he : (⟨⟦(v, w)⟧, h⟩ : G.edge_set) ∈ c.edges)
  (hb : ∀ (p : G.walk v w), (⟨⟦(v, w)⟧, h⟩ : G.edge_set) ∈ p.edges)
  (hc : c.is_trail)
  (hv : v ∈ c.support)
  (hw : w ∈ (c.split_at_vertex_fst v hv).support) :
  false :=
begin
  let p1 := c.split_at_vertex_fst v hv,
  let p2 := c.split_at_vertex_snd v hv,
  let p11 := p1.split_at_vertex_fst w hw,
  let p12 := p1.split_at_vertex_snd w hw,
  have : (p11.concat p12).concat p2 = c := by simp,
  let q := p2.concat p11,
  have hbq := hb (p2.concat p11),
  have hpq' := hb p12.reverse,
  have this' : multiset.count (⟨⟦(v, w)⟧, h⟩ : G.edge_set) (p2.edges + p11.edges + p12.edges) = 1,
  { convert_to multiset.count (⟨⟦(v, w)⟧, h⟩ : G.edge_set) c.edges = _,
    congr,
    rw ←this,
    simp_rw [walk.concat_edges],
    rw [add_assoc p11.edges, add_comm p12.edges, ←add_assoc],
    congr' 1,
    rw add_comm,
    apply c.trail_count_eq_one hc he, },
  have this'' : multiset.count (⟨⟦(v, w)⟧, h⟩ : G.edge_set) (p2.concat p11).edges + multiset.count (⟨⟦(v, w)⟧, h⟩ : G.edge_set) p12.edges = 1,
  { convert this',
    rw walk.concat_edges,
    symmetry,
    apply multiset.count_add, },
  have hA : multiset.count (⟨⟦(v, w)⟧, h⟩ : G.edge_set) (p2.concat p11).edges = 1,
  { apply walk.trail_count_eq_one,
    have hr := c.rotate_trail hc hv,
    have : c.rotate hv = (p2.concat p11).concat p12,
    { simp [walk.rotate],
      rw ←walk.concat_assoc,
      congr' 1,
      simp, },
    rw this at hr,
    apply walk.is_trail_of_concat_left _ _ hr,
    assumption, },
  have hB : multiset.count (⟨⟦(v, w)⟧, h⟩ : G.edge_set) p12.edges = 1,
  { apply walk.trail_count_eq_one,
    apply walk.is_trail_of_concat_right,
    apply walk.is_trail_of_concat_left,
    rw this,
    exact hc,
    simpa using hpq', },
  rw [hA, hB] at this'',
  simpa using this'',
end

lemma mem_concat_support {u v w : V} (p : G.walk u v) (p' : G.walk v u) (h : w ∈ p.support) :
  w ∈ (p.concat p').support :=
begin
  rw [walk.concat_support, ←multiset.count_pos, multiset.count_sub, multiset.count_add],
  by_cases hwv : w = v,
  { subst w,
    have hp : 0 < multiset.count v p.support := by simp [multiset.count_pos],
    have hp' : 0 < multiset.count v p'.support := by simp [multiset.count_pos],
    simp,
    omega, },
  { simp [hwv],
    have hp : 0 < multiset.count w p.support := by simp [multiset.count_pos, h],
    omega, },
end

lemma is_bridge_iff_no_cycle_contains {v w : V} (h : G.adj v w) :
  G.is_bridge h ↔ ∀ {u : V} (p : G.walk u u), p.is_cycle → (⟨⟦(v, w)⟧, h⟩ : G.edge_set) ∉ p.edges :=
begin
  split,
  { intros hb u c hc he,
    rw is_bridge_iff_walks_contain at hb,
    simp [walk.is_cycle] at hc,
    have hv : v ∈ c.support := walk.edge_vert_mem_support h c he,
    have hh : (⟨⟦(w, v)⟧, G.sym h⟩ : G.edge_set) = ⟨⟦(v, w)⟧, h⟩ := by simp [sym2.eq_swap],
    have hwc : w ∈ c.support := walk.edge_vert_mem_support (G.sym h) c (by { rw hh, exact he, }),
    let p1 := c.split_at_vertex_fst v hv,
    let p2 := c.split_at_vertex_snd v hv,
    by_cases hw : w ∈ p1.support,
    { exact is_bridge_iff_no_cycle_contains.aux1 G h c he hb hc.2.1 hv hw, },
    { have hw' : w ∈ p2.support,
      { have : c = p1.concat p2 := by simp,
        rw [this, walk.concat_support] at hwc,
        simp at hwc,
        rw multiset.mem_erase_of_ne at hwc,
        rw multiset.mem_add at hwc,
        cases hwc,
        { exact (hw hwc).elim },
        { exact hwc },
        exact (G.ne_of_adj h).symm, },
      apply is_bridge_iff_no_cycle_contains.aux1 G (G.sym h) (p2.concat p1)
        (by { rw [walk.concat_edges, add_comm, ←walk.concat_edges, walk.split_at_vertex_spec], rw hh, exact he })
        _ (walk.rotate_trail _ hc.2.1 hv),
      swap,
      { apply mem_concat_support,
        exact hw', },
      { simp, },
      { intro p,
        specialize hb p.reverse,
        rw hh,
        simpa using hb, }, }, },
  { intro hc,
    rw is_bridge_iff_walks_contain,
    intro p,
    by_contra hne,
    specialize hc (walk.cons (G.sym h) p.to_path) _,
    { simp [walk.is_cycle, walk.cons_is_trail_iff],
      split,
      { apply walk.to_path_avoids,
        convert hne using 3,
        rw sym2.eq_swap, },
      { exact p.to_path.property.2, }, },
    simp [-quotient.eq] at hc,
    push_neg at hc,
    apply hc.1,
    rw sym2.eq_swap, },
end

lemma is_acyclic_iff_all_bridges : G.is_acyclic ↔ ∀ {v w : V} (h : G.adj v w), G.is_bridge h :=
begin
  split,
  { intros ha v w hvw,
    rw is_bridge_iff_no_cycle_contains,
    intros u p hp,
    exact (ha _ p hp).elim, },
  { intros hb v p hp,
    cases p,
    { simpa [walk.is_cycle] using hp, },
    { specialize hb p_h,
      rw is_bridge_iff_no_cycle_contains at hb,
      apply hb _ hp,
      simp, }, },
end

lemma unique_path_if_is_acyclic (h : G.is_acyclic) {v w : V} (p q : G.path v w) : p = q :=
begin
  obtain ⟨p, hp⟩ := p,
  obtain ⟨q, hq⟩ := q,
  simp only,
  induction p generalizing q,
  { by_cases hnq : q = walk.nil,
    { subst q, },
    { exfalso,
      cases q,
      exact (hnq rfl).elim,
      simpa [walk.is_path] using hq, }, },
  { rw is_acyclic_iff_all_bridges at h,
    specialize h p_h,
    rw is_bridge_iff_walks_contain at h,
    specialize h (q.concat p_p.reverse),
    simp at h,
    cases h,
    { cases q,
      { exfalso,
        simpa [walk.is_path] using hp, },
      { rw walk.cons_is_path_iff at hp hq,
        simp [walk.edges] at h,
        cases h,
        { cases h,
          { congr,
            exact p_ih hp.1 _ hq.1, },
          { exfalso,
            apply hq.2,
            simp, }, },
        { exfalso,
          apply hq.2 (walk.edge_vert_mem_support _ _ h), }, }, },
    { rw walk.cons_is_path_iff at hp,
      exact (hp.2 (walk.edge_vert_mem_support _ _ h)).elim, }, },
end

lemma is_acyclic_if_unique_path (h : ∀ (v w : V) (p q : G.path v w), p = q) : G.is_acyclic :=
begin
  intros v c hc,
  simp [walk.is_cycle] at hc,
  cases c,
  { exact (hc.1 rfl).elim },
  { simp [walk.cons_is_trail_iff] at hc,
    have hp : c_p.is_path,
    { cases_matching* [_ ∧ _],
      simp only [walk.is_path],
      split; assumption, },
    specialize h _ _ ⟨c_p, hp⟩ (path.singleton (G.sym c_h)),
    simp [path.singleton] at h,
    subst c_p,
    simpa [walk.edges, -quotient.eq, sym2.eq_swap] using hc, },
end

lemma is_acyclic_iff : G.is_acyclic ↔ ∀ (v w : V) (p q : G.path v w), p = q :=
begin
  split,
  { apply unique_path_if_is_acyclic, },
  { apply is_acyclic_if_unique_path, },
end

lemma is_tree_iff : G.is_tree ↔ ∀ (v w : V), ∃!(p : G.walk v w), p.is_path :=
begin
  simp only [is_tree, is_acyclic_iff],
  split,
  { rintro ⟨hc, hu⟩ v w,
    let q := (hc v w).some.to_path,
    use q,
    simp only [true_and, walk.path_is_path],
    intros p hp,
    specialize hu v w ⟨p, hp⟩ q,
    rw ←hu,
    refl, },
  { intro h,
    split,
    { intros v w,
      obtain ⟨p, hp⟩ := h v w,
      use p, },
    { rintros v w ⟨p, hp⟩ ⟨q, hq⟩,
      simp only,
      exact unique_of_exists_unique (h v w) hp hq, }, },
end

/-- Get the unique path between two vertices in the tree. -/
noncomputable abbreviation tree_path (h : G.is_tree) (v w : V) : G.path v w :=
⟨((G.is_tree_iff.mp h) v w).some, ((G.is_tree_iff.mp h) v w).some_spec.1⟩

lemma tree_path_spec {h : G.is_tree} {v w : V} (p : G.path v w) : p = G.tree_path h v w :=
begin
  cases p,
  have := ((G.is_tree_iff.mp h) v w).some_spec,
  simp only [this.2 p_val p_property],
end

/-- The tree metric, which is the length of the path between any two vertices.

Fixing a vertex as the root, then `G.tree_dist h root` gives the depth of each node with
respect to the root. -/
noncomputable def tree_dist (h : G.is_tree) (v w : V) : ℕ :=
walk.length (G.tree_path h v w : G.walk v w)

variables {G} [decidable_eq V]

/-- Given a tree and a choice of root, then we can tell whether a given path
from `v` is a *rootward* path based on whether or not it is a prefix of the unique
path from `v` to the root. This gives paths a canonical orientation in a rooted tree. -/
def path.is_rootward (h : G.is_tree) (root : V) {v w : V} (p : G.path v w) : Prop :=
walk.prefix_of (p : G.walk v w) (G.tree_path h v root : G.walk v root)

lemma path.is_rootward_or_reverse (h : G.is_tree) (root : V) {v w : V} (p : G.path v w) :
  p.is_rootward h root ∨ p.reverse.is_rootward h root :=
begin
  sorry,
end

end

end simple_graph
