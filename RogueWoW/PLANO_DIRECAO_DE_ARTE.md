# Plano de direção de arte — estética MMORPG clássico (WoW Vanilla 2004–2006)
*Etapa 1 aprovada em 31/10/2026. Etapa 2 (protótipo visual) entregue na v6. Feedback recebido: "ficou PS2 demais" → ajuste de direção abaixo (Etapa 3).*
*Referência única: **WoW Vanilla**. Morrowind e LoL saíram das referências (31/10) — puxavam o visual para o lado PS2.*

## 0. Sensação que o jogo deve passar (palavras do Gabriel, 31/10)
**Jogo novo com sensação de jogo antigo**: nostalgia de MMORPG clássico, mas com mecânicas modernas e gráfico "meio antigo, meio novo" — como o WoW faz hoje com as zonas antigas (mesmo estilo de arte, tecnologia atual).

### Receita "meio antigo, meio novo"
| Fica com cara de antigo (Vanilla) | Fica com cara de atual |
|---|---|
| Estilo pintado à mão, cores saturadas e quentes, proporções exageradas (ombreiras grandes, mãos e armas grandes) | Texturas em resolução maior (512–1024 px), sem pixelado de PS1/PS2 |
| Silhuetas simples e legíveis, poucos polígonos estilizados | Luz mais rica: sombras suaves, oclusão de ambiente leve, céu com hora do dia |
| Neblina de distância colorida por zona | Bloom suave só na magia, fogo e itens raros; partículas modernas |
| Layout de interface clássico (barras, retratos, minimapa, pergaminho de missão) | Vento na grama e nas árvores, água com reflexo, animações suaves de verdade |
| Paleta por bioma bem marcada | Feedback moderno de combate (números de dano, impacto, tremor leve de câmera) |

O que deixou com cara de PS2 na v6: texturas de chão PSX de 128 px (pixeladas), modelos PSX de baixa resolução misturados com modelos de IA realistas, e luz muito chapada. As árvores do Forest Pack funcionaram bem e ficam.

## 1. Diagnóstico do projeto
- Godot 4.5, renderizador Forward+. Cenas montadas por código (GDScript), sem .tscn de conteúdo.
- Sistemas funcionando: tela de personagens, cidade, mapa com 3 biomas + masmorra, 4 classes, cartas, loot, ferreiro, mochila (U), personagem (I), menu (ESC), minimapa, missões, extração.

## 2. Assets em uso (v6)
| Pacote | Uso | Licença |
|---|---|---|
| Dwarf Melee Animations (Kevin Iglesias) | jogador, NPCs e bandidos animados (base provisória para todas as raças) | royalty-free, não revender |
| Warhorse Lite | montaria com animações | grátis p/ jogos, não redistribuir |
| 25 armas | armas nas mãos | CC0 |
| PSX Forest / PSX Snow | chão, grama, flores (a substituir por versões de maior resolução) | ❓ conferir |
| Forest Model Pack | pinheiros, abetos, tocos, troncos, samambaia (aprovado) | ❓ conferir |
| Dungeon kit (SigilsVault) | caixas, potes, braseiro; peças modulares para a cripta | CC0 |
| daysky | céu panorâmico | ❓ conferir |
| Dumivid UI | molduras, anéis, pedra, pergaminho | CC0 |
| Craftpix | ícones pintados de habilidades/equipamentos | Craftpix free |
| Binbun VFX | efeitos | CC0 |
Ainda não usados: 1_Free_Pack (ícones/HUD/status), Pack_2 (ícones de materiais), Magic Projectiles, Loot VFX, Battle/Explosion FX.
Não chegaram (reenviar): animações de humano, pacote completo de animações, pacotes de mobs.

## 3. Regras de propriedade intelectual
- Reproduzir a **linguagem visual** do WoW Vanilla é permitido; copiar o WoW "como base" foi aprovado nesse sentido.
- **Não** usar texturas/ícones/molduras extraídos do WoW, logos, nem a fonte Friz Quadrata. Fontes: Cinzel + Alegreya (OFL).

## 4. Decisões tomadas (31/10)
- Referência visual única: **WoW Vanilla** (sem Morrowind, sem LoL).
- Sem chat: o canto inferior esquerdo é um **log de eventos** (dano, loot, XP, missões, conquistas).
- **Cada bioma tem um nível** (Floresta 2–5, Pântano 5–9, Picos 8–12, Cripta 10–13). Dificuldades maiores mantêm o nível, mas os mobs ficam mais fortes.
- Recursos: **Guerreiro = fúria**, **Mago e Bruxo = mana**, **Caçador = foco**.
- Foco nos assets novos; os antigos eram para teste.
- Direção visual: "meio antigo, meio novo" (seção 0).

## 5. Execução
1. ✅ Diagnóstico e plano.
2. ✅ Protótipo visual (v6) — cena "Clareira do Bandido" (botão "Cena de demonstração" na seleção de personagem ou `--demo-scene`).
3. ▶ Ajustes artísticos: aplicar a receita da seção 0 na cena de demonstração com os próximos assets do Gabriel (texturas e modelos estilizados de maior resolução, animações de humano, mobs).
4. Padronização: hub, 3 biomas, cripta (dungeon kit modular), VFX, slots de arma.
5. Revisão: consistência, funcionalidades, importação e desempenho.

## 6. Pontos em aberto
- Orientação do cajado e do arco na mão ainda imperfeita.
- Raças diferentes ainda usam o mesmo anão escalado — aguardando animações/modelos de humano.
- Licenças marcadas ❓ precisam ser conferidas antes de publicar.
