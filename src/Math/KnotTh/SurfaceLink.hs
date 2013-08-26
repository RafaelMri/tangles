{-# LANGUAGE TemplateHaskell, TypeFamilies #-}
module Math.KnotTh.SurfaceLink
    ( module Math.KnotTh.Knotted
    , SurfaceLink
    , crossingSurfaceLink
    , faceSurfaceLink
    , dartSurfaceLink
    , emptySurfaceLink
    , changeNumberOfFreeLoops
    , testPrime
    ) where

import Language.Haskell.TH
import Data.Function (fix)
import Data.Array.Base (listArray, unsafeAt, newArray, newArray_, readArray, writeArray)
import Data.Array.Unboxed (UArray)
import Data.Array.ST (STUArray)
import Control.Monad.ST (ST, runST)
import Control.Monad (when, forM_)
import Text.Printf
import Math.KnotTh.Knotted
import Math.KnotTh.Knotted.TH.Knotted
import Math.KnotTh.Knotted.TH.Show


produceKnotted
    [d| data SurfaceLink ct = SurfaceLink
            { faceCount   :: !Int
            , faceOffset  :: !(UArray Int Int)
            , faceLList   :: !(UArray Int Int)
            , faceLLookup :: !(UArray Int Int)
            }
    |]
    defaultKnotted
        { implodeExplodeSettings = Just $ defaultImplodeExplode
            { implodeInitializers =
                [ (,) (mkName "faceCount")   `fmap` [| 0 :: Int |]
                , (,) (mkName "faceOffset")  `fmap` [| listArray (0 :: Int, 1) [0 :: Int, 0] |]
                , (,) (mkName "faceLList")   `fmap` [| listArray (0 :: Int, -1) [] |]
                , (,) (mkName "faceLLookup") `fmap` [| listArray (0 :: Int, -1) [] |]
                ]
            }

        , emptyExtraInitializers =
            [ (,) (mkName "faceCount")   `fmap` [| 1 :: Int |]
            , (,) (mkName "faceOffset")  `fmap` [| listArray (0 :: Int, 1) [0 :: Int, 0] |]
            , (,) (mkName "faceLList")   `fmap` [| listArray (0 :: Int, -1) [] |]
            , (,) (mkName "faceLLookup") `fmap` [| listArray (0 :: Int, -1) [] |]
            ]
        }

produceShowDart ''SurfaceLink ''Dart (const [])
produceShowCrossing ''SurfaceLink ''Crossing
produceShowKnot ''SurfaceLink


instance SurfaceKnotted SurfaceLink where
    data Face SurfaceLink ct = Face !(SurfaceLink ct) {-# UNPACK #-} !Int

    numberOfFaces = faceCount

    nthFace link i
        | i < 1 || i > numberOfFaces link  = error $ printf "nthFace: index %i is out of bounds (1, %i)" i (numberOfFaces link)
        | otherwise                        = Face link (i - 1)

    faceOwner = faceSurfaceLink

    faceIndex (Face _ i) = i - 1

    faceDegree (Face l i) =
        let cur = faceOffset l `unsafeAt` (i - 1)
            nxt = faceOffset l `unsafeAt` i
        in nxt - cur

    nthCCWBorderDart (Face l i) p =
        let cur = faceOffset l `unsafeAt` (i - 1)
            nxt = faceOffset l `unsafeAt` i
        in Dart l $ unsafeAt (faceLList l) $ cur + p `mod` (nxt - cur)

    nthCWBorderDart f p =
        opposite $ nthCCWBorderDart f p

    faceToTheLeft (Dart l i) =
        Face l $ faceLLookup l `unsafeAt` i

    faceToTheRight = faceToTheLeft . opposite


{-# INLINE faceSurfaceLink #-}
faceSurfaceLink :: Face SurfaceLink ct -> SurfaceLink ct
faceSurfaceLink (Face l _) = l


testPrime :: SurfaceLink ct -> Bool
testPrime link = runST $ do
    let sz = numberOfCrossings link
    g <- newArray ((1, 1), (sz, sz)) 0 :: ST s (STUArray s (Int, Int) Int)

    forM_ (allCrossings link) $ \ u ->
        forM_ (adjacentCrossings u) $ \ v -> do
            let i = (crossingIndex u, crossingIndex v)
            w <- readArray g i
            writeArray g i $! w + 1

    v <- newArray_ (1, sz) :: ST s (STUArray s Int Int)
    forM_ [1 .. sz] $ \ i ->
        writeArray v i i

    a <- newArray_ (1, sz) :: ST s (STUArray s Int Bool)
    w <- newArray_ (1, sz) :: ST s (STUArray s Int Int)
    na <- newArray_ (1, sz) :: ST s (STUArray s Int Int)

    let setA i x = do
            j <- readArray v i
            writeArray a j x

    flip fix sz $ \ loop !n -> do
        setA 1 True
        forM_ [2 .. n] $ \ i -> do
            setA i False
            writeArray na (i - 1) i
            writeArray w i =<< do
                p <- readArray v 1
                q <- readArray v i
                readArray g (p, q)

        when (n > 1) $ loop (n - 1)

    return True
