module Math.Topology.KnotTh.Moves.AdHocOfTangle.Test
    ( passTests
    ) where

import Math.Topology.KnotTh.Tangle
import qualified Math.Topology.KnotTh.Moves.AdHocOfTangle.Pass as Pass


passTests :: [(NATangle, [NATangle])]
passTests = map (\ tangle -> (tangle, Pass.neighbours tangle))
    [ decodeCascadeCode [(WU, 0), (MO, 0)]
    , decodeCascadeCode [(XO, 0), (XO, 0), (XO, 1)]

    , implode
        ( 0
        , [(5, 0), (6, 0), (6, 1), (2, 2)]
        ,    [ ([(6, 2), (4, 1), (2, 0), (5, 2)], overCrossing )
            , ([(1, 2), (3, 0), (0, 3), (5, 3)], underCrossing)
            , ([(2, 1), (4, 0), (4, 3), (4, 2)], overCrossing )
            , ([(3, 1), (1, 1), (3, 3), (3, 2)], overCrossing )
            , ([(0, 0), (6, 3), (1, 3), (2, 3)], underCrossing)
            , ([(0, 1), (0, 2), (1, 0), (5, 1)], underCrossing)
            ]
        )

    , implode
        ( 0
        , [(3, 2), (6, 0), (6, 1), (2, 2)]
        ,     [ ([(6, 2), (2, 1), (2, 0), (5, 2)], overCrossing )
            , ([(1, 2), (1, 1), (0, 3), (5, 3)], underCrossing)
            , ([(4, 1), (4, 0), (0, 0), (4, 2)], overCrossing )
            , ([(3, 1), (3, 0), (3, 3), (5, 0)], overCrossing )
            , ([(4, 3), (6, 3), (1, 3), (2, 3)], underCrossing)
            , ([(0, 1), (0, 2), (1, 0), (5, 1)], underCrossing)
            ]
        )
    ]