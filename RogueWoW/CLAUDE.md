# CLAUDE.md — RogueWoW (nome provisório)

Contexto para o Claude Code. Leia antes de mexer no projeto.

## O jogo
Action RPG de extração por partidas, com visual inspirado em World of Warcraft (fantasia
medieval, estilo anos 2000, low-poly pintado à mão) e animações modernas de jogo de ação.
Não é cópia do WoW: **nunca** usar assets, nomes, personagens ou logos da Blizzard
(nem rips nem fan art do Sketchfab). Inspiração de estilo, sim; propriedade intelectual, não.

O documento de design completo (GDD) está no Projeto do Claude "Jogo WOW rogue like".
Resumo das decisões:
- Abre na **tela de personagens**: até 4 personagens, cada um com nome, **raça** (Humano, Anão, Elfo, Orc —
  provisórias) e **classe**. Cada personagem tem seu próprio ouro, materiais, equipamento, bolsa e poções;
  conquistas são da conta. Depois vai para a **cidade-hub**; o Mestre dos Portais escolhe a fase/dificuldade.
- **6 dificuldades** com multiplicadores de vida/dano dos mobs e de recompensa (`Game.DIFFICULTIES`).
- **Sem level permanente**: o nível sobe só dentro da partida (XP vem em orbes verdes dos mobs).
  A progressão permanente é o **equipamento**: o Ferreiro forja armaduras com **materiais + ouro**;
  cada peça dá **Poder de Armadura (PA)** (+2 vida e +1% dano por ponto) e o PA libera dificuldades (`min_pa`).
- **Loot**: mobs dropam XP, **ouro** e **materiais** (Pele de Lobo, Osso de Carniçal, Couro de Yeti, Fragmento
  Sombrio; bosses dropam materiais únicos). Ouro e materiais só ficam seus ao extrair; morrer perde tudo da partida.
  Dados em `Game.MATERIALS`, `Game.RECIPES`; drops nos dicionários de mob em `field.gd`.
- **Extração** (3 por mapa): 2 portais de **PAUSA** (verdes, posição sorteada) e 1 de **SAÍDA** (dourado, perto do início).
  - Pausa: guarda ouro e materiais na cidade e congela o mapa (o nó sai da árvore e fica na memória em `main.gd`);
    ao continuar, tudo volta como estava. Cada pausa deixa os mobs novos 25% mais fortes (`Game.pause_scaling()`).
  - Saída: guarda o loot e encerra a partida. Morrer perde o loot não extraído.
  - Ao começar a extrair, vem uma onda de mobs; o portal leva 6 s.
- Mapa 1 (~440 x 440 m): fixo, **3 biomas** de 220 m (Floresta Sombria, Pântano Pútrido, Picos Gelados), estradas,
  respawn rápido de mobs, guardas perto dos portais, baús, **10 NPCs com missões** (matar, coletar, boss, entregar).
- **Masmorra** "Cripta Profanada": construída em x = 1000 e acessada por teleporte na entrada dos Picos Gelados.
  Salas com esqueletos e acólitos (sem respawn) e o chefe Senhor da Cripta. Sem montaria lá dentro.
- **Bosses** (v5, com modelos): Ancião da Floresta (árvore gigante), Dragão do Pântano, Dragão da Montanha e
  Senhor da Cripta (demônio). Elite: Centauro Chama-Viva na floresta (dropa Crina Flamejante).
- **Bosses** (um por bioma + o da masmorra): chegou perto, ele trava a luta (derruba do cavalo e impede montar).
  Só reseta se o jogador ficar mais de 55 m longe do covil por 4 s. Cada um dá uma conquista.
- **Cidade**: Mestre dos Portais (dificuldades por PA / continuar partida), Loja (poções, tecla Q),
  Ferreiro (receitas), Baú pessoal (inventário), Mestra de Cartas (placeholder).
- **Cartas**: cada classe tem um deck padrão de **10 cartas**. Nos níveis 3 e 6 da partida o deck é embaralhado:
  mostra 4 e escolhe 2, depois mostra 3 e escolhe 1. As outras ficam de fora até a próxima partida
  (`ClassData.CARD_ROUNDS`, efeitos em `Player.apply_card`).
- **Habilidades** destravam por nível na partida (Mago: Bola de Fogo nv 1, Nova de Gelo nv 2, Piscar nv 4).
- **Habilidades por clique/tecla** (não automáticas). Câmera estilo WoW (botão direito gira; TAB trava o mouse).
- **Classes** (todas jogáveis, dados em `ClassData`, habilidades em `Player.try_ability`):
  Guerreiro (espada e escudo: Golpe, Investida, Muralha de Escudo), Mago (Bola de Fogo, Nova de Gelo, Piscar),
  Caçador (só arco: Flecha, Chuva de Flechas, Salto Evasivo + **animal da raça** como pet permanente),
  Bruxo (Raio Sombrio, Invocar Espírito, Sugar Alma). Aliados em `scripts/player/ally.gd` (MVP: não tomam dano).
- **Interface estilo WoW**: vida, XP e barra de ações embaixo; minimapa (missões, portais, bosses) em cima à direita;
  inventário na tecla I (equipar/desequipar só na cidade).
- **Montaria**: cavalo; 1,5 s parado para montar; montado não ataca; tomar dano derruba.
- Monetização: grátis ou barato; nunca loot box nem item aleatório pago (ECA Digital).

## Visual (v5)
- Modelos 3D em `assets/models/*.glb` carregados por `Models.instance(id, altura, tint)` (`scripts/core/models.gd`):
  ajusta tamanho, apoia no chão e vira para -Z. Sem o arquivo, cai no boneco cinza.
- A maioria dos modelos é estática: `ProcAnim` (`scripts/core/proc_anim.gd`) faz respiração, balanço ao andar,
  investida no ataque e tranco ao tomar dano. O dragão da montanha tem animação própria (AnimationPlayer em loop).
- Pipeline de modelos novos: FBX → importar no Godot → exportar GLB (GLTFDocument) → `gltfpack -noq -si <razão>`
  → reduzir texturas (script `shrink_glb.py`: só cor + normal, 1024 px, zera emissão). Mantenha < 60 mil triângulos.
- Ícones gerados por código em `assets/icons/` (habilidades, itens, classes). Efeitos em `FX` (`scripts/combat/fx.gd`):
  partículas CPU, números de dano, coluna de luz.
- Tema da interface: `UITheme.build()` gera `assets/ui_theme.tres` (definido em project.godot). **Se mudar o
  ui_theme.gd, gere o .tres de novo** (rodar um script com `ResourceSaver.save(UITheme.build(), ...)`).
- Janelas: ESC = `GameMenu`, U = `BagUI` (mochila em grade), I = `CharacterUI` (equipamento + personagem 3D + aba de cartas).
  Toda janela fica no grupo `ui_window` com `is_open()`/`close()`; `UIWin.sync_lock` trava o jogador.
- Cartas desenhadas por `CardView` (moldura própria; não copiar moldura/símbolos do Magic).
- Licenças dos modelos: ver `CREDITOS_E_LICENCAS.md` (todas a conferir antes de publicar).

## Stack
- Godot 4.5+ (GDScript), renderer Forward+.
- Tudo do protótipo é montado **por código** com formas cinza (`Build`), para depois trocar por cenas .glb.

## Estrutura
```
scenes/main.tscn            cena raiz (troca hub <-> mapa)
scripts/core/game.gd        autoload "Game": dificuldades, save (user://save.json), controles, avisos
scripts/core/main.gd        troca de cenas
scripts/cards/class_data.gd raças, classes, habilidades, níveis de destrave, rodadas e deck de 10 cartas por classe
scripts/player/ally.gd      pet do Caçador e espírito do Bruxo
scripts/world/menu.gd       tela de personagens (criar, escolher, apagar)
scripts/ui/minimap.gd       minimapa desenhado em 2D
scripts/ui/bag_ui.gd        mochila (U)
scripts/ui/character_ui.gd  personagem (I) com prévia 3D e aba de cartas
scripts/ui/game_menu.gd     menu do ESC
scripts/ui/card_view.gd     desenho das cartas
scripts/ui/tooltip.gd       dica que segue o mouse (Game.tooltip)
scripts/ui/ui_theme.gd      tema visual (gera assets/ui_theme.tres)
scripts/core/models.gd      carregar modelos 3D
scripts/core/proc_anim.gd   animação procedural
scripts/combat/fx.gd        partículas e números flutuantes
scripts/world/npc_look.gd   visual dos NPCs
scripts/ui/card_picker.gd   tela de escolha de cartas (pausa o jogo)
scripts/world/build.gd      atalhos para montar o cenário placeholder
scripts/world/hub.gd        cidade-hub + painel de dificuldade
scripts/world/field.gd      mapa 1: biomas, spawn, baús, NPCs, boss, extração, teste automático
scripts/world/interactable.gd  qualquer coisa que se usa com E
scripts/player/player.gd    jogador: câmera, movimento, habilidades, cavalo, vida/XP/mana
scripts/enemies/enemy.gd    mob genérico (dados vêm do bioma)
scripts/combat/projectile.gd
scripts/pickups/pickup.gd  orbe de XP, moeda de ouro ou material no chão
scripts/ui/hud.gd           interface
assets/                     modelos, animações, texturas, áudio
```

## Convenções
- Código e comentários em português; nomes de variáveis/funções em inglês.
- Dados de jogo (mobs, dificuldades, habilidades) ficam em dicionários/constantes no topo dos scripts.
  Quando crescerem, migrar para `Resource` (.tres).
- O save é **um arquivo único** com campo `version`, pensado para migrar depois para Steam Cloud.
- Teste automático do loop inteiro (hub → mapa → combate → baú → extração → hub):
  `godot --headless --path . --fixed-fps 60 --quit-after 3000 -- --smoke`
  Testa cartas, cavalo, missões, masmorra, boss (trava e reset), pausa, retomada, saída, ferreiro, loja e inventário.
  Rode para cada classe: `-- --smoke --class=guerreiro|mago|cacador|bruxo --race=humano|anao|elfo|orc`. Precisa terminar em `SMOKE hub ok`. Rode depois de qualquer mudança grande.
- Print de tela para conferir o visual: `godot --path . -- --shot /caminho/print.png` (use `--hub` ou `--field` com `--class=` / `--race=`, `--demo-cards`, `--demo-smith`, `--demo-char`,
  `--demo-at=Nome do Boss`, e `--models` [--only=id] para ver os modelos; esses modos não gravam o save).
- Cena de demonstração da direção de arte (Etapa 2): `scripts/world/demo.gd` — `--demo-scene` [`--demo-view=camp|house`, `--demo-ui`]
  ou botão "Cena de demonstração" na seleção de personagem (Game.start_demo faz backup e restaura ao sair; nada é salvo).
- Estilo clássico: `Build.classic_environment` (céu panorâmico, neblina colorida, sem bloom/SSAO), `Build.textured_ground`/`ground_patch`
  (texturas PSX com tiling), `Build.scatter_model` (grama/flores em MultiMesh), `Build.prop` (fit_longest para troncos deitados).
  Models.instance deixa todo material fosco (sem metal/especular). Game.icon usa `assets/icons/craftpix/<nome>.png` antes dos gerados.

## Próximos passos (roadmap)
1. ✅ Protótipo cinza (este).
2. ✅ Classes, raças, tela de personagens, inventário, interface estilo WoW.
3. Itens: drops, inventário, Poder de Armadura, stash no hub, perda ao morrer.
4. Mapa 1 completo: 10+ NPCs com missões, masmorra, mais bosses, conquistas.
5. Arte e animação: personagem modular, armaduras, cavalo, cenário.
6. Hub completo, 4 slots de personagem.
7. Polimento e lançamento no itch.io.

## v7 — personagens, mobs e interface
- CharacterRig: famílias "dwarf" (anão Kevin Iglesias), "human" (Quaternius: roupa Ranger/Peasant + rosto/cabelo do Universal Base Characters + animações UAL, mesmo esqueleto),
  "humanoid" (esqueleto AccuRig retargetado no import com map_cc.tres + fix_silhouette) e "creature" (Monster04, animações próprias renomeadas).
  CharacterRig.for_character(classe, raça, sexo) monta o personagem; anão usa o anão, as outras raças o humano (rig_scale por raça, orelhas/presas).
- Armas: Models.weapon(id, comprimento, grip, flip) alinha pelo eixo comprido (PCA); GRIP/WEAPON_FIX em character_rig.gd giram na mão.
  Conferir com godot --path . res://tools/rigtest.tscn (fila de personagens) e res://tools/griptest.tscn.
- Interface: texturas em assets/ui/hud_* geradas por tools/gen_ui.py; depois de mudar ui_theme.gd rode tools/bake_theme.gd.
- Props: assets/models/props/*.gltf (Models aceita .glb e .gltf). Chão pintado: assets/textures/ground_hp.

## v8 — heróis (uso pessoal)
- Cada classe é um herói fixo (ClassData.<CLASSE>["hero"], CharacterRig.HEROES). Não há mais escolha de raça/corpo no menu; Game.race/sex vêm do herói.
- Heróis com esqueleto próprio são retargetados NO IMPORT para o perfil humanoide: assets/characters/heroes/<x>/map.tres (gerados por tools/make_bonemaps.gd)
  + "retarget/bone_map" e fix_silhouette no .import; animações = heroes/hero_anims.res (UAL retargetada em /home/claude/conv4).
- Guerreiro (King Varian) era .obj estático: pesos transferidos do manequim UAL (conv3/vdump.gd -> vweights (python) -> vbuild.gd). Família "human" plain.
- Mobs: lobo (wolf.fbx, anims próprias), carniçal (monster04), esqueleto (retarget), diabrete/puglin (bestiário Quaternius, esqueleto UAL).
- Animal do Caçador = urso (pet_bear); espíritos do Bruxo = Enigma (spirit). VFX prontos: FX.vfx(parent, id, pos, escala, vida, direção).

## v9 — mapa com o visual da demo
- Village.build_house(w, d, andares, estilo) monta casas com o Medieval Village MegaKit (peças de 2 m em assets/models/village). Usado na vila de partida (field._build_start_village) e na cidade.
- field._build_decorations usa TREES/SMALL por bioma (pacotes Forest/PSX/Snow) + grama em MultiMesh; _build_rocks com pedras dos pacotes.
- Mobs: aggro 18 m, aggro social (10 m), perambulam perto de casa, desistem a 50 m e voltam curando; grupos de 2–4; renascem após RESPAWN_TIME (25–40 s).
- Habilidades: clipes por habilidade em ClassData.anims, brilho na mão, tremor de câmera (Player.shake), efeitos Binbun maiores.
