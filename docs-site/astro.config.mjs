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
              // Find all SVGs inside mermaid containers
              const svgs = document.querySelectorAll('.mermaid svg, .astro-mermaid svg, pre.mermaid svg');

              svgs.forEach((svg) => {
                const container = svg.closest('.mermaid, .astro-mermaid, pre.mermaid');
                if (!container || container.dataset.zoomEnabled) return;
                container.dataset.zoomEnabled = 'true';

                container.addEventListener('click', () => {
                  // Get fresh reference to SVG on each click
                  const currentSvg = container.querySelector('svg');
                  if (!currentSvg) return;

                  // Create modal fresh each time to avoid caching
                  let modal = document.getElementById('mermaid-modal');
                  if (modal) modal.remove();

                  modal = document.createElement('div');
                  modal.id = 'mermaid-modal';
                  modal.className = 'mermaid-modal active';
                  modal.innerHTML = '<button class="mermaid-modal-close" aria-label="Close">×</button><div class="mermaid-content"></div>';

                  // Clone current SVG
                  const svgClone = currentSvg.cloneNode(true);
                  svgClone.removeAttribute('width');
                  svgClone.removeAttribute('height');
                  svgClone.style.cssText = 'width:100%;height:auto;max-height:80vh;';

                  modal.querySelector('.mermaid-content').appendChild(svgClone);
                  document.body.appendChild(modal);
                  document.body.style.overflow = 'hidden';

                  // Close handlers
                  modal.addEventListener('click', (e) => {
                    if (e.target === modal || e.target.classList.contains('mermaid-modal-close')) {
                      modal.remove();
                      document.body.style.overflow = '';
                    }
                  });
                  document.addEventListener('keydown', function closeOnEsc(e) {
                    if (e.key === 'Escape') {
                      modal.remove();
                      document.body.style.overflow = '';
                      document.removeEventListener('keydown', closeOnEsc);
                    }
                  });
                });
              });
            }

            function scheduleInit() {
              setTimeout(initMermaidZoom, 1500);
            }
            if (document.readyState === 'loading') {
              document.addEventListener('DOMContentLoaded', scheduleInit);
            } else {
              scheduleInit();
            }
            document.addEventListener('astro:page-load', scheduleInit);
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
            { label: 'Monitoring', slug: 'guides/monitoring' },
            { label: 'Authentik Migration', slug: 'guides/authentik-migration' },
            { label: 'Subdomain Cleanup', slug: 'guides/subdomain-cleanup' },
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
