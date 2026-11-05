---
title: Use with an AI agent
description: Let an AI coding agent walk you through each chapter, using the guide's skills.
---

Every chapter comes with an **agent skill**: instructions an AI agent follows to guide you through
that chapter. It says what to ask you first, which steps to run, how to check each one, and where
to stop and ask before doing anything risky.

The skills follow two rules: **the agent never handles your secret values** (you type those yourself),
and **it never creates, changes or deletes infrastructure without your explicit OK**.

## Claude Code

The guide's repository is a Claude Code plugin marketplace. Add it and install the plugin:

```sh title="Laptop"
claude plugin marketplace add romansegador/homelab-guide
claude plugin install homelab-guide@homelab-guide
```

Then, in a session, run a chapter's skill, for example `/homelab-guide:plan` or
`/homelab-guide:machine`, or just say "help me with chapter 1 of the homelab guide".

## Other agents

The skills use the open **Agent Skills** format: a folder with a `SKILL.md`. Copy the chapter's
folder from [`skills/`](https://github.com/romansegador/homelab-guide/tree/main/skills) into
your agent's skills directory (see its documentation).

## Any agent, with no setup

The site publishes machine-readable versions of the whole guide:

- [`/llms.txt`](/llms.txt): an index of the guide, for agents.
- [`/llms-full.txt`](/llms-full.txt): the full text of every page in one file.

Give your agent one of those URLs and ask it to guide you through a chapter.

## Skills by chapter

| Chapter | Skill |
|---|---|
| 0 · Plan | `plan` |
| 1 · The machine | `machine` |
| 2 · The cluster | `cluster` |
