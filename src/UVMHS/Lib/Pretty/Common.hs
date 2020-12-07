module UVMHS.Lib.Pretty.Common where

import UVMHS.Core

import UVMHS.Lib.ATree
import UVMHS.Lib.Sep

import UVMHS.Lib.Pretty.Annotation
import UVMHS.Lib.Pretty.Shape

-----------------
-- Input Chunk --
-----------------
  
data ChunkI =
  --          length
  --          ⌄⌄⌄
    RawChunkI ℕ64 𝕊
  --              ^
  --              string with no newlines
  | NewlineChunkI ℕ64
  --              ^^^
  --              indent after newline
  deriving (Eq,Ord,Show)

rawChunksI ∷ 𝕊 → ChunkI
rawChunksI s = RawChunkI (𝕟64 $ length𝕊 s) s
 
splitChunksI ∷ 𝕊 → 𝐼 ChunkI
splitChunksI s = 
  materialize 
  $ filter (\ c → c ≢ RawChunkI (𝕟64 0) "") 
  $ inbetween (NewlineChunkI zero) 
  $ map rawChunksI $ splitOn𝕊 "\n" s

shapeIChunk ∷ ChunkI → Shape
shapeIChunk = \case
  RawChunkI l _ → SingleLine l
  NewlineChunkI n → newlineShape ⧺ SingleLine n
 
extendNewlinesIChunk ∷ ℕ64 → ChunkI → ChunkI
extendNewlinesIChunk n = \case
  RawChunkI l s → RawChunkI l s
  NewlineChunkI l → NewlineChunkI $ n + l

------------------
-- Output Chunk --
------------------

data ChunkO =
  --          length
  --          ⌄⌄⌄
    RawChunkO ℕ64 𝕊
  --              ^
  --              string with no newlines
  | PaddingChunkO ℕ64
  --              ^^^
  --              padding length
  deriving (Eq,Ord,Show)

instance Sized ChunkO where
  size (RawChunkO n _) = n
  size (PaddingChunkO n) = n

shapeOChunk ∷ ChunkO → Shape
shapeOChunk = \case
  RawChunkO l _ → SingleLine l
  PaddingChunkO n → SingleLine n

--------------------
-- Document Trees --
--------------------

type TreeI = 𝑉𝐴 Annotation (𝐼 ChunkI)

--                              stuff 
--                              between 
--                              newlines
--                              ⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄
type TreeO = 𝑉𝐴 Formats (Sep () (𝐼A ChunkO))
--                           ^^
--                           newline indicator

chunkIO ∷ ChunkO → ChunkI
chunkIO = \case
  RawChunkO n s → RawChunkI n s
  PaddingChunkO n → RawChunkI n $ string $ repeat n ' '

treeIO ∷ TreeO → TreeI
treeIO = map𝑉𝐴 formatAnnotation $ concat ∘ iter ∘ mapSep (const $ single @ _ @ (𝐼 _) $ NewlineChunkI zero) (map chunkIO ∘ iter)

--------------
-- SummaryI --
--------------

data SummaryI = SummaryI
  { summaryIShape ∷ ShapeA
  , summaryIContents ∷ TreeI
  }
makeLenses ''SummaryI

summaryIAlignedL ∷ SummaryI ⟢ 𝔹
summaryIAlignedL = shapeIAlignedL ⊚ summaryIShapeL

instance Null SummaryI where null = SummaryI null null
instance Append SummaryI where
  SummaryI sh₁ cs₁ ⧺ SummaryI sh₂ cs₂ = 
    let cs₂' =
          if shape singleLineL (shapeIShape sh₂) ⩔ not (shapeIAligned sh₂)
          then cs₂
          else mappOn cs₂ $ extendNewlinesIChunk $ shapeLastLength $ shapeIShape sh₁
    in SummaryI (sh₁ ⧺ sh₂) $ cs₁ ⧺ cs₂'
instance Monoid SummaryI

summaryChunksI ∷ 𝐼 ChunkI → SummaryI
summaryChunksI chunks =
  let sh = concat $ map shapeIChunk $ iter chunks
  in SummaryI (ShapeA False sh) $ element𝑉𝐴 chunks

annotateSummaryI ∷ Annotation → SummaryI → SummaryI
annotateSummaryI a (SummaryI sh cs) = SummaryI sh $ annotate𝑉𝐴 a cs

--------------
-- SummaryO --
--------------

data SummaryO = SummaryO
  { summaryOShape ∷ Shape
  , summaryOContents ∷ TreeO
  }
makeLenses ''SummaryO

instance Null SummaryO where null = SummaryO null null
instance Append SummaryO where SummaryO sh₁ cs₁ ⧺ SummaryO sh₂ cs₂ = SummaryO (sh₁ ⧺ sh₂) $ cs₁ ⧺ cs₂
instance Monoid SummaryO

summaryChunksO ∷ Sep () (𝐼A ChunkO) → SummaryO
summaryChunksO chunks =
  let sh = concat $ mapSep (const newlineShape) (concat ∘ map shapeOChunk ∘ iter) chunks
  in SummaryO sh $ element𝑉𝐴 chunks

annotateSummaryO ∷ Formats → SummaryO → SummaryO
annotateSummaryO fm (SummaryO sh cs) = SummaryO sh $ annotate𝑉𝐴 fm cs

---------------
-- Alignment --
---------------

data HAlign = LH | CH | RH
data VAlign = TV | CV | BV

hvalign ∷ HAlign → VAlign → ℕ64 → ℕ64 → SummaryO → SummaryO
hvalign ha va m n (SummaryO sh cs) =
  let w   = shapeWidth sh
      wd  = (w ⊔ m) - w
      wdm = wd ⌿ 𝕟64 2
      h   = shapeNewlines sh
      hd  = (h ⊔ n) - h
      hdm = hd ⌿ 𝕟64 2
        -- mmmmmmmm
        -- wwwwwddd
        --        m 
        --
        -- nnnnnnnn
        -- hhhhhddd
        --        m
      f ∷ 𝐼A ChunkO → 𝐼A ChunkO
      f = case ha of
        -- mmmmmmmmm
        -- XX
        -- →
        -- XX␣␣␣␣␣␣␣
        LH → hwrap (const zero) $ \ s → m - s
        -- mmmmmmmmm
        -- XX
        -- →
        -- ␣XX␣␣␣␣␣␣
        CH → hwrap (const wdm) $ \ s → m - s - wdm
        -- mmmmmmmmm
        -- XX
        -- →
        -- ␣␣␣␣␣␣␣XX
        RH → hwrap (\ s → m - s) $ const zero
      g ∷ Sep () (𝐼A ChunkO) → Sep () (𝐼A ChunkO)
      g = case va of
        TV → vwrap (zero @ ℕ64) $ n - h
        CV → vwrap hdm $ n - h - hdm
        BV → vwrap (n - h) $ zero @ ℕ64
  in SummaryO (boxShape m n) $ map (map f ∘ g) cs
  where
    hwrap fi fj xs =
      let s = size xs
          i = fi s
          j = fj s
      in concat
        [ if i ≡ zero then null else single $ PaddingChunkO i
        , xs 
        , if j ≡ zero then null else single $ PaddingChunkO j
        ]
    vwrap i j xs =
      concat
      [ concat $ repeat i $ sepI ()
      , xs
      , concat $ repeat j $ sepI ()
      ]
