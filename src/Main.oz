functor
import
    GUI
    Input
    PlayerManager
    System
    OS
define
    Board
    InitPlayers

    %%%%%%%%%%%%%%%%%%%%
    % Submarine Object %
    %%%%%%%%%%%%%%%%%%%%

    class Submarine
        attr port id surface turns
        meth init(Port ID)
            port := Port
            id := ID
            surface := 1
            turns := 0
        end
        meth getValue(Value X)
            case Value of 'port' then X = @port
            [] 'id' then X = @id
            [] 'turns' then X = @turns
            [] 'surface' then X = @surface
            end
        end
        meth dive() surface := 0 end
        meth emerge()
            surface := 1
            turns := Input.turnSurface
        end
        meth newTurn() turns := @turns-1 end
    end

    %%%%%%%%%%%%%%%%%%%
    % Creates players %
    %%%%%%%%%%%%%%%%%%%

    proc {God}
    	fun {Create PList CList ID}
    		if ID > Input.nbPlayer then nil
    		else
    			case PList#CList of (Player|T1)#(Color|T2) then
            {New Submarine init({PlayerManager.playerGenerator Player Color ID} ID)}|{Create T1 T2 ID+1}
          else nil end
    		end
    	end
      proc {Place Sub}
        local Port ID Pos in
          {Sub getValue('port' Port)}
          {Send Port initPosition(ID Pos)}
          {Wait ID} {Wait Pos}
          {System.showInfo 'God spawned '#ID.name#'('#ID.color#') at ('#Pos.x#','#Pos.y#')'}
          {Send Board initPlayer(ID Pos)}
        end
      end
    in
    	InitPlayers = {Create Input.players Input.colors 1}
      {List.forAll InitPlayers Place}
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Turn by turn Game Manager %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    proc{TBT Board Players Round} % Turn by turn
        Living
        fun{DeleteDeaths Submarines} % Filters the list of players and keep submarines with  1 or more lives
            case Submarines of nil then nil
            [] CSubmarine|T then
                local Port Dead ID in
                  {CSubmarine getValue('port' Port)}
                  {CSubmarine getValue('id' ID)}
                  {Send Port isDead(Dead)}
                  {Wait Dead}
                  if(Dead) then
                      {Send Board removePlayer(ID)}
                      {DeleteDeaths T}
                  else CSubmarine|{DeleteDeaths T} end
                end
            end
        end
        proc{TBTExtend Board Players}
            proc{Turn CSubmarine}
                local Turns in
                    {CSubmarine getValue('turns' Turns)}
                    if(Turns < 1) then
                        local Port in
                            {CSubmarine getValue('port' Port)}
                            {CSubmarine dive()}
                            {Send Port dive}
                            {Move Board CSubmarine Living}
                        end
                    else {CSubmarine newTurn()} end
                end
            end
        in
            case Players of CSubmarine|T then
                {Turn CSubmarine}
                {TBTExtend Board T}
            else skip end
        end
    in
        {System.showInfo 'TURN #'#Round}
        Living = {DeleteDeaths Players}
        case Living of H|nil then
            local ID in
                {H getValue('id' ID)}
                {System.showInfo 'VICTORY FOR '#ID.color#' SUBMARINE'}
            end
        else
            {Delay Input.guiDelay}
            {TBTExtend Board Living}
            {TBT Board Living Round+1}
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Simultaneous Game Manager %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    proc{Sim Board Players} % Simultaneous
        DeadCount
        proc{DiveAll Submarines}
            case Submarines of nil then skip
            [] CSubmarine|T then
                local Port in
                    {CSubmarine getValue('port' Port)}
                    {Send Port dive}
                end
            end
        end
        proc{Play CSubmarine}
            local Port Dead ID in
              {CSubmarine getValue('port' Port)}
              {CSubmarine getValue('id' ID)}
              {Send Port isDead(Dead)}
              {Wait Dead}
              if(Dead) then
                  DeadCount := @DeadCount+1
                  {Send Board removePlayer(ID)}
              else
                  local Emerged in
                      {CSubmarine getValue('surface' Emerged)}
                      if(Emerged == 1) then
                          {Delay Input.turnSurface*1000}
                          {Send Port dive}
                      else {Thinking} end
                  end
                  if(@DeadCount < Input.nbPlayer-1) then
                    {Move Board CSubmarine Players}
                    {Play CSubmarine}% Arreter si seul joueur
                  else {System.showInfo 'VICTORY FOR '#ID.color#' SUBMARINE'} end
              end
            end
        end
        proc{SubThread CSubmarine}
            thread {Play CSubmarine} end
        end
    in
        DeadCount = {NewCell 0}
        {DiveAll Players}
        {List.forAll Players SubThread}
    end

    %%%%%%%%%%%%%%%%
    % Broadcasting %
    %%%%%%%%%%%%%%%%

    proc {Broadcast Board Players Message}
      proc{SayMineExp CSubmarine ID Pos}
        local Port Msg in
          {CSubmarine getValue('port' Port)}
          {Send Port sayMineExplode(ID Pos Msg)}
          {Wait Msg}
          if (Msg \= null) then
            case Msg of sayDamageTaken(SubID Damage LifeLeft) then
              {Broadcast Board Players sayDamageTaken(SubID Damage LifeLeft)}
              {Send Board lifeUpdate(SubID LifeLeft)}
            [] sayDeath(SubID) then
              {Broadcast Board Players sayDeath(SubID)}
              {Send Board removePlayer(SubID)}
            end
          end
        end
      end
      proc{SayMissileExp CSubmarine ID Pos}
        local Port Msg in
          {CSubmarine getValue('port' Port)}
          {Send Port sayMissileExplode(ID Pos Msg)}
          {Wait Msg}
          if (Msg \= null) then
            case Msg of sayDamageTaken(SubID Damage LifeLeft) then
              {Broadcast Board Players sayDamageTaken(SubID Damage LifeLeft)}
              {Send Board lifeUpdate(SubID LifeLeft)}
            [] sayDeath(SubID) then
              {Broadcast Board Players sayDeath(SubID)}
              {Send Board removePlayer(SubID)}
            end
          end
        end
      end
      proc{SayPassingSonar CSubmarine ID}
        local Port Answer in
          {CSubmarine getValue('port' Port)}
          {Send Port sayPassingSonar(ID Answer)}
          {Wait Answer}
          {Send Port sayAnswerSonar(ID Answer)}
        end
      end
      proc{SayPassingDrone CSubmarine Drone ID}
        local Port Answer in
          {CSubmarine getValue('port' Port)}
          {Send Port sayPassingDrone(Drone ID Answer)}
          {Wait Answer}
          {Send Port sayAnswerDrone(Drone ID Answer)}
        end
      end
      proc{SendMsg CSubmarine}
        local Port in
          {CSubmarine getValue('port' Port)}
          {Send Port Message}
        end
      end
    in
      case Message of sayMineExplode(ID Pos) then
        {List.forAll Players proc{$ CSubmarine} {SayMineExp CSubmarine ID Pos} end}
      [] sayMissileExplode(ID Pos) then
        {List.forAll Players proc{$ CSubmarine} {SayMissileExp CSubmarine ID Pos} end}
      [] sayPassingSonar(ID) then
        {List.forAll Players proc{$ CSubmarine} {SayPassingSonar CSubmarine ID} end}
      [] sayPassingDrone(Drone ID) then
        {List.forAll Players proc{$ CSubmarine} {SayPassingDrone CSubmarine Drone ID} end}
      else {List.forAll Players SendMsg} end
    end

    %%%%%%%%%%%
    % Actions %
    %%%%%%%%%%%

    proc{Thinking}
        {Delay ({OS.rand} mod(Input.thinkMax - Input.thinkMin) + Input.thinkMin)}
    end

    proc{Move Board CSubmarine Living}
        local Port ID Pos Dir in
            {CSubmarine getValue('port' Port)}
            {Send Port move(ID Pos Dir)}
            {Wait ID} {Wait Pos} {Wait Dir}

            if(ID \= null) then
                if(Dir == surface) then
                    {Broadcast Board Living saySurface(ID)}
                    {Send Board surface(ID)}
                    {CSubmarine emerge()}
                else
                    {Broadcast Board Living sayMove(ID Dir)}
                    {Send Board movePlayer(ID Pos)}
                    if(Input.isTurnByTurn) then
                        {ChargeItem Board CSubmarine Living}
                        {FireItem Board CSubmarine Living}
                        {ExplodeMine Board CSubmarine Living}
                    else
                        {Thinking}
                        {ChargeItem Board CSubmarine Living}
                        {Thinking}
                        {FireItem Board CSubmarine Living}
                        {Thinking}
                        {ExplodeMine Board CSubmarine Living}
                    end
                end
            else skip end
        end
    end

    proc{ChargeItem Board CSubmarine Living}
        local Port ID Item Load in
            {CSubmarine getValue('port' Port)}
            {Send Port chargeItem(ID Item)}
            {Wait ID} {Wait Item}
            if(ID \= null andthen Item\= null) then
                if(Item == mine orelse Item == missile orelse Item == sonar orelse Item == drone) then
                    {Broadcast Board Living sayCharge(ID Item)}
                else skip end
            else skip end
        end
    end

    proc{FireItem Board CSubmarine Living}
        local Port ID Fire in
            {CSubmarine getValue('port' Port)}
            {Send Port fireItem(ID Fire)}
            {Wait ID} {Wait Fire}

            if(ID \= null andthen Fire \= null) then
                case Fire of mine(Pos) then
                    {Broadcast Board Living sayMinePlaced(ID)}
                    {Send Board putMine(ID Pos)}
                [] missile(Pos) then {Broadcast Board Living sayMissileExplode(ID Pos)}
                [] sonar then {Broadcast Board CSubmarine sayPassingSonar(ID)}
                [] drone(row X) then {Broadcast Board CSubmarine sayPassingDrone(drone(row X) ID)}
                [] drone(column Y) then {Broadcast Board CSubmarine sayPassingDrone(drone(column Y) ID)}
                else skip end
            else skip end
        end
    end

    proc{ExplodeMine Board CSubmarine Living}
        local Port ID Mine in
            {CSubmarine getValue('port' Port)}
            {Send Port fireMine(ID Mine)}
            {Wait ID} {Wait Mine}

            if(ID \= null) then
                case Mine of mine(Pos) then
                    {Broadcast Board Living sayMineExplode(ID Pos)}
                    {Send Board removeMine(ID Pos)}
                    {Send Board explosion(ID Pos)}
                else skip end
            else skip end
        end
    end

in
    %%%%%%%%%%%%%%%%%%%%%
    % Creates gameboard %
    %%%%%%%%%%%%%%%%%%%%%
    {System.showInfo '******************************'}
    {System.showInfo '* WELCOME IN CAPTAIN SONAR ! *'}
    {System.showInfo '******************************'}
    {System.showInfo 'Map creation...'}
    Board = {GUI.portWindow}
    {Send Board buildWindow}
    {System.showInfo 'Design finished!'}

    {System.showInfo 'God is creating submarines...'}
    {God}
    {System.showInfo 'All submarines ready!'}

    if(Input.isTurnByTurn) then {TBT Board InitPlayers 1}
    else {Sim Board InitPlayers} end
end
