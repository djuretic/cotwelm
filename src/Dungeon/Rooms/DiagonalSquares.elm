module Dungeon.Rooms.DiagonalSquares exposing (template)

{-|

-}

import Dungeon.Rooms.Type exposing (..)


template : RoomTemplate
template =
    { makeWalls = walls
    , makeCorners = corners
    , makeFloors = floors
    }


corners : Dimension -> Walls
corners dimension =
    []


floors : Dimension -> Floors
floors dimension =
    []


walls : Dimension -> List Walls
walls dimension =
    []
