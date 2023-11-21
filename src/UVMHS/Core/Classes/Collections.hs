module UVMHS.Core.Classes.Collections where

import UVMHS.Core.Init

infixl 7 ⋕?,⋕,⋕!

class All a where all ∷ 𝐼 a

-- aggregate size = sum of sizes of each element
class ASized a where asize ∷ a → ℕ64

-- count size = number of elements
class CSized a where csize ∷ a → ℕ64

class Single a t | t → a where single ∷ a → t
class Lookup k v t | t → k,t → v where (⋕?) ∷ t → k → 𝑂 v
class Access k v t | t → k,t → v where (⋕) ∷ t → k → v

class ToIter a t | t → a where iter ∷ t → 𝐼 a

lup ∷ (Lookup k v t) ⇒ k → t → 𝑂 v
lup = flip (⋕?)

(⋕!) ∷ (Lookup k v t,STACK) ⇒ t → k → v
kvs ⋕! k = case kvs ⋕? k of
  Some v → v
  None → error "failed ⋕! lookup"

lupΩ ∷ (Lookup k v t) ⇒ k → t → v
lupΩ = flip (⋕!)

