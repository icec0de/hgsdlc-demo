// trusted test config: lives in the framework image, not in the repo the ai edits
// runs the ai-written scenario tests (repo tests/) and the governance tests (this dir)
// against the page served from the run workspace (cwd)
const path = require('path');
const repo = process.cwd();

module.exports = {
  timeout: 15000,
  retries: 0,
  outputDir: '/tmp/pw-output',  // keep playwright scratch files out of the repo
  reporter: [['list'], ['json', { outputFile: process.env.RESULTS_JSON || '/tmp/pw-results.json' }]],
  use: { baseURL: 'http://127.0.0.1:4173', browserName: 'chromium', headless: true },
  webServer: {
    command: `node ${path.join(__dirname, 'serve.js')} ${repo} 4173`,
    url: 'http://127.0.0.1:4173/index.html',
    reuseExistingServer: false,
    timeout: 15000,
  },
  projects: [
    { name: 'scenarios', testDir: path.join(repo, 'tests'), testMatch: /T-\d{4}\.spec\.js$/ },
    { name: 'governance', testDir: __dirname, testMatch: /governance\.spec\.js$/ },
  ],
};
