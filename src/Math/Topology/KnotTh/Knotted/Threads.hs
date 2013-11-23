module Math.Topology.KnotTh.Knotted.Threads
    ( ThreadList
    , ThreadedCrossing(..)
    , maybeThreadContinuation
    , allThreads
    , numberOfThreads
    , allThreadsWithMarks
    ) where

import Data.Ix (Ix)
import Data.STRef (newSTRef, readSTRef, modifySTRef')
import Data.Array.Unboxed (UArray)
import Data.Array.Unsafe (unsafeFreeze)
import Data.Array.ST (STUArray, newArray, readArray, writeArray)
import Control.Monad.ST
import Control.Monad (foldM)
import Math.Topology.KnotTh.Knotted.Definition


type ThreadList d = (Int, UArray d Int, [(Int, [(d, d)])])


class (CrossingType ct) => ThreadedCrossing ct where
    threadContinuation :: (Knotted k) => Dart k ct -> Dart k ct

    threadContinuation d | isDart d   = nextCCW $ nextCCW d
                         | otherwise  = error "continuation: from endpoint"


{-# INLINE maybeThreadContinuation #-}
maybeThreadContinuation :: (ThreadedCrossing ct, Knotted k) => Dart k ct -> Maybe (Dart k ct)
maybeThreadContinuation d | isDart d   = Just $! threadContinuation d
                          | otherwise  = Nothing


allThreads :: (ThreadedCrossing ct, Knotted k) => k ct -> [[(Dart k ct, Dart k ct)]]
allThreads knot =
    let (_, _, threads) = allThreadsWithMarks knot
    in map snd threads


numberOfThreads :: (ThreadedCrossing ct, Knotted k) => k ct -> Int
numberOfThreads knot =
    let (n, _, _) = allThreadsWithMarks knot
    in n


allThreadsWithMarks :: (ThreadedCrossing ct, Knotted k) => k ct -> ThreadList (Dart k ct)
allThreadsWithMarks knot = runST $ do
    let lp = numberOfFreeLoops knot
    threads <- newSTRef $ replicate lp (0, [])

    (n, visited) <- if numberOfEdges knot == 0
        then return (1, undefined)
        else do
            visited <- (newArray :: (Ix i) => (i, i) -> Int -> ST s (STUArray s i Int)) (dartsRange knot) 0
            n <- foldM (\ !i (!startA, !startB) -> do
                    v <- readArray visited startA
                    if v /= 0
                        then return $! i
                        else do
                            let traceBack !prev !b = do
                                    let a = opposite b
                                    writeArray visited a i
                                    writeArray visited b (-i)
                                    let !next = (a, b) : prev
                                    if isEndpoint a
                                        then return $! Right $! next
                                        else do
                                            let b' = threadContinuation a
                                            if b' == startB
                                                then return $! Left $! next
                                                else traceBack next b'

                                traceFront !prev !b'
                                    | isEndpoint b'  = return $! reverse prev
                                    | otherwise      = do
                                        let !a = threadContinuation b'
                                        let !b = opposite a
                                        writeArray visited a i
                                        writeArray visited b (-i)
                                        traceFront ((a, b) : prev) b

                            tb <- traceBack [] startB
                            thread <- case tb of
                                Left thread  -> return $! thread
                                Right prefix -> do
                                    !suffix <- traceFront [] startB
                                    return $! prefix ++ suffix

                            modifySTRef' threads ((i, thread) :)
                            return $! i + 1
                ) 1 (allEdges knot)
            (,) n `fmap` unsafeFreeze visited

    (,,) (n - 1 + lp) visited `fmap` readSTRef threads