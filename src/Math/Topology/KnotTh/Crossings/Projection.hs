module Math.Topology.KnotTh.Crossings.Projection
    ( ProjectionCrossingType
    , ProjectionCrossing
    , projectionCrossing
    , projectionCrossings
    , projection
    ) where

import Data.Char (isSpace)
import Control.DeepSeq
import qualified Math.Algebra.Group.D4 as D4
import Math.Topology.KnotTh.Knotted


data ProjectionCrossingType = ProjectionCrossing deriving (Eq)


instance NFData ProjectionCrossingType


instance CrossingType ProjectionCrossingType where
    localCrossingSymmetry _ = D4.subGroupD4
    possibleOrientations _ _ = projectionCrossings
    mirrorReversingDartsOrder = id


instance ThreadedCrossing ProjectionCrossingType


instance Show ProjectionCrossingType where
    show _ = "+"


instance Read ProjectionCrossingType where
    readsPrec _ s = case dropWhile isSpace s of
        '+' : t -> [(ProjectionCrossing, t)]
        _       -> []


type ProjectionCrossing = Crossing ProjectionCrossingType


projectionCrossing :: ProjectionCrossing
projectionCrossing = makeCrossing' ProjectionCrossing


projectionCrossings :: [ProjectionCrossing]
projectionCrossings = [projectionCrossing]


projection :: (Knotted k) => k a -> k ProjectionCrossingType
projection = mapCrossings (const projectionCrossing)
