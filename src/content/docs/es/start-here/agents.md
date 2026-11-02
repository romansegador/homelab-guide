---
title: Usar con un agente de IA
description: Deja que un agente de IA te guíe por cada capítulo con las skills de la guía.
---

:::note[Traducción asistida por IA]
Esta página es una traducción asistida por IA del original en inglés, que es la referencia. Si
ves un error, abre un issue o un PR.
:::

Cada capítulo incluye una **skill para agentes**: instrucciones que sigue un agente de IA para
guiarte en ese capítulo. Indica qué preguntarte primero, qué pasos ejecutar, cómo comprobar cada
uno y dónde parar a preguntar antes de hacer algo arriesgado.

Las skills siguen dos reglas: **el agente nunca maneja tus valores secretos** (los escribes tú) y
**nunca crea, cambia ni borra infraestructura sin tu permiso explícito**.

## Claude Code

El repositorio de la guía es un marketplace de plugins de Claude Code. Añádelo e instala el plugin:

```sh
$ claude plugin marketplace add romansegador/homelab-guide
$ claude plugin install homelab-guide@homelab-guide
```

Después, en una sesión, ejecuta la skill de un capítulo, por ejemplo `/homelab-guide:plan` o
`/homelab-guide:machine`, o simplemente di «ayúdame con el capítulo 1 de la guía homelab».

## Otros agentes

Las skills usan el formato abierto **Agent Skills**: una carpeta con un `SKILL.md`. Copia la carpeta
del capítulo desde [`skills/`](https://github.com/romansegador/homelab-guide/tree/main/skills) al
directorio de skills de tu agente (consulta su documentación).

## Cualquier agente, sin configurar nada

La web publica versiones de toda la guía pensadas para máquinas:

- [`/llms.txt`](/llms.txt): un índice de la guía, para agentes.
- [`/llms-full.txt`](/llms-full.txt): el texto completo de todas las páginas en un solo fichero.

Pasa a tu agente una de esas URLs y pídele que te guíe por un capítulo.

## Skills por capítulo

| Capítulo | Skill |
|---|---|
| 0 · Plan | `plan` |
| 1 · La máquina | `machine` |
