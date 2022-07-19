functor
export
   isTurnByTurn:IsTurnByTurn
   nRow:NRow
   nColumn:NColumn
   map:Map
   nbPlayer:NbPlayer
   players:Players
   colors:Colors
   thinkMin:ThinkMin
   thinkMax:ThinkMax
   turnSurface:TurnSurface
   maxDamage:MaxDamage
   missile:Missile
   mine:Mine
   sonar:Sonar
   drone:Drone
   minDistanceMine:MinDistanceMine
   maxDistanceMine:MaxDistanceMine
   minDistanceMissile:MinDistanceMissile
   maxDistanceMissile:MaxDistanceMissile
   guiDelay:GUIDelay
import
   OS
define
   IsTurnByTurn
   NRow
   NColumn
   Ratio
   Map
   NbPlayer
   Players
   Colors
   ThinkMin
   ThinkMax
   TurnSurface
   MaxDamage
   Missile
   Mine
   Sonar
   Drone
   MinDistanceMine
   MaxDistanceMine
   MinDistanceMissile
   MaxDistanceMissile
   GUIDelay

   RandomMap
in

%%%% Style of game %%%%

   IsTurnByTurn = true

%%%% Players description %%%%

    NbPlayer = 2
    Players = [player1 player2]% player3 player4]
    Colors = [yellow black]% blue red]

%%%% Description of the map %%%%

    fun{RandomMap Rows Columns Ratio}
        fun{RowDesign Columns Ratio}
            if(Columns == 0) then nil
            elseif(({OS.rand} mod Ratio) == 1) then 1|{RowDesign Columns-1 Ratio}
            else 0|{RowDesign Columns-1 Ratio}
            end
        end
        fun{MapDesign Rows Columns Ratio}
            if(Rows == 0) then nil
            else
                {RowDesign Columns Ratio}|{MapDesign Rows-1 Columns Ratio}
            end
        end
    in
        {MapDesign Rows Columns Ratio}
    end

    NRow = {OS.rand} mod ((10 - 4)*NbPlayer) + 4*NbPlayer
    NColumn = {OS.rand} mod ((10 - 4)*NbPlayer) + 4*NbPlayer
    Ratio = {OS.rand} mod ((6 - 4)*NbPlayer) + 4*NbPlayer % Ratio Water/Island

    Map = {RandomMap NRow NColumn Ratio}

%%%% Thinking parameters (only in simultaneous) %%%%

   ThinkMin = 500
   ThinkMax = 3000

%%%% Surface time/turns %%%%

   TurnSurface = 3

%%%% Life %%%%

   MaxDamage = 4

%%%% Number of load for each item %%%%

   Missile = 3
   Mine = 3
   Sonar = 3
   Drone = 3

%%%% Distances of placement %%%%

   MinDistanceMine = 1
   MaxDistanceMine = 2
   MinDistanceMissile = 1
   MaxDistanceMissile = 4

%%%% Waiting time for the GUI between each effect %%%%

   GUIDelay = 500 % ms

end
