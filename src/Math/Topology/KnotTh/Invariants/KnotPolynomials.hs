{-# LANGUAGE MultiParamTypeClasses #-}
module Math.Topology.KnotTh.Invariants.KnotPolynomials
    ( SkeinRelation(..)
    , reduceSkein
    , skeinRelationPostMinimization
    , skeinRelationMidMinimization
    , skeinRelationPreMinimization
    ) where

import Math.Topology.KnotTh.Algebra.PlanarAlgebra.Reduction
import Math.Topology.KnotTh.Tangle


class (Functor f, TransposeAction (f p), PlanarAlgebra (f p)) => SkeinRelation f p where
    crossingSkein :: DiagramCrossing -> f p


reduceSkein :: (SkeinRelation f p) => TangleDiagram -> f p
reduceSkein = reducePlanarAlgebra . fmap crossingSkein


skeinRelationPostMinimization :: (Ord (f p), MirrorAction (f p), SkeinRelation f p) => (TangleDiagram -> f p) -> TangleDiagram -> f p
skeinRelationPostMinimization invariant tangle = minimum $ do
    p <- allOrientationsOf $ invariant tangle
    [p, transposeIt p]


skeinRelationMidMinimization :: (Ord (f p), MirrorAction (f p), SkeinRelation f p) => (TangleDiagram -> f p) -> TangleDiagram -> f p
skeinRelationMidMinimization invariant tangle = minimum $ do
    p <- map invariant [tangle, transposeCrossings tangle]
    allOrientationsOf p


skeinRelationPreMinimization :: (Ord (f p), SkeinRelation f p) => (TangleDiagram -> f p) -> TangleDiagram -> f p 
skeinRelationPreMinimization invariant tangle = minimum $ do
    inv <- [id, transposeCrossings]
    t <- allOrientationsOf tangle
    return $ invariant $ inv t
