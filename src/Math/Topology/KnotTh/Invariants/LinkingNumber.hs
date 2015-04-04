module Math.Topology.KnotTh.Invariants.LinkingNumber
    ( linkingNumbersInvariant
    ) where

import Data.List (sort)
import Data.Array.IArray ((!))
import Math.Topology.KnotTh.Knotted
import Math.Topology.KnotTh.Knotted.Crossings.Diagram


linkingNumbersInvariant :: (KnottedPlanar k) => k DiagramCrossing -> [Int]
linkingNumbersInvariant knot = sort $ do
    let ((n, _, _), ln) = threadsWithLinkingNumbers knot
    i <- [1 .. n]
    j <- [1 .. i - 1]
    return $! abs $! ln ! (i, j)
