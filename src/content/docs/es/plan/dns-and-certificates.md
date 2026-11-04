---
title: Plan de DNS y certificados
description: Cómo obtienen los nombres privados certificados HTTPS de confianza sin exponerse a internet.
---

:::note[Traducción asistida por IA]
Esta página es una traducción asistida por IA del original en inglés, que es la referencia. Si
ves un error, abre un issue o un PR.
:::

## La idea en un párrafo

Tienes un dominio público (`example.com`) cuyo DNS está alojado en un proveedor con API. Tus
servicios usan nombres **privados** dentro de él (`*.lab.home.example.com`), que solo resuelve tu
servidor DNS interno, hacia la IP local de tu máquina. Para demostrar a Let's Encrypt que
controlas esos nombres, cert-manager crea durante un momento un registro TXT en la zona
**pública** mediante la API del proveedor (el reto DNS-01). Let's Encrypt nunca se conecta a tu
red.

## Qué necesitas

| Elemento | Ejemplo | Para qué |
|---|---|---|
| Un dominio registrado | `example.com` | Let's Encrypt solo emite certificados para dominios públicos reales |
| DNS alojado en un proveedor con API | Cloudflare, entre muchos otros | cert-manager crea el registro del reto automáticamente |
| Un token de API limitado a editar el DNS de esa zona | guardado en el gestor de secretos | Mínimo privilegio: no puede tocar nada más |
| Un servidor DNS interno | tu router, Pi-hole, bind9, AdGuard… en `192.168.10.53` | Resuelve los nombres privados en tu red local |

## Plan de nombres

- Elige **un subdominio privado** para todo lo que sirva el clúster, por ejemplo
  `lab.home.example.com`.
- Añade **un registro comodín** en tu DNS interno: `*.lab.home.example.com → 192.168.10.50`.
- Pide **un certificado comodín** para `*.lab.home.example.com`.

Así, un servicio nuevo no necesita ni cambios de DNS ni un certificado nuevo. Basta con elegir un
nombre bajo el comodín.

:::tip[No metas nombres de máquinas en las URLs]
Nombra los servicios por **lo que son** (`guide.lab.home.example.com`), no por **dónde se
ejecutan** (`app.server-2.home.example.com`). Así, mover un servicio a otra máquina no rompe
marcadores, URLs de redirección del inicio de sesión único ni certificados.
:::

## DNS de horizonte dividido, en breve

Los nombres privados existen **solo** en tu DNS interno. El DNS público no sabe nada de ellos,
salvo por los registros TXT de corta duración de los retos. Si más adelante publicas una
aplicación, tendrá un nombre **público** (por ejemplo `app.example.com`) servido a través de un
túnel. Eso es el capítulo 9.

## Opcional: empezar con un dominio nuevo

Si aún no tienes dominio, o quieres uno limpio para el laboratorio, un capítulo extra cubrirá:
comprarlo, apuntar sus servidores de nombres a un proveedor de DNS con API, crear el token de API
con permisos limitados y comprobar que todo funciona antes del capítulo 5.

## Antes del capítulo 1, decide

- [ ] Tu dominio y tu proveedor de DNS.
- [ ] El subdominio privado (por ejemplo `lab.home.example.com`).
- [ ] Dónde se ejecuta tu DNS interno y si admite registros comodín.
