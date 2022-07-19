functor
import
Player091Thor
Player091Loki
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player1 then {Player091Thor.portPlayer Color ID}
		[] player2 then {Player091Loki.portPlayer Color ID}
		[] player3 then {Player091Thor.portPlayer Color ID}
		[] player4 then {Player091Loki.portPlayer Color ID}
		end
	end
end
