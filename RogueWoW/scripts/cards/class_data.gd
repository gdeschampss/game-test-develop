class_name ClassData
extends RefCounted
## Raças, classes, habilidades (e em que nível destravam), rodadas de cartas e o
## deck padrão de 10 cartas de cada classe.
## As raças são provisórias (genéricas de fantasia): troque nomes/cores à vontade.

## Rodadas de cartas: no nível X, mostra N cartas sorteadas do deck e o jogador escolhe K.
const CARD_ROUNDS := {
	3: {"show": 4, "pick": 2},
	6: {"show": 3, "pick": 1},
}

const RARITY_COLORS := {
	"comum": Color(0.75, 0.75, 0.75),
	"incomum": Color(0.35, 0.8, 0.45),
	"rara": Color(0.35, 0.6, 1.0),
	"mítica": Color(1.0, 0.55, 0.15),
}

const SCHOOL_COLORS := {
	"Fogo": Color(0.95, 0.4, 0.15),
	"Gelo": Color(0.45, 0.8, 1.0),
	"Arcano": Color(0.75, 0.45, 1.0),
	"Aço": Color(0.75, 0.75, 0.8),
	"Fúria": Color(0.85, 0.2, 0.15),
	"Natureza": Color(0.4, 0.8, 0.3),
	"Sombra": Color(0.5, 0.25, 0.65),
	"Almas": Color(0.4, 0.95, 0.75),
}

## pet: animal do Caçador desta raça
const RACES := {
	"humano": {"rig_scale": Vector3(1.0, 1.0, 1.0), "name": "Humano", "skin": Color(0.95, 0.78, 0.65), "height": 1.0, "pet": "Lobo Cinzento", "pet_color": Color(0.55, 0.55, 0.6), "pet_size": 1.0,
		"desc": "Versáteis e determinados. Caçadores humanos andam com um lobo cinzento."},
	"anao": {"rig_scale": Vector3(1.0, 1.0, 1.0), "name": "Anão", "skin": Color(0.9, 0.7, 0.55), "height": 0.82, "pet": "Urso Pardo", "pet_color": Color(0.45, 0.3, 0.2), "pet_size": 1.35,
		"desc": "Baixos, robustos e teimosos. Caçadores anões domam ursos pardos."},
	"elfo": {"rig_scale": Vector3(0.92, 1.05, 0.92), "name": "Elfo", "skin": Color(0.85, 0.85, 0.95), "height": 1.08, "pet": "Pantera Noturna", "pet_color": Color(0.2, 0.18, 0.3), "pet_size": 1.0,
		"desc": "Ágeis e antigos. Caçadores élficos caçam com panteras noturnas."},
	"orc": {"rig_scale": Vector3(1.22, 1.03, 1.18), "name": "Orc", "skin": Color(0.45, 0.62, 0.35), "height": 1.12, "pet": "Javali de Guerra", "pet_color": Color(0.5, 0.35, 0.25), "pet_size": 1.15,
		"desc": "Fortes e ferozes. Caçadores orcs lutam ao lado de javalis de guerra."},
}

const MAGE := {
	"hero": {"race": "humano", "sex": "m"}, "hero_desc": "Feiticeiro de alma rubra e cajado. Magias elementais à distância: fogo, gelo e teleporte.",
	"name": "Mago", "color": Color(0.25, 0.35, 0.85), "hp": 100.0, "weapon": "staff",
	"model": "darkelf", "tint": Color(0.72, 0.82, 1.0), "icon": "class_mago",
	"resource": "mana", "costs": {"basic": 0, "a1": 25, "a2": 20},
	"anims": {"basic": "attack_cast", "a1": "punch", "a2": "roll"},
	"desc": "Magias elementais à distância: fogo, gelo e teleporte.",
	"abilities": {
		"basic": {"name": "Bola de Fogo", "icon": "fireball", "key": "LMB", "cooldown": 0.45, "unlock": 1},
		"a1": {"name": "Nova de Gelo", "icon": "frostnova", "key": "1", "cooldown": 6.0, "unlock": 2},
		"a2": {"name": "Piscar", "icon": "blink", "key": "2", "cooldown": 5.0, "unlock": 4},
	},
	"deck": [
		{"id": "brasa_viva", "name": "Brasa Viva", "school": "Fogo", "rarity": "comum", "text": "Bola de Fogo causa +35% de dano."},
		{"id": "leque_chamas", "name": "Leque de Chamas", "school": "Fogo", "rarity": "rara", "text": "Bola de Fogo dispara 3 projéteis em leque."},
		{"id": "combustao", "name": "Combustão", "school": "Fogo", "rarity": "rara", "text": "Bola de Fogo explode ao acertar, causando dano em área."},
		{"id": "inverno_eterno", "name": "Inverno Eterno", "school": "Gelo", "rarity": "incomum", "text": "Nova de Gelo tem +45% de raio."},
		{"id": "coracao_gelo", "name": "Coração de Gelo", "school": "Gelo", "rarity": "incomum", "text": "Nova de Gelo recarrega 40% mais rápido."},
		{"id": "pele_geada", "name": "Pele de Geada", "school": "Gelo", "rarity": "comum", "text": "+40 de vida máxima."},
		{"id": "passo_arcano", "name": "Passo Arcano", "school": "Arcano", "rarity": "comum", "text": "Piscar recarrega 45% mais rápido."},
		{"id": "ruptura", "name": "Ruptura Dimensional", "school": "Arcano", "rarity": "mítica", "text": "Ao Piscar, explode no ponto de chegada."},
		{"id": "sede_arcana", "name": "Sede Arcana", "school": "Arcano", "rarity": "incomum", "text": "Cada orbe de XP coletado cura 3 de vida."},
		{"id": "celeridade", "name": "Celeridade", "school": "Arcano", "rarity": "comum", "text": "+18% de velocidade de movimento."},
	],
}

const WARRIOR := {
	"hero": {"race": "humano", "sex": "m"}, "hero_desc": "Rei guerreiro de armadura azul e dourada, com duas espadas. Aguenta pancada e avança no meio dos inimigos.",
	"name": "Guerreiro", "color": Color(0.6, 0.25, 0.2), "hp": 140.0, "weapon": "sword_shield",
	"model": "knight", "tint": Color(1, 1, 1), "icon": "class_guerreiro",
	"resource": "furia", "costs": {"basic": 0, "a1": 20, "a2": 30},
	"anims": {"basic": "attack_1h", "a1": "sprint", "a2": "attack_shield"},
	"desc": "Corpo a corpo com espada e escudo. Aguenta pancada e avança no meio dos inimigos.",
	"abilities": {
		"basic": {"name": "Golpe de Espada", "icon": "sword_slash", "key": "LMB", "cooldown": 0.55, "unlock": 1},
		"a1": {"name": "Investida", "icon": "charge", "key": "1", "cooldown": 6.0, "unlock": 2},
		"a2": {"name": "Muralha de Escudo", "icon": "shield_wall", "key": "2", "cooldown": 12.0, "unlock": 4},
	},
	"deck": [
		{"id": "lamina_afiada", "name": "Lâmina Afiada", "school": "Aço", "rarity": "comum", "text": "Golpe de Espada causa +35% de dano."},
		{"id": "golpe_amplo", "name": "Golpe Amplo", "school": "Aço", "rarity": "incomum", "text": "Golpe de Espada alcança 40% mais longe."},
		{"id": "sede_sangue", "name": "Sede de Sangue", "school": "Fúria", "rarity": "rara", "text": "Cada inimigo atingido pelo Golpe cura 3 de vida."},
		{"id": "investida_brutal", "name": "Investida Brutal", "school": "Fúria", "rarity": "incomum", "text": "Investida causa +60% de dano."},
		{"id": "passos_trovao", "name": "Passos de Trovão", "school": "Fúria", "rarity": "comum", "text": "Investida recarrega 40% mais rápido."},
		{"id": "escudo_espinhos", "name": "Escudo de Espinhos", "school": "Aço", "rarity": "rara", "text": "O empurrão da Muralha de Escudo causa o triplo de dano."},
		{"id": "bastiao", "name": "Bastião", "school": "Aço", "rarity": "incomum", "text": "Muralha de Escudo dura +2 segundos."},
		{"id": "pele_ferro", "name": "Pele de Ferro", "school": "Aço", "rarity": "comum", "text": "+50 de vida máxima."},
		{"id": "furia_berserker", "name": "Fúria Berserker", "school": "Fúria", "rarity": "mítica", "text": "+40% de dano enquanto estiver abaixo de 50% de vida."},
		{"id": "vigor", "name": "Vigor", "school": "Fúria", "rarity": "comum", "text": "+15% de velocidade de movimento."},
	],
}

const HUNTER := {
	"hero": {"race": "elfo", "sex": "f"}, "hero_desc": "Arqueira do gelo de capa longa. Luta à distância com o arco ao lado do seu urso espiritual.",
	"name": "Caçador", "color": Color(0.3, 0.5, 0.25), "hp": 110.0, "weapon": "bow",
	"model": "knight", "tint": Color(0.72, 0.95, 0.68), "icon": "class_cacador",
	"resource": "foco", "costs": {"basic": 0, "a1": 35, "a2": 25},
	"anims": {"basic": "attack_bow", "a1": "attack_cast", "a2": "roll"},
	"desc": "Arqueira com um urso espiritual que luta junto.", "pet": "Urso Espiritual",
	"abilities": {
		"basic": {"name": "Flecha", "icon": "arrow", "key": "LMB", "cooldown": 0.4, "unlock": 1},
		"a1": {"name": "Chuva de Flechas", "icon": "arrow_rain", "key": "1", "cooldown": 7.0, "unlock": 2},
		"a2": {"name": "Salto Evasivo", "icon": "leap", "key": "2", "cooldown": 6.0, "unlock": 4},
	},
	"deck": [
		{"id": "ponta_aco", "name": "Ponta de Aço", "school": "Natureza", "rarity": "comum", "text": "Flecha causa +35% de dano."},
		{"id": "tiro_triplo", "name": "Tiro Triplo", "school": "Natureza", "rarity": "rara", "text": "Flecha dispara 3 flechas em leque."},
		{"id": "flecha_perfurante", "name": "Flecha Perfurante", "school": "Natureza", "rarity": "rara", "text": "Flechas atravessam os inimigos."},
		{"id": "chuva_intensa", "name": "Chuva Intensa", "school": "Natureza", "rarity": "incomum", "text": "Chuva de Flechas tem +40% de raio."},
		{"id": "aljava_rapida", "name": "Aljava Rápida", "school": "Natureza", "rarity": "comum", "text": "Chuva de Flechas recarrega 40% mais rápido."},
		{"id": "instinto_feral", "name": "Instinto Feral", "school": "Natureza", "rarity": "incomum", "text": "Seu animal causa +60% de dano."},
		{"id": "matilha", "name": "Chamado da Matilha", "school": "Natureza", "rarity": "mítica", "text": "Um segundo animal se junta a você."},
		{"id": "passo_leve", "name": "Passo Leve", "school": "Natureza", "rarity": "comum", "text": "Salto Evasivo recarrega 45% mais rápido."},
		{"id": "olhos_aguia", "name": "Olhos de Águia", "school": "Natureza", "rarity": "incomum", "text": "Flechas voam 40% mais rápido e mais longe."},
		{"id": "vigor_selvagem", "name": "Vigor Selvagem", "school": "Natureza", "rarity": "comum", "text": "+40 de vida máxima."},
	],
}

const WARLOCK := {
	"hero": {"race": "orc", "sex": "m"}, "hero_desc": "Senhor cósmico com uma foice. Invoca espíritos do vazio e suga a alma dos inimigos.",
	"name": "Bruxo", "color": Color(0.35, 0.15, 0.45), "hp": 105.0, "weapon": "orb",
	"model": "darkelf", "tint": Color(0.85, 0.62, 1.0), "icon": "class_bruxo",
	"resource": "mana", "costs": {"basic": 0, "a1": 30, "a2": 25},
	"anims": {"basic": "attack_cast", "a1": "interact", "a2": "attack_2h"},
	"desc": "Magia das trevas: invoca um espírito que luta por você e suga a vida dos inimigos.",
	"abilities": {
		"basic": {"name": "Raio Sombrio", "icon": "shadow_bolt", "key": "LMB", "cooldown": 0.5, "unlock": 1},
		"a1": {"name": "Invocar Espírito", "icon": "spirit", "key": "1", "cooldown": 18.0, "unlock": 2},
		"a2": {"name": "Sugar Alma", "icon": "soul_drain", "key": "2", "cooldown": 8.0, "unlock": 4},
	},
	"deck": [
		{"id": "sombra_densa", "name": "Sombra Densa", "school": "Sombra", "rarity": "comum", "text": "Raio Sombrio causa +35% de dano."},
		{"id": "rajada_sombria", "name": "Rajada Sombria", "school": "Sombra", "rarity": "rara", "text": "Raio Sombrio dispara 3 raios em leque."},
		{"id": "explosao_sombria", "name": "Explosão Sombria", "school": "Sombra", "rarity": "rara", "text": "Raio Sombrio explode ao acertar, causando dano em área."},
		{"id": "espirito_ancestral", "name": "Espírito Ancestral", "school": "Almas", "rarity": "comum", "text": "O espírito fica +10 segundos."},
		{"id": "legiao", "name": "Legião", "school": "Almas", "rarity": "mítica", "text": "Invocar Espírito chama 2 espíritos."},
		{"id": "furia_espectral", "name": "Fúria Espectral", "school": "Almas", "rarity": "incomum", "text": "Espíritos causam +60% de dano."},
		{"id": "fome_almas", "name": "Fome de Almas", "school": "Almas", "rarity": "incomum", "text": "Sugar Alma cura 100% do dano causado (em vez de 50%)."},
		{"id": "colheita", "name": "Colheita", "school": "Almas", "rarity": "incomum", "text": "Sugar Alma tem +40% de raio."},
		{"id": "pacto_sombrio", "name": "Pacto Sombrio", "school": "Sombra", "rarity": "comum", "text": "Sugar Alma recarrega 40% mais rápido."},
		{"id": "carapaca_ossos", "name": "Carapaça de Ossos", "school": "Sombra", "rarity": "comum", "text": "+40 de vida máxima."},
	],
}

const CLASS_ORDER := ["guerreiro", "mago", "cacador", "bruxo"]

## Recursos (como no MMORPG clássico): mana regenera, fúria vem de bater/apanhar e cai fora de combate,
## foco regenera rápido.
const RESOURCES := {
	"mana": {"name": "Mana", "color": Color(0.15, 0.35, 0.95), "max": 100.0, "regen": 5.0, "start": 100.0},
	"furia": {"name": "Fúria", "color": Color(0.85, 0.12, 0.1), "max": 100.0, "regen": -2.0, "start": 0.0},
	"foco": {"name": "Foco", "color": Color(0.95, 0.75, 0.15), "max": 100.0, "regen": 10.0, "start": 100.0},
}
const RACE_ORDER := ["humano", "anao", "elfo", "orc"]


static func for_class(id: String) -> Dictionary:
	match id:
		"guerreiro":
			return WARRIOR
		"cacador":
			return HUNTER
		"bruxo":
			return WARLOCK
		_:
			return MAGE


## Cada classe é um herói fixo: a "raça" e o corpo vêm do herói (não se escolhe mais raça).
static func hero(class_id: String) -> Dictionary:
	return for_class(class_id).get("hero", {"race": "humano", "sex": "m"})


static func race(id: String) -> Dictionary:
	return RACES.get(id, RACES["humano"])
