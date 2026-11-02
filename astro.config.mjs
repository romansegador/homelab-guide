// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://starlight.astro.build/reference/configuration/
export default defineConfig({
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
			],
		}),
	],
});
