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

## How a chapter is made

1. **Before writing**, ask Roman how to approach it: options and a recommendation (for example the
   web UI vs OpenTofu for the VM). Several options can become tabs (`<Tabs syncKey=…>`).
2. Write the page(s) in **English and every existing locale**, the chapter's **agent skill**
   (`skills/<concept>/SKILL.md`) and any **example code** (`examples/NN-<chapter>/`, validated:
   `tofu validate`, `kubectl --dry-run`, etc.).
3. **Record the reasoning** behind every tool or approach choice in the FAQ
   (`start-here/faq.md`, under the chapter's heading): why this option, which alternatives were
   considered and why not, and when a reader might pick differently.
4. Roman reads it at http://localhost:4321 (`npm run dev`), follows it on the real machine and gives
   feedback. Refine, and only then mark it ✅ on the roadmap.

Command blocks must be copy-paste clean (see `start-here/conventions`): no `$` or `server$`
prompts, a `title` saying where to run it (`Laptop`, `Proxmox host`, `The machine`), no output
mixed in, and no `#` comments (zsh on macOS doesn't ignore them when pasted).

Skills: named after the concept (`plan`, `machine`, `cluster`…), not the tool. They must tell the
agent to never handle secret values and to get explicit approval before creating, changing or deleting
infrastructure. Keep the table on `start-here/agents` and the plugin in sync (`claude plugin validate .`).

## Languages

- **English is the source of truth** and lives at the root of `src/content/docs/`.
- Other locales (`es/` today, more later) are **AI-assisted translations** of the English pages.
  Every translated page starts with the `:::note` translation banner (see any `es/` page).
- When an English page changes, update its translations in the same PR, or open an issue.
  Starlight shows the English page when a translation is missing.
- Keep code blocks, commands, file names and YAML identical across languages. Only prose is translated.
  Code block **titles** (where to run it) are prose and are translated: Laptop / Portátil,
  Proxmox host / Host de Proxmox, The machine / La máquina.

## Develop

```sh
npm install
npm run dev      # http://localhost:4321
npm run build    # must pass before a PR (CI runs it too)
```

The site is built as a static bundle (`dist/`) and served by an unprivileged nginx image
(`Dockerfile`). Publishing that image and deploying it is chapter 6 of the guide itself.
