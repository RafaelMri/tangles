module Math.Topology.KnotTh.Invariants.LinkingNumber
    ( linkingNumbersInvariant
    ) where

import Data.List (sort)
import Data.Array.IArray ((!))
import Math.Topology.KnotTh.Knotted
import Math.Topology.KnotTh.Crossings.Diagram


linkingNumbersInvariant :: (Knotted k) => k DiagramCrossingType -> [Int]
linkingNumbersInvariant knot = sort $ do
    let ((n, _, _), ln) = threadsWithLinkingNumbers knot
    i <- [1 .. n]
    j <- [1 .. i - 1]
    return $! abs $! ln ! (i, j)
