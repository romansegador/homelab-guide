# Homelab Guide

From zero to production on your own server: a step-by-step, multilingual guide to a small,
GitOps-driven homelab.

It's written while the author builds their own setup, so each chapter has been run for real
before it's published.

**What you'll build:**
- one machine running a lightweight Kubernetes (k3s),
- everything deployed from git with ArgoCD,
- secrets kept off-box in a secrets manager,
- real HTTPS certificates for private hostnames,
- a Postgres database with off-site backups,
- a multi-service app, published to the internet through a tunnel.

The structure is tool-agnostic, so other paths (for example Docker Swarm) can be added for the same steps.

- **Languages:** English (source), Español (AI-assisted). More to come.
- **Status:** chapters 0 to 9 tested on real hardware. See the roadmap page in the site.

## Run locally

```sh
npm install
npm run dev
```

Then open http://localhost:4321.

## Contributing

Issues and PRs are welcome, especially corrections to translations. English is the source text.
Translated pages follow it.

## License

MIT, see [LICENSE](LICENSE).
