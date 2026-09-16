import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";

// Rules to skip when injecting .cursor/rules into pi sessions.
const EXCLUDED_RULES = new Set(["dexter-running-tests.mdc"]);

const CURSOR_STYLE_BEHAVIOR = `

## Working style

- Use tools silently; report results, not intentions. Never narrate tool calls.
- Read a file before editing it. Prefer dedicated file/search tools over shell cat/grep/sed.
- Batch independent tool calls in parallel; avoid serial exploration.
- Search before reading large files; use offsets/limits on files over 500 lines.
- Lead with the answer. No preamble, no post-task summaries, no sign-offs.
- For multi-step work, keep a visible task list and update it as you go.
- When a task is ambiguous or has real trade-offs, propose a plan before editing.
- Don't run tests, lint, or typecheck unless asked or the change is high-risk.
- Stop when done — no extra verification rounds "for safety".`;

const rulesCache = new Map<string, string>();

function stripFrontmatter(text: string): string {
	if (!text.startsWith("---")) return text;
	const end = text.indexOf("\n---", 3);
	return end === -1 ? text : text.slice(end + 4);
}

function alwaysApplies(text: string): boolean {
	if (!text.startsWith("---")) return true;
	const end = text.indexOf("\n---", 3);
	const frontmatter = end === -1 ? text : text.slice(0, end);
	return /alwaysApply:\s*true/.test(frontmatter);
}

async function loadCursorRules(cwd: string): Promise<string> {
	const cached = rulesCache.get(cwd);
	if (cached !== undefined) return cached;

	let prompt = "";
	try {
		const dir = join(cwd, ".cursor", "rules");
		const files = (await readdir(dir))
			.filter((f) => f.endsWith(".mdc") && !EXCLUDED_RULES.has(f))
			.sort();
		const parts: string[] = [];
		for (const file of files) {
			const text = await readFile(join(dir, file), "utf8");
			if (!alwaysApplies(text)) continue;
			const body = stripFrontmatter(text).trim();
			if (body) parts.push(`### ${file}\n\n${body}`);
		}
		if (parts.length) {
			prompt = `\n\n## Workspace rules (.cursor/rules)\n\n${parts.join("\n\n")}`;
		}
	} catch {
		// No .cursor/rules in this workspace — fine.
	}

	rulesCache.set(cwd, prompt);
	return prompt;
}

export default function (pi: ExtensionAPI) {
	let rulesPrompt = "";

	pi.on("session_start", async (_event, ctx) => {
		const cwd = ctx.cwd ?? process.cwd();
		rulesPrompt = await loadCursorRules(cwd);
		if (rulesPrompt && ctx.hasUI) {
			ctx.ui.notify("cursor-parity: injected .cursor/rules into system prompt", "info");
		}
	});

	pi.on("before_agent_start", (event) => ({
		systemPrompt: event.systemPrompt + CURSOR_STYLE_BEHAVIOR + rulesPrompt,
	}));
}
