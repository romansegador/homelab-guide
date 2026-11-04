---
title: Introducción
description: Qué construye esta guía, para quién es y cómo está organizada.
---

:::note[Traducción asistida por IA]
Esta página es una traducción asistida por IA del original en inglés, que es la referencia. Si
ves un error, abre un issue o un PR.
:::

Esta guía te lleva de una máquina vacía a una pequeña plataforma de producción en la que puedes
confiar para aplicaciones reales. Se escribe mientras el autor construye la suya, así que cada
paso se ha ejecutado de verdad. Cuando algo salió mal por el camino, la guía lo cuenta.

## Con qué terminarás

- **Una máquina** (física o virtual) con una distribución ligera de Kubernetes.
- **GitOps:** cada aplicación y cada pieza de configuración de la plataforma vive en un
  repositorio git, y [ArgoCD](https://argo-cd.readthedocs.io/) mantiene el clúster sincronizado
  con él.
- **Un gestor de secretos** fuera de la máquina, sincronizado con el clúster. Los secretos nunca
  están en git en texto plano y sobreviven a la pérdida de la máquina.
- **HTTPS de confianza para servicios privados**, con Let's Encrypt y validación por DNS. No hace
  falta que nada sea accesible desde internet para obtener un certificado.
- **DNS privado** para tus servicios, y un camino claro para publicar una aplicación concreta a
  través de un túnel, sin abrir puertos en el router.
- **Una base de datos Postgres** con copias de seguridad automáticas fuera de la máquina.
- **Una aplicación real de varios servicios** (web, API, proceso en segundo plano, base de datos),
  desplegada igual que todo lo demás.
- Un procedimiento de **reconstrucción desde cero** que habrás probado de verdad.

## Para quién es

Te manejas con la terminal de Linux, SSH y Docker, y quieres entender lo que ejecutas en lugar
de pulsar botones en un instalador. No se presupone experiencia previa con Kubernetes. La guía
explica cada concepto la primera vez que aparece.

## Cómo está organizada

- Los **capítulos** describen *qué* construyes y *por qué*: plan, máquina, clúster, GitOps,
  secretos, HTTPS, primera aplicación, base de datos, una aplicación real, publicación y
  operación diaria. Consulta la [hoja de ruta](/es/start-here/roadmap/).
- Los **caminos** son las herramientas concretas de cada paso. El primer camino completo es
  **k3s + ArgoCD**. La estructura deja sitio para alternativas (por ejemplo Docker Swarm) en los
  mismos pasos más adelante. Las instrucciones propias de un camino siempre están señaladas.
- Las **convenciones** sobre valores de ejemplo, comandos y secretos están en la página de
  [convenciones](/es/start-here/conventions/). Léela una vez antes de empezar.

## Una nota sobre «producción»

Aquí «producción» significa: cosas de las que dependes, que funcionan sin vigilancia y que se
pueden recuperar cuando fallan. **No** significa alta disponibilidad. Una sola máquina es un
único punto de fallo, y la guía lo dice claramente. Lo que la hace apta para producción es que
puedes reconstruirlo todo a partir de git, tu gestor de secretos y tus copias de seguridad, y que
lo has practicado.
