# Como colocar assets no projeto

O Godot importa sozinho tudo o que você colocar dentro da pasta do projeto. Basta copiar os
arquivos para a pasta certa com o Godot aberto; ele detecta e importa.

## Onde colocar
| Tipo | Pasta | Formatos |
|---|---|---|
| Modelos 3D (personagens, armaduras, árvores, prédios) | `assets/models/` | **.glb** (melhor), .gltf, .fbx, .blend* |
| Animações | `assets/animations/` | .fbx (Mixamo), .glb |
| Texturas | `assets/textures/` | .png |
| Sons e música | `assets/audio/` | .ogg (música), .wav (efeitos) |

*`.blend` funciona se o Blender estiver instalado e configurado no Godot (Editor → Configurações → Importação → Blender). Na dúvida, exporte do Blender como .glb.

Use uma subpasta por pacote (ex.: `assets/models/kaykit_adventurers/`) e **guarde junto o arquivo de licença** do pacote.

## Checklist de licença (antes de copiar qualquer coisa)
- ✅ CC0, CC-BY (dar crédito) ou licença comercial do pacote comprado.
- ❌ Nada extraído do WoW e nada que retrate personagem, arma ou armadura da Blizzard, mesmo que o site diga "free download".

## Animações do Mixamo no Godot
1. No Mixamo, baixe em **FBX**, *With Skin* para o primeiro arquivo (personagem) e *Without Skin* para as outras animações.
2. Copie para `assets/animations/`.
3. Dê **duplo clique** no arquivo dentro do Godot → janela *Advanced Import*.
4. Selecione o nó **Skeleton3D** → em *Retarget*, crie um **BoneMap** com perfil **SkeletonProfileHumanoid**. Assim a mesma animação serve para todos os personagens humanoides.
5. Em *Animation*, marque **Loop** nas animações de andar, correr e parado.
6. Clique em **Reimportar**.

Depois disso, me avise quais arquivos colocou (ou deixe o Claude Code ver a pasta) que a gente liga o modelo ao jogador no lugar da cápsula.
