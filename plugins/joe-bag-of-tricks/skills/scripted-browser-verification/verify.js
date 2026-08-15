#!/usr/bin/env node
/**
 * Reusable browser verification harness.
 *
 * Copy once into the project (conventionally `scripts/verify.js`), then EXTEND
 * `checks` for each new UI change. Never hand-roll a fresh script per fix.
 *
 * Config (`verify.config.json`, sibling of this file) supplies everything
 * project-specific — there are no baked-in defaults:
 *   {
 *     "baseUrl": "http://localhost:5173",
 *     "screenshotDir": ".verify-screenshots",
 *     "viewports": [{ "name": "desktop", "width": 1440, "height": 900 }]
 *   }
 *
 * Run: node scripts/verify.js [name-substring]
 * Exit code 0 = every check passed. Output is a summary plus screenshot paths.
 */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');

const config = require('./verify.config.json');

// EXTEND THIS. One entry per behavior worth proving; assertions live in code.
const checks = [
  {
    name: 'landing page renders its primary heading',
    path: '/',
    async run(page) {
      const heading = page.locator('h1').first();
      await heading.waitFor({ state: 'visible', timeout: 5000 });
      const text = (await heading.innerText()).trim();
      assert.ok(text.length > 0, 'primary heading is empty');
    },
  },
];

const slug = (value) => value.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

async function runCheck(context, check, viewport) {
  const page = await context.newPage();
  const consoleErrors = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });
  page.on('pageerror', (error) => consoleErrors.push(error.message));

  const screenshot = path.join(config.screenshotDir, `${slug(check.name)}--${viewport.name}.png`);
  let failure = null;
  try {
    await page.goto(new URL(check.path, config.baseUrl).href, { waitUntil: 'domcontentloaded' });
    await check.run(page);
    assert.equal(consoleErrors.length, 0, `console errors: ${consoleErrors.join(' | ')}`);
  } catch (error) {
    failure = error.message.split('\n')[0];
  }
  await page.screenshot({ path: screenshot, fullPage: true });
  await page.close();
  return { name: check.name, viewport: viewport.name, failure, screenshot };
}

async function main() {
  const filter = process.argv[2];
  const selected = filter ? checks.filter((check) => check.name.includes(filter)) : checks;
  assert.ok(selected.length > 0, `no check matches "${filter}"`);
  fs.mkdirSync(config.screenshotDir, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const results = [];
  try {
    for (const viewport of config.viewports) {
      const context = await browser.newContext({
        viewport: { width: viewport.width, height: viewport.height },
      });
      for (const check of selected) {
        results.push(await runCheck(context, check, viewport));
      }
      await context.close();
    }
  } finally {
    await browser.close();
  }

  // Compact output contract: one line per check, then paths. Never dump page content.
  for (const result of results) {
    const status = result.failure ? 'FAIL' : 'PASS';
    const reason = result.failure ? ` — ${result.failure}` : '';
    console.log(`${status} [${result.viewport}] ${result.name}${reason}`);
  }
  const failed = results.filter((result) => result.failure).length;
  console.log(`\n${results.length - failed}/${results.length} passed`);
  console.log('screenshots:');
  for (const result of results) console.log(`  ${result.screenshot}`);
  process.exitCode = failed === 0 ? 0 : 1;
}

main().catch((error) => {
  console.log(`FAIL harness — ${error.message.split('\n')[0]}`);
  process.exitCode = 1;
});
