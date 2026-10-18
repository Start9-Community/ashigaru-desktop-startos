import { setupManifest } from '@start9labs/start-sdk'
import { long, short } from './i18n'

export const manifest = setupManifest({
  id: 'ashigaru-desktop',
  title: 'Ashigaru Desktop',
  license: 'GPL-3.0',
  packageRepo: 'https://github.com/linkinparkrulz/ashigaru-desktop-startos',
  upstreamRepo: 'https://github.com/linkinparkrulz/ashigaru-desktop',
  marketingUrl: 'https://ashigaru.rs/',
  donationUrl: null,
  description: { short, long },
  volumes: ['main'],
  images: {
    main: {
      source: { dockerBuild: {} },
      // Upstream publishes a Linux build for x86_64 only.
      arch: ['x86_64'],
      emulateMissing: false,
    },
  },
})
