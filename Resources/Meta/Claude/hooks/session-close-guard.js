#!/usr/bin/env node
// Session-Close Guard — Stop hook
//
// Mechanical enforcement of session-protocol.md's close process. When you
// explicitly signal a session close AND substantive vault work happened this
// session that hasn't been consolidated into work-state.md, block the stop once
// and tell the agent to run the close protocol before ending.
//
// Why mechanical, not prose: a "must-happen" close step can't live in an
// instruction alone, because an agent optimizing to end the turn will rationalize
// past it. This guarantees the ARTIFACT (work-state.md gets written), not its quality.
//
// Guards (why this won't nag or trap you):
//   - close-intent gate   : fires only on a close signal in the LAST human message.
//                           No mid-session firing.
//   - substantive gate    : fires only if tracked content was written this session
//                           (pure Q&A / read-only -> silent).
//   - artifact exclusion  : the close-target files (work-state/memory/reminders/Session Log)
//                           don't count as "work", so touching them doesn't keep it dirty.
//   - one block per close : a /tmp marker keyed on session + last-message uuid releases on the
//                           second pass, so the agent is nudged at most once (also honors
//                           stop_hook_active when present). You can never be trapped.
//   - override honor      : "skip memory" / "don't save" in the close message -> allow.
//   - fails OPEN          : any error -> exit 0 (allow). A broken guard must never block a close.
//
// Limit (by design): a silent walk-away (no close signal typed) is NOT caught.
// Vault-scoped: coding projects have their own .claude/ and never see this hook.

const fs = require('fs');
const os = require('os');
const path = require('path');

// --- close-intent vocabulary (canonical source: rules/core/session-protocol.md) ---
const STRONG = [
  /\/update-memory\b/i, /\bupdate memory\b/i, /\b(save|remember) this\b/i,
  /\bwrap(?:ping)? up\b/i, /\bthat'?s all\b/i, /\bthat'?s it\b/i,
  /\bdone for now\b/i, /\ball set\b/i, /\bsign(?:ing)? off\b/i, /\bcall it (?:a day|here)\b/i,
];
const WEAK = [
  // close-specific only — pure acknowledgments (ok / great / perfect / cool) are excluded
  // because mid-session they read as approval, not "we're done".
  /\bdone\b/i, /\bbye\b/i, /\bthanks\b/i, /\bthank you\b/i, /\bthx\b/i,
  /\bgoodnight\b/i, /\bgood night\b/i, /\bnight\b/i,
];
const OVERRIDE = [
  /\bskip (?:the )?memory\b/i, /\bno memory\b/i, /\bdon'?t save\b/i,
  /\bno update\b/i, /\bdon'?t update\b/i, /\bwithout updating\b/i,
];

// --- substantive-content path test ---
const TRACKED = ['/Contexts/', '/Calendar/'];                   // vault working content
const RULES = ['/rules/', '/commands/', '/hooks/', '/agents/']; // rules work (under Resources/Meta/Claude)
const CLOSE_ARTIFACTS = ['work-state.md', 'memory.md', 'reminders.md'];

function isWorkState(p) { return path.basename(p) === 'work-state.md'; }

function isSubstantive(p) {
  if (!p || !p.endsWith('.md')) return false;
  if (CLOSE_ARTIFACTS.includes(path.basename(p))) return false;
  if (/session log/i.test(p)) return false;             // the Session Log is itself a close artifact
  const inTracked = TRACKED.some(s => p.includes(s));
  const inRules = p.includes('/Resources/Meta/Claude/') && RULES.some(s => p.includes(s));
  return inTracked || inRules;
}

// Return {text, uuid} for a REAL human prompt line, else null (rejects tool_result carriers).
function humanPrompt(o) {
  if (!o || o.type !== 'user' || o.isSidechain) return null;
  if (o.toolUseResult) return null;                     // tool_result, not a typed prompt
  const c = (o.message || {}).content;
  let text = '';
  if (typeof c === 'string') text = c;
  else if (Array.isArray(c)) {
    for (const b of c) {
      if (!b || typeof b !== 'object') continue;
      if (b.type === 'tool_result') return null;        // a tool_result block disqualifies the line
      if (b.type === 'text' && typeof b.text === 'string') text += b.text + '\n';
    }
  } else return null;
  text = text.replace(/Current local time:[^\n]*\n?/gi, '').trim(); // strip injected date line if present
  if (!text) return null;
  return { text, uuid: o.uuid || '' };
}

function classifyClose(text) {
  const t = text.trim();
  if (OVERRIDE.some(r => r.test(t))) return { close: false, override: true };
  if (STRONG.some(r => r.test(t))) return { close: true, override: false };
  const words = t.split(/\s+/).filter(Boolean);
  if (words.length <= 5 && !t.includes('?') && WEAK.some(r => r.test(t)))
    return { close: true, override: false };            // weak signal only on a short, request-free message
  return { close: false, override: false };
}

function run(input) {
  let stdin = {};
  try { stdin = JSON.parse(input); } catch { /* fall through */ }
  if (stdin.stop_hook_active) return;                   // already continuing from a prior block -> never loop

  const tpath = stdin.transcript_path;
  if (!tpath || !fs.existsSync(tpath)) return;

  let lines;
  try { lines = fs.readFileSync(tpath, 'utf8').split('\n').filter(Boolean); } catch { return; }

  // last human prompt (scan from the end; tool_results are skipped)
  let last = null;
  for (let i = lines.length - 1; i >= 0 && !last; i--) {
    let o; try { o = JSON.parse(lines[i]); } catch { continue; }
    last = humanPrompt(o);
  }
  if (!last) return;

  const verdict = classifyClose(last.text);
  if (verdict.override || !verdict.close) return;       // no close signal, or user opted out

  // close signal present -> did substantive work happen, and was work-state.md written?
  let substantive = false, workStateWritten = false;
  for (const ln of lines) {
    let o; try { o = JSON.parse(ln); } catch { continue; }
    if (o.type !== 'assistant' || o.isSidechain) continue;
    const c = (o.message || {}).content;
    if (!Array.isArray(c)) continue;
    for (const b of c) {
      if (!b || b.type !== 'tool_use') continue;
      if (!['Write', 'Edit', 'MultiEdit', 'NotebookEdit'].includes(b.name)) continue;
      const fp = (b.input || {}).file_path || (b.input || {}).notebook_path;
      if (!fp) continue;
      if (isWorkState(fp)) workStateWritten = true;
      else if (isSubstantive(fp)) substantive = true;
    }
  }

  if (!substantive || workStateWritten) return;         // nothing to consolidate, or already done

  // loop guard: block at most once per distinct close message
  const marker = path.join(os.tmpdir(), `claude-session-close-${stdin.session_id || 'x'}.json`);
  try {
    if (fs.existsSync(marker)) {
      const m = JSON.parse(fs.readFileSync(marker, 'utf8'));
      if (m.uuid === last.uuid) return;                 // already nudged for THIS close -> release
    }
    fs.writeFileSync(marker, JSON.stringify({ uuid: last.uuid, at: Date.now() }));
  } catch { /* marker is best-effort; stop_hook_active is the backstop */ }

  const reason = [
    "Session-close guard: substantive vault work happened this session but work-state.md hasn't been written.",
    "Before ending, run the rules/core/session-protocol.md close process:",
    "(1) update the Last Session summary plus the touched projects' Left Off / Last Touched in work-state.md;",
    "(2) update memory.md only if a decision, open thread, or pattern actually changed;",
    "(3) write a Session Log entry if the session was substantial.",
    "If the user explicitly declined a memory update, stop without updating instead.",
  ].join(' ');

  process.stdout.write(JSON.stringify({ decision: 'block', reason }));
}

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', c => (input += c));
process.stdin.on('end', () => { try { run(input); } catch { /* fail open */ } process.exit(0); });
