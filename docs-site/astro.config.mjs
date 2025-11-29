import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import tailwind from '@astrojs/tailwind';
import mermaid from 'astro-mermaid';

export default defineConfig({
  site: 'https://mykyta-ryasny.github.io',
  base: '/homeserver',
  integrations: [
    mermaid(),
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
      head: [
        {
          tag: 'script',
          content: `
            function initMermaidZoom() {
              const diagrams = document.querySelectorAll('.mermaid');
              let modal = document.getElementById('mermaid-modal');
              if (!modal) {
                modal = document.createElement('div');
                modal.id = 'mermaid-modal';
                modal.className = 'mermaid-modal';
                modal.innerHTML = '<button class="mermaid-modal-close" aria-label="Close">&times;</button><div class="mermaid-content"></div>';
                document.body.appendChild(modal);
                modal.addEventListener('click', (e) => {
                  if (e.target === modal || e.target.classList.contains('mermaid-modal-close')) {
                    modal.classList.remove('active');
                    document.body.style.overflow = '';
                  }
                });
                document.addEventListener('keydown', (e) => {
                  if (e.key === 'Escape' && modal.classList.contains('active')) {
                    modal.classList.remove('active');
                    document.body.style.overflow = '';
                  }
                });
              }
              diagrams.forEach((diagram) => {
                if (diagram.dataset.zoomEnabled) return;
                diagram.dataset.zoomEnabled = 'true';
                diagram.addEventListener('click', () => {
                  const svg = diagram.querySelector('svg');
                  if (svg) {
                    modal.querySelector('.mermaid-content').innerHTML = svg.outerHTML;
                    modal.classList.add('active');
                    document.body.style.overflow = 'hidden';
                  }
                });
              });
            }
            if (document.readyState === 'loading') {
              document.addEventListener('DOMContentLoaded', () => setTimeout(initMermaidZoom, 500));
            } else {
              setTimeout(initMermaidZoom, 500);
            }
            document.addEventListener('astro:page-load', () => setTimeout(initMermaidZoom, 500));
          `,
        },
      ],
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
