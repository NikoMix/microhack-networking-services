import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// ─── Site URL & base path ─────────────────────────────────────────────────────
// Derived from GITHUB_REPOSITORY ("owner/repo") on GitHub Actions so a freshly
// templated repo builds with no manual configuration. Override via ASTRO_SITE /
// ASTRO_BASE repo variables if needed.
const repo = process.env.GITHUB_REPOSITORY ?? 'NikoMix/microhack-networking-services';
const [owner, repoName] = repo.split('/');
const isUserOrOrgPage = repoName?.toLowerCase() === `${owner?.toLowerCase()}.github.io`;

const site =
  process.env.ASTRO_SITE ??
  (isUserOrOrgPage ? `https://${owner}.github.io` : `https://${owner}.github.io/${repoName}`);

const base = process.env.ASTRO_BASE ?? (isUserOrOrgPage ? '/' : `/${repoName}/`);

const githubUrl = process.env.ASTRO_GITHUB_URL ?? `https://github.com/${repo}`;

export default defineConfig({
  site,
  base,
  integrations: [
    starlight({
      title: 'Module B Networking Microhack',
      description:
        'A 1-day Train-the-Trainer microhack for the Networking Services in Microsoft Azure Advanced Specialization (Module B), powered by GitHub Copilot agents, skills, and MCP.',
      social: [{ icon: 'github', label: 'GitHub', href: githubUrl }],
      sidebar: [
        { label: 'Home', link: '/' },
        { label: 'Overview', link: '/overview/' },
        { label: 'Agenda (1 day)', link: '/agenda/' },
        { label: 'Prerequisites', link: '/prerequisites/' },
        {
          label: 'Challenges',
          items: [{ autogenerate: { directory: 'challenges' } }],
        },
        {
          label: 'Trainer (TtT)',
          items: [{ autogenerate: { directory: 'trainer' } }],
        },
        {
          label: 'Solutions (trainer-only)',
          collapsed: true,
          items: [{ autogenerate: { directory: 'solutions' } }],
        },
        {
          label: 'Reference',
          items: [{ autogenerate: { directory: 'reference' } }],
        },
      ],
      editLink: { baseUrl: `${githubUrl}/edit/main/` },
      lastUpdated: true,
    }),
  ],
});
