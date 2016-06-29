module Game.Collision exposing (..)

{-| This module handles all movement inputs and will move players, trigger new areas, shop screens, down stairs etc.
-}

import Dict exposing (..)
import Utils.Vector as Vector exposing (..)
import Game.Data exposing (..)
import Game.Keyboard exposing (..)
import Game.Maps exposing (..)
import GameData.Tile exposing (..)
import GameData.Building as Building exposing (..)
import Hero exposing (..)
import Monster.Monster as Monster exposing (..)
import Shop.Shop as Shop exposing (..)


tryMoveHero : Direction -> Game.Data.Model -> Game.Data.Model
tryMoveHero dir model =
    let
        movedHero =
            Hero.update (Hero.Move <| dirToVector dir) model.hero

        obstructions =
            getObstructions (Hero.pos movedHero) model
    in
        case obstructions of
            ( _, _, Just monster ) ->
                let
                    _ =
                        Debug.log "mosnter obstruction: " monster
                in
                    model

            -- entering a building
            ( _, Just building, _ ) ->
                enterBuilding building model

            -- path blocked
            ( True, _, _ ) ->
                model

            -- path free, moved
            ( False, _, _ ) ->
                { model | hero = movedHero }


enterBuilding : Building.Model -> Game.Data.Model -> Game.Data.Model
enterBuilding building model =
    case building.buildingType of
        LinkType link ->
            { model | map = Game.Maps.updateArea link.area model.map, hero = Hero.update (Hero.Teleport link.pos) model.hero }

        ShopType shopType ->
            { model | currentScreen = BuildingScreen building, shop = Shop.setCurrentShopType shopType model.shop }

        Ordinary ->
            { model | currentScreen = BuildingScreen building }


{-| Given a position and a map, work out what is on the square
Returns (isTileObstructed, a building entry)
-}
getObstructions : Vector -> Game.Data.Model -> ( Bool, Maybe Building.Model, Maybe Monster )
getObstructions pos ({ hero, map, monsters } as model) =
    let
        ( maybeTile, maybeBuilding ) =
            (thingsAtPosition pos map)

        equalToHeroPosition =
            \monster ->
                let
                    _ =
                        Debug.log "Monster at: " monster
                in
                    Vector.equal pos (Monster.pos monster)

        maybeMonster =
            monsters
                |> List.filter equalToHeroPosition
                |> List.head

        tileObstruction =
            case maybeTile of
                Just tile ->
                    tile.solid

                Nothing ->
                    False
    in
        ( tileObstruction, maybeBuilding, maybeMonster )


{-| Return the tile and possibly the building that is at a given point. Uses currentArea and maps from model to determine which area to look at
-}
thingsAtPosition : Vector -> Game.Maps.Model -> ( Maybe Tile, Maybe Building.Model )
thingsAtPosition pos model =
    let
        area =
            model.currentArea

        buildings =
            getBuildings area model

        map =
            getMap area model

        tile =
            Dict.get (toString pos) map

        building =
            buildingAtPosition pos buildings
    in
        ( tile, building )


{-| Given a point and a list of buildings, return the building that the point is within or nothing
-}
buildingAtPosition : Vector -> List Building.Model -> Maybe Building.Model
buildingAtPosition pos buildings =
    let
        buildingsAtTile =
            List.filter (isBuildingAtPosition pos) buildings
    in
        case buildingsAtTile of
            b :: rest ->
                Just b

            _ ->
                Nothing


{-| Given a point and a building, will return true if the point is within the building
-}
isBuildingAtPosition : Vector -> Building.Model -> Bool
isBuildingAtPosition pos building =
    let
        bottomLeft =
            Vector.sub (Vector.add building.pos building.size) (Vector.new 1 1)
    in
        boxIntersect pos ( building.pos, bottomLeft )


tryMoveMonster : Monster -> ( Game.Data.Model, List Monster ) -> ( Game.Data.Model, List Monster )
tryMoveMonster monster ( { hero, map } as model, monsters ) =
    let
        { x, y } =
            Vector.sub (Hero.pos hero) (Monster.pos monster)

        ( normX, normY ) =
            ( x // abs x, y // abs y )

        movedMonster =
            Monster.move monster (Vector.new normX normY)

        isBuildingObstruction =
            List.any (isBuildingAtPosition (Monster.pos movedMonster)) (getBuildings map.currentArea map)

        isMonsterObstruction =
            List.any (Vector.equal (Monster.pos movedMonster)) (List.map Monster.pos monsters)

        isHeroObstruction =
            Vector.equal (Monster.pos movedMonster) (Hero.pos hero)
    in
        if isBuildingObstruction || isMonsterObstruction || isHeroObstruction then
            ( model, monster :: monsters )
        else
            ( model, movedMonster :: monsters )
