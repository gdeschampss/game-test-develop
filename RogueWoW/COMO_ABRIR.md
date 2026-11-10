# Como abrir e jogar o protótipo

1. Baixe o **Godot 4** (versão Standard, 4.5 ou mais nova) em https://godotengine.org/download
2. Descompacte este zip numa pasta (ex.: `Documentos/RogueWoW`).
3. Abra o Godot → **Importar** → selecione o arquivo `project.godot` desta pasta → **Importar e Editar**.
4. Aperte **F5** (ou o ▶ no canto superior direito) para jogar.

## Controles
| Tecla | Ação |
|---|---|
| WASD | andar |
| Espaço | pular |
| Botão direito (segurar) | girar a câmera e o personagem (igual WoW) |
| TAB | travar o mouse (modo action, sem segurar o botão direito) |
| Scroll | zoom |
| Botão esquerdo | ataque básico da classe |
| 1 | 2ª habilidade (destrava no nível 2) |
| 2 | 3ª habilidade (destrava no nível 4) |
| F | invocar/desmontar o cavalo (fique parado 1,5 s) |
| Q | beber poção de vida |
| E | interagir (NPC, baú, portal) |
| I | personagem (equipamento, atributos, cartas) |
| U | mochila |
| ESC | menu (continuar, controles, trocar de personagem, sair) |
| Esc | fechar painel |

## O que testar
- O jogo abre na **tela de personagens**: crie até 4 (nome, raça e classe) e clique em **Entrar no mundo**. Na cidade, a **Pedra do Destino** volta para essa tela.
- Teste as 4 classes: **Guerreiro** (espada e escudo), **Mago**, **Caçador** (arco + animal da raça) e **Bruxo** (espírito + Sugar Alma).
- **I** abre o personagem (equipamento dos lados, o boneco em 3D girando, atributos e a aba **Cartas**). **U** abre a mochila em grade. Na cidade, clique numa peça da mochila para equipar e num espaço do personagem para tirar. Passe o mouse para ver a dica do item.
- **ESC** abre o menu (e fecha qualquer janela aberta).
- O **minimapa** (canto superior direito) mostra missões (! e ?), portais, baús, bosses e a masmorra.
- Na cidade, fale com o **Mestre dos Portais** e escolha uma dificuldade (as mais altas pedem Poder de Armadura).
- No mapa você começa só com a Bola de Fogo. A Nova de Gelo destrava no nível 2 e o Piscar no 4.
- Mobs dropam **XP** (orbe verde), **ouro** (moeda) e às vezes **materiais** (cubo roxo).
- Nos níveis **3** e **6** aparecem as **cartas** do seu deck, embaralhadas: escolha 2 e depois 1.
- **10 NPCs** com "!" dão missões. "?" em cima do NPC = missão pronta para entregar.
- **3 bosses**, um em cada bioma (Alfa da Matilha, Rei do Lodo, Yeti Ancião). Chegou perto, não dá para montar; só despista fugindo para bem longe.
- **Cripta Profanada** (masmorra) no fundo dos Picos Gelados: entre com E. Lá dentro tem o Senhor da Cripta.
- **Portais verdes (PAUSA, 2 por partida):** aguente 6 s e a onda de mobs. Ouro e materiais vão para a cidade e você pode **continuar** depois, com o mapa do jeito que deixou.
- **Portal dourado (SAÍDA, perto do início):** encerra a partida guardando tudo.
- Morreu: perde o ouro e os materiais que não extraiu.
- Na cidade: **Ferreiro** forja armaduras com os materiais (sobe o Poder de Armadura), **Loja** vende poções (tecla Q), **Baú pessoal** mostra tudo o que você tem.


## Cena de demonstração do visual
Na tela de seleção de personagem, escolha um personagem e clique em **Cena de demonstração (visual)**.
É uma clareira pequena com o novo estilo (chão pintado, céu, árvores, casa, bandidos e uma missão). Nada lá é salvo.
