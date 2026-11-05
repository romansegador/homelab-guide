// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightLlmsTxt from 'starlight-llms-txt';

// https://starlight.astro.build/reference/configuration/
export default defineConfig({
	// Public URL of the site. Set SITE_URL when building for a real deployment.
	site: process.env.SITE_URL ?? 'http://localhost:4321',
	integrations: [
		starlight({
			title: 'Homelab Guide',
			description:
				'From zero to production on your own server: a step-by-step guide to a small, GitOps-driven homelab.',
			social: [
				{ icon: 'github', label: 'GitHub', href: 'https://github.com/romansegador/homelab-guide' },
			],
			editLink: { baseUrl: 'https://github.com/romansegador/homelab-guide/edit/main/' },
			lastUpdated: true,
			// /llms.txt and /llms-full.txt: the whole guide in a form AI agents can read.
			plugins: [starlightLlmsTxt()],
			// English is the source language and lives at the root (no /en/ prefix).
			// Every other locale is an AI-assisted translation of the English pages.
			// To add a language: add it here, copy the English pages into src/content/docs/<code>/,
			// translate them, and add the sidebar label translations below.
			defaultLocale: 'root',
			locales: {
				root: { label: 'English', lang: 'en' },
				es: { label: 'Español', lang: 'es' },
			},
			sidebar: [
				{
					label: 'Start here',
					translations: { es: 'Empieza aquí' },
					items: [
						{ slug: 'start-here/introduction' },
						{ slug: 'start-here/roadmap' },
						{ slug: 'start-here/conventions' },
						{ slug: 'start-here/agents' },
						{ slug: 'start-here/faq' },
					],
				},
				{
					label: '0 · Plan',
					translations: { es: '0 · Plan' },
					items: [
						{ slug: 'plan/architecture' },
						{ slug: 'plan/machine' },
						{ slug: 'plan/dns-and-certificates' },
					],
				},
				{
					label: '1 · The machine',
					translations: { es: '1 · La máquina' },
					items: [{ slug: 'machine/opentofu-setup' }, { slug: 'machine/create' }],
				},
				{
					label: '2 · The cluster',
					translations: { es: '2 · El clúster' },
					items: [{ slug: 'cluster/install' }],
				},
				{
					label: '3 · GitOps',
					translations: { es: '3 · GitOps' },
					items: [{ slug: 'gitops/argocd' }],
				},
			],
		}),
	],
});
