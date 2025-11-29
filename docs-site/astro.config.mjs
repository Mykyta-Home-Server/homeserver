import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import tailwind from '@astrojs/tailwind';

export default defineConfig({
  site: 'https://mykyta-ryasny.github.io',
  base: '/homeserver',
  integrations: [
    starlight({
      title: 'Home Server Docs',
      description: 'Documentation for personal home server with AI-powered automation',
      logo: {
        light: './src/assets/logo-light.svg',
        dark: './src/assets/logo-dark.svg',
        replacesTitle: false,
      },
      social: {
        github: 'https://github.com/mykyta-ryasny/homeserver',
      },
      customCss: ['./src/styles/custom.css'],
      sidebar: [
        {
          label: 'Getting Started',
          items: [
            { label: 'Introduction', slug: 'guides/introduction' },
            { label: 'Quick Reference', slug: 'reference/quick-reference' },
          ],
        },
        {
          label: 'Setup Guides',
          items: [
            { label: 'Docker Guide', slug: 'guides/docker' },
            { label: 'Adding Services', slug: 'guides/adding-services' },
            { label: 'ZSH Setup', slug: 'setup/zsh' },
            { label: 'GitHub Runner', slug: 'setup/github-runner' },
          ],
        },
        {
          label: 'Infrastructure',
          items: [
            { label: 'LDAP Guide', slug: 'guides/ldap' },
            { label: 'Monitoring', slug: 'guides/monitoring' },
            { label: 'Migration Guide', slug: 'guides/migration' },
          ],
        },
        {
          label: 'Reference',
          items: [
            { label: 'Service Profiles', slug: 'reference/service-profiles' },
            { label: 'Scripts', slug: 'reference/scripts' },
            { label: 'Maintenance Cron', slug: 'reference/maintenance-cron' },
            { label: 'QoL Tools', slug: 'reference/qol-tools' },
          ],
        },
      ],
      editLink: {
        baseUrl: 'https://github.com/mykyta-ryasny/homeserver/edit/main/docs-site/',
      },
      lastUpdated: true,
    }),
    tailwind({
      applyBaseStyles: false,
    }),
  ],
});
