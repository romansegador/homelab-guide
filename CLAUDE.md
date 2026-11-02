# homelab-guide

Public, multilingual Astro Starlight site: a step-by-step guide to building a small homelab
from zero to production. It's written **while** the author builds the real thing, so every
chapter has been executed for real before it's published.

## Hard rules

- **This repo is PUBLIC. Nothing from the author's real environment goes in it.** No real
  domains, hostnames, IPs, usernames, account ids, tokens, data, screenshots with real values,
  or names of private projects. Use the placeholders in `src/content/docs/start-here/conventions.md`
  (`example.com`, `home.example.com`, `192.168.10.0/24`, `<YOUR_…>`). Re-read every diff for
  leaks before committing, and check terminal output pasted into pages.
- **Never put secret values in pages or examples.** Show *where* a secret goes, never a value.
- **Tool-agnostic structure.** Chapters describe *what* you're building. Tool-specific steps
  live in clearly labelled sections or tabs (k3s first; a Docker Swarm path may come later).
  Don't bake a tool name into the site or repo name, or into chapter slugs that are about a concept.
- **PRs only.** Never push to `main`.

## Languages

- **English is the source of truth** and lives at the root of `src/content/docs/`.
- Other locales (`es/` today, more later) are **AI-assisted translations** of the English pages.
  Every translated page starts with the `:::note` translation banner (see any `es/` page).
- When an English page changes, update its translations in the same PR, or open an issue.
  Starlight shows the English page when a translation is missing.
- Keep code blocks, commands, file names and YAML identical across languages. Only prose is translated.

## Develop

```sh
npm install
npm run dev      # http://localhost:4321
npm run build    # must pass before a PR (CI runs it too)
```

The site is built as a static bundle (`dist/`) and served by an unprivileged nginx image
(`Dockerfile`). Publishing that image and deploying it is chapter 6 of the guide itself.
