module Math.KnotTh.Crossings.Projection
	( ProjectionCrossing(..)
	, ProjectionCrossingState
	, projectionCrossing
	, projectionCrossings
	, projection
	) where

import Control.DeepSeq
import Math.Algebra.Group.D4 (subGroupD4)
import Math.KnotTh.Knotted


data ProjectionCrossing = ProjectionCrossing deriving (Eq)


instance NFData ProjectionCrossing


instance CrossingType ProjectionCrossing where
	localCrossingSymmetry _ = subGroupD4

	possibleOrientations _ _ = projectionCrossings


instance ThreadedCrossing ProjectionCrossing where
	continuation d
		| isDart d   = nextCCW $ nextCCW d
		| otherwise  = error "continuation: from endpoint"


instance Show ProjectionCrossing where
	show _ = "+"


type ProjectionCrossingState = CrossingState ProjectionCrossing


projectionCrossing :: ProjectionCrossingState
projectionCrossing = makeCrossing' ProjectionCrossing


projectionCrossings :: [ProjectionCrossingState]
projectionCrossings = [projectionCrossing]


projection :: (CrossingType ct, Knotted k c d) => k ct -> k ProjectionCrossing
projection = mapCrossings (const projectionCrossing)
