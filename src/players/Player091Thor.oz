functor
import
    Input
    System
    OS
export
    portPlayer:StartPlayer
define
    StartPlayer
    TreatStream

    InitPosition
  	Move
  	ChargeItem
  	FireItem
  	FireMine
  	SayExplosion
  	SayPassingDrone
  	SayPassingSonar
in
    proc{TreatStream Stream SubState}
        case Stream of nil then skip
        []initPosition(?ID ?Position)|T then
            {TreatStream T {InitPosition ?ID ?Position SubState}}
        []move(?ID ?Position ?Direction)|T then
            {TreatStream T {Move ?ID ?Position ?Direction SubState}}
        []dive|T then
            {System.showInfo 'Thor dove'}
            {TreatStream T {Record.adjoin SubState submarine(dive:1)}}
        []chargeItem(?ID ?KindItem)|T then
            {TreatStream T {ChargeItem ?ID ?KindItem SubState}}
        []fireItem(?ID ?KindFire)|T then
            {TreatStream T {FireItem ?ID ?KindFire SubState}}
        []fireMine(?ID ?Mine)|T then
            {TreatStream T {FireMine ?ID ?Mine SubState}}
        []isDead(?Answer)|T then
            if(SubState.life == 0) then Answer = true
            else Answer = false end
            {TreatStream T SubState}
        []sayMove(ID Direction)|T then
            {System.showInfo 'Submarine '#ID.id#'('#ID.color#') moved to '#Direction}
            {TreatStream T SubState}
        []saySurface(ID)|T then
            {System.showInfo 'Submarine '#ID.id#'('#ID.color#') went to surface'}
            {TreatStream T SubState}
        []sayCharge(ID KindItem)|T then
            {System.showInfo 'Submarine '#ID.id#'('#ID.color#') charged a '#KindItem}
            {TreatStream T SubState}
        []sayMinePlaced(ID)|T then
            {System.showInfo 'Submarine '#ID.id#'('#ID.color#') placed a mine'}
            {TreatStream T SubState}
        []sayMissileExplode(ID Position ?Message)|T then
            {System.showInfo 'Submarine '#ID.id#'('#ID.color#') launched a missile to ('#Position.x#','#Position.y#')'}
            {TreatStream T {SayExplosion ID Position ?Message SubState}}
        []sayMineExplode(ID Position ?Message)|T then
            {System.showInfo 'Submarine '#ID.id#'('#ID.color#') exploded a mine at ('#Position.x#','#Position.y#')'}
            {TreatStream T {SayExplosion ID Position ?Message SubState}}
        []sayPassingDrone(Drone ?ID ?Answer)|T then
            {SayPassingDrone Drone ?ID ?Answer SubState}
            if(Answer) then {System.showInfo 'Thor has been discovered'}
            else {System.showInfo 'Thor is well hidden'} end
            {TreatStream T SubState}
        []sayAnswerDrone(Drone ID Answer)|T then
            if(Answer) then {System.showInfo 'Thor knows someone has been found...'}
            else {System.showInfo 'Thor knows the drone found nothing interesting'} end
            {TreatStream T SubState}
        []sayPassingSonar(?ID ?Answer)|T then
            {TreatStream T {SayPassingSonar ?ID ?Answer SubState}}
        []sayAnswerSonar(ID Answer)|T then
            {System.showInfo 'Thor is analyzing a position'}
            {TreatStream T SubState}
        []sayDeath(ID)|T then
            {System.showInfo 'Thor knows the '#ID.color#' submarine died'}
            {TreatStream T SubState}
        []sayDamageTaken(ID Damage LifeLeft)|T then
            {System.showInfo 'Thor knows the '#ID.color#' submarine has '#LifeLeft#' lives left'}
            {TreatStream T SubState}
        []_|T then {TreatStream T SubState} end
    end

    fun{StartPlayer Color ID}
        Stream
        Port
        Submarine
    in
        {NewPort Stream Port}
        Submarine = submarine(id:id(id:ID color:Color name:player091thor) life:Input.maxDamage mines:0 minesPlaced:nil missiles:0 drones:0 sonars:0 path:_ dive:0 pos:_)
        thread
            {TreatStream Stream Submarine}
        end
        Port
    end

    %%%%%%%%%%%%%
    % Functions %
    %%%%%%%%%%%%%
    fun{InitPosition ?ID ?Position SubState}
        fun{DefPos}
            local Pt in
                Pt = pt(x:({OS.rand} mod(Input.nRow-1) +1) y:({OS.rand} mod(Input.nColumn-1) +1))
                if({Nth {Nth Input.map Pt.x} Pt.y} \= 0) then {DefPos}
                else Pt end
            end
        end
    in
        ID = SubState.id
        Position = {DefPos}
        {System.showInfo 'Thor (id:'#ID.id#', color:'#ID.color#') appeared at ('#Position.x#','#Position.y#')'}
        {Record.adjoin SubState submarine(path:Position|nil pos:Position)}
    end

  	fun{Move ?ID ?Position ?Direction SubState}
        proc{DefDir CurPos}
            local Surf N in
                Surf = {OS.rand} mod 42
                if(Surf mod 7 == 1) then
                    Direction = surface
                    Position = CurPos
                else
                    N = {OS.rand} mod 4
                    case N of 0 then
                        if(CurPos.x-1 > 0 andthen {Nth {Nth Input.map (CurPos.x-1)} CurPos.y} == 0) then
                            Direction = west
                            Position = pos(x:CurPos.x-1 y:CurPos.y)
                        else {DefDir CurPos} end
                    [] 1 then
                        if(CurPos.x+1 =< Input.nColumn andthen {Nth {Nth Input.map (CurPos.x+1)} CurPos.y} == 0) then
                            Direction = east
                            Position = pos(x:CurPos.x+1 y:CurPos.y)
                        else {DefDir CurPos} end
                    [] 2 then
                        if(CurPos.y-1 > 0 andthen {Nth {Nth Input.map CurPos.x} (CurPos.y-1)} == 0) then
                            Direction = north
                            Position = pos(x:CurPos.x y:CurPos.y-1)
                        else {DefDir CurPos} end
                    else
                        if(CurPos.y+1 =< Input.nRow andthen {Nth {Nth Input.map CurPos.x} CurPos.y+1} == 0) then
                            Direction = south
                            Position = pos(x:CurPos.x y:CurPos.y+1)
                        else {DefDir CurPos} end
                    end
                end
            end
        end
    in
        if(SubState.life == 0) then
            ID = null
            Position = null
            Direction = null
            SubState
        else
            ID = SubState.id
            {DefDir SubState.pos}
            if(Direction == surface) then
                {System.showInfo 'Thor emerged'}
                {Record.adjoin SubState submarine(path:Position|nil dive:0)}
            else
                {System.showInfo 'Thor moved '#Direction}
                {Record.adjoin SubState submarine(path:Position|SubState.path pos:Position)}
            end
        end
    end

  	fun{ChargeItem ?ID ?Item SubState}
        if(SubState.life == 0) then
            ID = null
            Item = null
            SubState
        else
            local N in
                ID = SubState.id
                N = {OS.rand} mod 8
                case N of 0 then
                    {System.showInfo 'Thor found nothing'}
                    Item = null
                    SubState
                [] 1 then
                    if(SubState.mines =< Input.mine) then
                        {System.showInfo 'Thor caught a mine'}
                        Item = mine
                        {Record.adjoin SubState sub(mines:SubState.mines+1)}
                    else
                        {System.showInfo 'Thor is at is maximum capacity and could not charge'}
                        Item = null
                        SubState
                    end
                [] 2 then
                    if(SubState.drones =< Input.drone) then
                        {System.showInfo 'Thor caught a drone'}
                        Item = drone
                        {Record.adjoin SubState sub(drones:SubState.drones+1)}
                    else
                        {System.showInfo 'Thor is at is maximum capacity and could not charge'}
                        Item = null
                        SubState
                    end
                [] 3 then
                    if(SubState.sonars =< Input.sonar) then
                        {System.showInfo 'Thor caught a sonar'}
                        Item = sonar
                        {Record.adjoin SubState sub(sonars:SubState.sonars+1)}
                    else
                        {System.showInfo 'Thor is at is maximum capacity and could not charge'}
                        Item = null
                        SubState
                    end
                else
                    if(SubState.missiles =< Input.missile) then
                        {System.showInfo 'Thor caught a missile'}
                        Item = missile
                        {Record.adjoin SubState sub(missiles:SubState.missiles+1)}
                    else
                        {System.showInfo 'Thor is at is maximum capacity and could not charge'}
                        Item = null
                        SubState
                    end
                end
            end
        end
    end

  	fun{FireItem ?ID ?Item SubState}
        fun{DefTarget Min Max Pos}
            local Target N in
                N = {OS.rand} mod 4
                case N of 0 then Target = pos(x:(Pos.x+({OS.rand} mod(Max - Min) +Min)) y:(Pos.y+({OS.rand} mod(Max - Min) +Min)))
                [] 1 then Target = pos(x:(Pos.x-({OS.rand} mod(Max - Min) +Min)) y:(Pos.y+({OS.rand} mod(Max - Min) +Min)))
                [] 2 then Target = pos(x:(Pos.x+({OS.rand} mod(Max - Min) +Min)) y:(Pos.y-({OS.rand} mod(Max - Min) +Min)))
                else Target = pos(x:(Pos.x-({OS.rand} mod(Max - Min) +Min)) y:(Pos.y-({OS.rand} mod(Max - Min) +Min))) end
                if({Nth {Nth Input.map Target.x} Target.y} == 0 andthen Target \= Pos) then
                    Target
                else {DefTarget Min Max Pos} end
            end
        end
    in
        if(SubState.life == 0) then
            ID = null
            Item = null
            SubState
        else
            ID = SubState.id
            local N in
                N = {OS.rand} mod 6
                case N of 0 then
                    {System.showInfo 'Thor decided to wait'}
                    Item = null
                    SubState
                [] 1 then
                    if(SubState.missiles > 0) then
                        local Target in
                            Target = {DefTarget Input.minDistanceMissile Input.maxDistanceMissile SubState.pos}
                            {System.showInfo 'Thor launched a missile to ('#Target.x#','#Target.y#')'}
                            Item = missile(Target)
                        end
                        {Record.adjoin SubState sub(missiles:SubState.missiles-1)}
                    else
                        {System.showInfo 'Thor has no missiles'}
                        Item = null
                        SubState
                    end
                [] 2 then
                    if(SubState.drones > 0) then
                        local Row in
                            Row = {OS.rand} mod Input.nRow +1
                            {System.showInfo 'Thor launched a drone on row '#Row}
                            Item = drone(row Row)
                        end
                        {Record.adjoin SubState sub(drones:SubState.drones-1)}
                    else
                        {System.showInfo 'Thor has no drones'}
                        Item = null
                        SubState
                    end
                [] 3 then
                    if(SubState.sonars > 0) then
                        {System.showInfo 'Thor launched a sonar'}
                        Item = sonar
                        {Record.adjoin SubState sub(sonars:SubState.sonars-1)}
                    else
                        {System.showInfo 'Thor has no sonars'}
                        Item = null
                        SubState
                    end
                else
                    if(SubState.mines > 0) then
                        {System.showInfo 'Thor placed a mine at ('#SubState.path.1.x#','#SubState.path.1.y#')'}
                        Item = mine(SubState.path.1)
                        {Record.adjoin SubState sub(minesPlaced:Item|SubState.minesPlaced mines:SubState.mines-1)}
                    else
                        {System.showInfo 'Thor has no mines'}
                        Item = null
                        SubState
                    end
                end
            end
        end
    end

  	fun{FireMine ?ID ?Mine SubState}
        if(SubState.life == 0) then
            ID = null
            Mine = null
            SubState
        else
            ID = SubState.id
            if(SubState.minesPlaced == nil) then
                {System.showInfo 'Thor has no mines placed'}
                Mine = null
                SubState
            else
                if(({OS.rand} mod 5) == 1) then
                    {System.showInfo 'Thor decided to attack'}
                    Mine = {Nth SubState.minesPlaced ({OS.rand} mod({Length SubState.minesPlaced}) +1)}
                    {Record.adjoin SubState submarine(minesPlaced:{List.subtract SubState.minesPlaced Mine})}
                else
                    {System.showInfo 'Thor is indulgent for this time...'}
                    Mine = null
                    SubState
                end
            end
        end
    end

  	fun{SayExplosion ID Position ?Message SubState}
        local Dist in
            Dist = {Abs (Position.x-SubState.pos.x)} + {Abs (Position.y-SubState.pos.y)}
            case Dist of 0 then
                if(SubState.life - 2 < 1) then
                    Message = sayDeath(SubState.id)
                    {Record.adjoin SubState submarine(life:0)}
                else
                    Message = sayDamageTaken(SubState.id 2 SubState.life)
                    {Record.adjoin SubState submarine(life:(SubState.life-2))}
                end
            [] 1 then
                if(SubState.life - 1 < 1) then
                    Message = sayDeath(SubState.id)
                    {Record.adjoin SubState submarine(life:0)}
                else
                    Message = sayDamageTaken(SubState.id 1 SubState.life)
                    {Record.adjoin SubState submarine(life:(SubState.life-1))}
                end
            else
                Message = sayDamageTaken(SubState.id 0 SubState.life)
                SubState
            end
        end
    end

  	proc{SayPassingDrone Drone ?ID ?Answer SubState}
        if(SubState.life == 0) then
            ID = null
            Answer = null
        else
            ID = SubState.id
            case Drone of drone(row X) then
                if(X == SubState.pos.x) then Answer = true
                else Answer = false end
            [] drone(column Y) then
                if(Y == SubState.pos.y) then Answer = true
                else Answer = false end
            else Answer = false end
        end
    end

  	fun{SayPassingSonar ?ID ?Answer SubState}
        if(SubState.life == 0) then
            ID = null
            Answer = null
            SubState
        else
            ID = SubState.id
            if(({OS.rand} mod 2) == 1) then
                Answer = pos(x:SubState.pos.x y:({OS.rand} mod(Input.nColumn) +1))
            else
                Answer = pos(x:({OS.rand} mod(Input.nRow) +1) y:SubState.pos.y)
            end
            SubState
        end
    end

end
