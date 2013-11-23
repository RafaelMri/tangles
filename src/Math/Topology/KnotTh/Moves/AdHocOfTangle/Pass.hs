module Math.Topology.KnotTh.Moves.AdHocOfTangle.Pass
    ( neighbours
    ) where

import Data.Maybe (mapMaybe)
import Data.List (sort, nub)
import Control.Monad (unless, guard, msum)
import Math.Topology.KnotTh.Tangle
import Math.Topology.KnotTh.Moves.AdHocOfTangle.Resting
import Math.Topology.KnotTh.Moves.AdHocOfTangle.Move
import Math.Topology.KnotTh.Moves.AdHocOfTangle.ReidemeisterReduction


neighbours :: NATangle -> [NATangle]
neighbours tangle = mapMaybe (\ d -> tryPass 1 d d [opposite d]) $ allOutcomingDarts tangle
    where
        tryPass n ha tb incoming = do
            let ah = opposite ha
            guard $ isDart ah

            let hp = nextCW ha
                ph = opposite hp
            --    tq = nextCCW tb
            --    qt = opposite tq

            msum
                [ do
                    (outcoming, _) <- restingPart tangle incoming
                    let m = length outcoming
                    guard $ m <= n
                    return $! pass incoming outcoming

                , do
                    let selfIncoming = map (threadContinuation . opposite) incoming
                    (outcoming, _) <- restingPart tangle selfIncoming
                    let m = length outcoming
                    guard $ m <= n
                    --guard $
                    --    let inside d = isDart d && sub ! crossingIndex (incidentCrossing d)
                    --    in inside qt || inside ph
                    guard $
                        let everything = sort $ map beginVertex $ selfIncoming ++ outcoming
                        in everything == nub everything
                    return $! pass incoming outcoming

                , do
                    guard $ isDart ph
                    let pa' = nextCW ph
                    guard $ passOver pa' == passOver tb && pa' /= tb
                    tryPass (n + 1) pa' tb (opposite pa' : incoming)
                ]

        pass incoming outcoming = move tangle $ do
            let m = length outcoming
                toRemove = drop m incoming

            substituteC $ map (\ d -> (d, threadContinuation $ opposite d)) incoming ++ zip (map opposite incoming) outcoming
            connectC $ zip outcoming $ map (threadContinuation . opposite) incoming
            unless (null toRemove) $ do
                let p = nextCCW $ opposite $ last toRemove
                let q = opposite $ nextCW $ opposite $ head toRemove
                substituteC [(q, p)]
                maskC $ map endVertex toRemove
            greedy [reduce1st, reduce2nd]