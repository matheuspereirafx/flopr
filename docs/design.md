---
name: Flopr
colors:
  surface: '#131314'
  surface-dim: '#131314'
  surface-bright: '#3a393a'
  surface-container-lowest: '#0e0e0f'
  surface-container-low: '#1c1b1c'
  surface-container: '#201f20'
  surface-container-high: '#2a2a2b'
  surface-container-highest: '#353435'
  on-surface: '#e5e1e3'
  on-surface-variant: '#c9c4d3'
  inverse-surface: '#e5e1e3'
  inverse-on-surface: '#313031'
  outline: '#928f9c'
  outline-variant: '#474551'
  surface-tint: '#c7bfff'
  primary: '#c7bfff'
  on-primary: '#2e2176'
  primary-container: '#52489c'
  on-primary-container: '#c9c1ff'
  inverse-primary: '#5d53a7'
  secondary: '#ffb3b4'
  on-secondary: '#680017'
  secondary-container: '#940a28'
  on-secondary-container: '#ff9da1'
  tertiary: '#c6c6cb'
  on-tertiary: '#2f3034'
  tertiary-container: '#535458'
  on-tertiary-container: '#c9c8cd'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e4dfff'
  primary-fixed-dim: '#c7bfff'
  on-primary-fixed: '#180262'
  on-primary-fixed-variant: '#453a8e'
  secondary-fixed: '#ffdada'
  secondary-fixed-dim: '#ffb3b4'
  on-secondary-fixed: '#40000b'
  on-secondary-fixed-variant: '#900626'
  tertiary-fixed: '#e3e2e7'
  tertiary-fixed-dim: '#c6c6cb'
  on-tertiary-fixed: '#1a1b1f'
  on-tertiary-fixed-variant: '#46474b'
  background: '#131314'
  on-background: '#e5e1e3'
  surface-variant: '#353435'
typography:
  headline-xl:
    fontFamily: DM Sans
    fontSize: 72px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: DM Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.01em
  headline-md:
    fontFamily: DM Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
  body:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.4'
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 48px
  gutter: 16px
---

FLOPR DESIGN SYSTEM
Version: 1.1

PRODUCT OVERVIEW
Flopr é uma plataforma SaaS para criação e operação de torneios privados de poker home game.
O sistema permite que organizadores criem torneios, convidem jogadores, gerenciem confirmações, operem eventos ao vivo e exibam um telão profissional durante o torneio.

O produto deve transmitir:
- Sofisticação
- Controle
- Organização
- Estratégia
- Simplicidade
- Modernidade

A experiência deve lembrar produtos como:
Linear, Notion, Raycast, Stripe. NÃO deve lembrar cassinos ou casas de apostas.

DESIGN PHILOSOPHY
Seguir fortemente a filosofia visual da Linear.
Princípios:
- Espaçamento antes de decoração
- Tipografia antes de cores
- Clareza antes de personalidade
- Informação antes de efeitos visuais
- Operação rápida sob pressão

BRAND PERSONALITY
Arquétipo Principal: Strategist (Tomada de decisão, Controle)
Arquétipo Secundário: Organizer (Eficiência, Estrutura)

VISUAL DIRECTION
Minimalista, Premium, Escuro, Profissional. Utiliza muito espaço negativo e evita excesso de cores ou sombras.

COLOR SYSTEM
:root {
  --color-primary: #52489C;
  --color-accent: #EB5160;
  --color-tertiary: #F0EFF4;
  --color-background: #0A0A0C;
  --color-surface: #131316;
  --color-text-primary: #FFFBFC;
  --color-text-secondary: #A1A1AA;
  --color-border: rgba(255,255,255,0.06);
}

Primary: #52489C
Accent: #EB5160
Tertiary: #F0EFF4 (Utilizado para highlights sutis e elementos de suporte)
Background: #0A0A0C
Neutral/Text: #FFFBFC (Garante máxima legibilidade em temas escuros)

TYPOGRAPHY
Font Family: DM Sans (Headlines), Inter (Body/Labels)
- H1: DM Sans Bold, 72px
- H2: DM Sans Bold, 48px
- H3: DM Sans Bold, 32px
- Body: Inter Regular, 16px
- Small/Label: Inter Regular, 14px

SPACING SYSTEM
Base Unit: 4px
Scale: 4 8 12 16 24 32 48 64 96 128

BORDER RADIUS
O sistema utiliza um nível de arredondamento "Rounded" (Base 8px).
- Small: 4px
- Medium (Default): 8px
- Large: 16px
- Pill: 999px

SHADOWS
box-shadow: 0 4px 12px rgba(0,0,0,0.15); (Apenas para Modais e Menus flutuantes)

COMPONENTS
- Primary Button: Primary bg (#52489C), White text (#FFFBFC), 999px radius
- Secondary Button: Transparent, Border 1px, 999px radius
- Input: Surface bg, 8px radius, 48px height
- Card: Surface bg, 1px border, 16px radius

UX RULES
- Nunca exibir mais informações do que o necessário.
- Cada tela deve possuir apenas uma ação principal.
- Utilizar confirmação para ações críticas.

FEELING
"Linear dos torneios de poker." Uma ferramenta profissional de gestão.