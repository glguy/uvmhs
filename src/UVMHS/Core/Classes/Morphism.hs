module UVMHS.Core.Classes.Morphism where

import UVMHS.Core.Init

infixr 1 →⁻,→⁼,⇄,⇄⁻,⇄⁼
infixl 7 ⊚

type (m ∷ ★ → ★) →⁻ (n ∷ ★ → ★) = ∀ a. m a → n a
type (t ∷ (★ → ★) → ★ → ★) →⁼ (u ∷ (★ → ★) → ★ → ★) = ∀ m. t m →⁻ u m

class a ⇄ b | a → b where
  isoto ∷ a → b
  isofr ∷ b → a
data Iso a b = Iso
  { ito ∷ a → b
  , ifr ∷ b → a
  }

toiso ∷ (a ⇄ b) ⇒ Iso a b
toiso = Iso isoto isofr

friso ∷ (a ⇄ b) ⇒ Iso b a
friso = Iso isofr isoto

class t ⇄⁻ u | t → u where
  isoto2 ∷ t →⁻ u
  isofr2 ∷ u →⁻ t
data Iso2 t u = Iso2
  { ito2 ∷ t →⁻ u
  , ifr2 ∷ u →⁻ t
  }

toiso2 ∷ (t ⇄⁻ u) ⇒ Iso2 t u
toiso2 = Iso2 isoto2 isofr2

friso2 ∷ (t ⇄⁻ u) ⇒ Iso2 u t
friso2 = Iso2 isofr2 isoto2

class v ⇄⁼ w | v → w where
  isoto3 ∷ v →⁼ w
  isofr3 ∷ w →⁼ v
data Iso3 v w = Iso3
  { ito3 ∷ v →⁼ w
  , ifr3 ∷ w →⁼ v
  }

toiso3 ∷ (v ⇄⁼ w) ⇒ Iso3 v w
toiso3 = Iso3 isoto3 isofr3

friso3 ∷ (v ⇄⁼ w) ⇒ Iso3 w v
friso3 = Iso3 isofr3 isoto3

class Reflexive t where refl ∷ t a a
class Transitive t where (⊚) ∷ t b c → t a b → t a c
class (Reflexive t,Transitive t) ⇒ Category t
class Symmetric t where {sym ∷ t a b → t b a}

instance Reflexive (→) where
  refl = id
instance Transitive (→) where
  (⊚) = (∘)
instance Category (→)

instance Reflexive Iso where
  refl = Iso id id
instance Transitive Iso where
  Iso gto gfrom ⊚ Iso fto ffrom = Iso (gto ∘ fto) (ffrom ∘ gfrom)
instance Symmetric Iso where
  sym (Iso to from) = Iso from to
instance Category Iso
instance Reflexive Iso2 where
  refl = Iso2 id id
instance Transitive Iso2 where
  Iso2 gto gfrom ⊚ Iso2 fto ffrom = Iso2 (gto ∘ fto) (ffrom ∘ gfrom)
instance Symmetric Iso2 where
  sym (Iso2 to from) = Iso2 from to
instance Category Iso2
instance Reflexive Iso3 where
  refl = Iso3 id id
instance Transitive Iso3 where
  Iso3 gto gfrom ⊚ Iso3 fto ffrom = Iso3 (gto ∘ fto) (ffrom ∘ gfrom)
instance Symmetric Iso3 where
  sym (Iso3 to from) = Iso3 from to
instance Category Iso3
