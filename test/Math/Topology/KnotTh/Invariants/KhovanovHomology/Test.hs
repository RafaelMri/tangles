module Math.Topology.KnotTh.Invariants.KhovanovHomology.Test
    ( test
    ) where

import Test.Framework (Test, testGroup)
import Test.Framework.Providers.HUnit (testCase)
import Test.HUnit hiding (Test, test)
import Math.Topology.KnotTh.Invariants.KhovanovHomology


test :: Test
test = testGroup "Tangle generators"
    [ testCase "Loop from 2 propagators" $ do
        let (s, _, _) = glue 2 (propagator :: Smoothing, 0) (propagator, 0)
        numberOfLegs s @?= 0
        numberOfLoops s @?= 1
    ]