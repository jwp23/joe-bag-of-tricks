/**
 * Mechanical UX-audit probes, for use inside the project's existing verify.js
 * harness (see the scripted-browser-verification skill). Copy once next to it,
 * then call these from `checks[].run` — do not start a second script.
 *
 *   const { sweepTruncation, assertPrimaryContentShare, captureLabels } = require('./ux-checks.js');
 *
 * Everything project-specific (selectors, ratios, output paths) is an argument,
 * supplied from the project's verify.config.json. Nothing is baked in here.
 *
 * `sweepTruncation` and `assertPrimaryContentShare` are ASSERTIONS — they throw,
 * and the harness turns that into a FAIL line. `captureLabels` is EVIDENCE — it
 * never fails; it writes a file for the agent to read and judge.
 */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

/**
 * Flags every clipped text-bearing element: scrollWidth > clientWidth.
 *
 * Only elements that actually clip are considered — overflow hidden/clip/auto/
 * scroll, or text-overflow: ellipsis. An element with visible overflow spills
 * rather than truncates, and inline elements report clientWidth 0, so both would
 * be pure noise.
 *
 * Writes the full list to `reportFile` (if given) and throws a one-line summary.
 */
async function sweepTruncation(page, { ignoreSelector = null, reportFile = null } = {}) {
  const truncated = await page.evaluate((ignore) => {
    const clips = (style) =>
      ['hidden', 'clip', 'auto', 'scroll'].includes(style.overflowX) ||
      style.textOverflow === 'ellipsis';
    const found = [];
    for (const el of document.querySelectorAll('body *')) {
      if (el.children.length > 0) continue; // leaf text nodes only
      if (ignore && el.closest(ignore)) continue;
      const text = (el.textContent || '').trim();
      if (!text) continue;
      const style = getComputedStyle(el);
      if (style.display === 'none' || style.display.startsWith('inline')) continue;
      if (style.visibility === 'hidden' || !clips(style)) continue;
      if (el.scrollWidth <= el.clientWidth + 1) continue;
      found.push({
        text,
        tag: el.tagName.toLowerCase(),
        selector: el.className ? `${el.tagName.toLowerCase()}.${String(el.className).split(/\s+/)[0]}` : el.tagName.toLowerCase(),
        scrollWidth: el.scrollWidth,
        clientWidth: el.clientWidth,
      });
    }
    return found;
  }, ignoreSelector);

  if (reportFile) writeEvidence(reportFile, truncated);
  const sample = truncated.slice(0, 3).map((item) => `${item.selector} "${item.text.slice(0, 30)}"`).join('; ');
  assert.equal(truncated.length, 0, `${truncated.length} truncated — ${sample}`);
}

/**
 * Asserts the primary content region still owns most of the viewport at this
 * size. `selector` and `minShare` (0-1) both come from project config.
 */
async function assertPrimaryContentShare(page, { selector, minShare }) {
  assert.ok(selector, 'assertPrimaryContentShare needs a selector from project config');
  assert.ok(typeof minShare === 'number', 'assertPrimaryContentShare needs minShare from project config');
  const box = await page.locator(selector).first().boundingBox();
  assert.ok(box, `primary content ${selector} is not visible`);
  const viewport = page.viewportSize();
  const share = (box.width * box.height) / (viewport.width * viewport.height);
  assert.ok(
    share >= minShare,
    `primary content ${selector} holds ${(share * 100).toFixed(0)}% of the viewport, want >= ${(minShare * 100).toFixed(0)}%`,
  );
}

/**
 * Captures every visible short label to `reportFile` for the agent to judge.
 * Never throws on the labels themselves — comprehensibility is not decidable in
 * code. `abbreviationCandidates` is a hint to read first, not a verdict.
 */
async function captureLabels(page, { reportFile, maxLength = 40 }) {
  assert.ok(reportFile, 'captureLabels needs a reportFile path');
  const labels = await page.evaluate((limit) => {
    const seen = new Set();
    for (const el of document.querySelectorAll('body *')) {
      if (el.children.length > 0) continue;
      const style = getComputedStyle(el);
      if (style.display === 'none' || style.visibility === 'hidden') continue;
      const text = (el.textContent || '').trim().replace(/\s+/g, ' ');
      if (!text || text.length > limit) continue;
      seen.add(text);
    }
    return [...seen];
  }, maxLength);

  const cryptic = labels.filter((label) => /^[A-Z0-9]{2,5}$/.test(label) || /^[^aeiouAEIOU\s]{4,}$/.test(label));
  writeEvidence(reportFile, { labels, abbreviationCandidates: cryptic });
  return reportFile;
}

function writeEvidence(file, data) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(data, null, 2)}\n`);
}

module.exports = { sweepTruncation, assertPrimaryContentShare, captureLabels };
