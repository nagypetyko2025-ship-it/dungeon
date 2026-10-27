class_name News
## A főmenü "Újdonságok" doboza (jobb oldalt, lásd MainMenu._build_news): minden változtatásnál ide kerül egy
## rövid, játékosnak szóló sor a legfrissebb dátum alá (a legújabb van felül).

const ENTRIES: Array[Dictionary] = [
	{"date": "2026-10-27", "items": [
		"A kopogás titka: Kormos Gyula küldetéssora a bánya mélyén, a végén a Kopogóval (egyedi főellenség) "
			+ "és A huszonhét lámpása jutalommal.",
		"A próbatétel nehézsége hatfokú (Nagyon könnyű – Brutális), és sokkal nagyobb eséllyel ad mítikus tárgyat "
			+ "(a Brutálisnál 30%).",
		"Próbatétel: random kazamata a bánya mélyén (1–20 emelet, könnyítések és nehezítések, biztos jutalom a végén; "
			+ "10 percenként új).",
		"A kocsmáros küldetésablaka már nem lóg ki a képből.",
		"Puskás Döme, a robbantómester: küldetések, és hidat robbant a bánya szakadéka fölé.",
		"Kibérelhető szoba a kocsmában: ágy (+1 bájital a következő futásra), láda, trófeafal.",
		"Szűrők a küldetések könyvében (J).",
		"30 új kocsmai küldetés (összesen 100).",
		"Kálmán doktor két új küldetése és négy új története.",
		"Mítikus tárgyak fejlesztése mítikus porral (legfeljebb ötször).",
		"Bemehetsz a bányába: alagút, barlangterem, leszakadt híd a szakadék fölött.",
		"Beszélgethetsz a kocsmárossal; a kocsma hátsó folyosóján kiadó szobák.",
	]},
	{"date": "2026-10-26", "items": [
		"Zene a táborban és a kazamatában (5 szám), bal alul kiírja, mi szól.",
		"Három új káoszszörny a 25. emelet után.",
		"A város ládái és hordói már nem átjárhatók.",
		"A király új küldetése (A Káosz kapuja) és négy új története.",
		"Utak minden házhoz, útjelző táblák, a bánya hegye.",
		"Új tutorial saját pályával és tábori bemutatóval.",
		"Kovácsműhely: tárgyfejlesztés és szétszedés porokért.",
	]},
]


## Az egész lista BBCode-ban (dátum aranyszínnel, alatta a pontok).
static func bbcode() -> String:
	var lines: Array[String] = []
	for entry: Dictionary in ENTRIES:
		lines.append("[color=#e8c36a][b]%s[/b][/color]" % entry["date"])
		for item: String in entry["items"]:
			lines.append("• " + item)
		lines.append("")
	return "\n".join(lines).strip_edges()
