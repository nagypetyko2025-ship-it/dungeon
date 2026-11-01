class_name FramePacing
## Egyenletes mozgás nagy frissítésű monitoron: a fizika (a játékos, a szörnyek, a lövedékek mozgása) annyiszor
## fut másodpercenként, ahányszor a monitor frissít (legfeljebb MAX_TICKS-szer; afölött az egész osztója).
## Különben 160 Hz-en a 60 Hz-es fizika képkockánként felváltva 2-3 képig áll, aztán ugrik: enyhe rángás.
## A játék logikája delta-alapú, így gyorsabb ütemben is ugyanúgy viselkedik. 60 Hz-es monitoron nem változik semmi.

const MAX_TICKS := 165
const MIN_TICKS := 60


## A főmenü, a tábor és a kazamata indulásakor, és teljes képernyő váltásakor (másik monitor) hívják.
static func apply() -> void:
	var refresh := DisplayServer.screen_get_refresh_rate(DisplayServer.window_get_current_screen())
	if refresh <= 0.0:
		refresh = 60.0
	var divisor := ceili(refresh / MAX_TICKS)
	Engine.physics_ticks_per_second = clampi(roundi(refresh / divisor), MIN_TICKS, MAX_TICKS)
