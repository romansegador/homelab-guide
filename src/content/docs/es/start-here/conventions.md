---
title: Convenciones
description: Valores de ejemplo, formato de los comandos y cómo se muestran los secretos en esta guía.
---

:::note[Traducción asistida por IA]
Esta página es una traducción asistida por IA del original en inglés, que es la referencia. Si
ves un error, abre un issue o un PR.
:::

## Valores de ejemplo

La guía nunca usa el entorno real de nadie. Sustituye estos valores por los tuyos:

| Valor de ejemplo | Significado |
|---|---|
| `example.com` | Tu dominio público (registrado, con el DNS en un proveedor que tenga API) |
| `home.example.com` | El subdominio privado para los servicios internos |
| `*.lab.home.example.com` | Los nombres que sirve el clúster (por ejemplo `guide.lab.home.example.com`) |
| `192.168.10.0/24` | Tu red local |
| `192.168.10.1` | Tu router |
| `192.168.10.53` | Tu servidor DNS interno |
| `192.168.10.50` | La máquina del clúster |
| `<YOUR_GITHUB_USER>` | Tu usuario u organización de GitHub |
| `<YOUR_…>` | Cualquier otro valor que elijas o que sea propio de tu entorno |

## Comandos

- `$` indica un comando que ejecutas en tu **portátil**. `server$` indica uno que ejecutas **en
  la máquina** por SSH.
- Los comandos largos se parten con `\`, así que puedes pegarlos tal cual.
- Cada comando que cambia algo va seguido de una forma de **comprobar** que ha funcionado.

## Secretos

Los valores secretos nunca aparecen en texto plano en esta guía, en sus ejemplos ni en tus
repositorios git. Cuando un paso necesita uno, la guía muestra **dónde** va el valor y cómo se
referencia, por ejemplo:

```yaml
# The value lives in the secrets manager under this key, never in git.
remoteRef:
  key: cloudflare-dns-api-token
```

## Versiones

Cada capítulo indica las versiones exactas con las que se probó. Las versiones más nuevas suelen
funcionar. Cuando se sabe que una actualización cambia el comportamiento, el capítulo lo indica.
