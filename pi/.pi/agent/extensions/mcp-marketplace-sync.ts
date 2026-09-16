import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";
import { existsSync } from "node:fs";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

// Re-syncs mcp.json from ~/projects/claude-marketplace when the clone's HEAD
// has moved since the last sync. Never pulls the repo — reacts to pulls only.
const MARKETPLACE_DIR = join(homedir(), "projects", "claude-marketplace");
const SYNC_SCRIPT = join(homedir(), ".pi", "agent", "sync-marketplace-mcp.py");
const STAMP_FILE = join(homedir(), ".pi", "agent", "mcp-marketplace-sync.stamp");

const execFileAsync = promisify(execFile);

async function headSha(): Promise<string | null> {
	try {
		const { stdout } = await execFileAsync("git", ["-C", MARKETPLACE_DIR, "rev-parse", "HEAD"], { timeout: 5000 });
		return stdout.trim() || null;
	} catch {
		return null;
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (!existsSync(MARKETPLACE_DIR) || !existsSync(SYNC_SCRIPT)) return;

		const head = await headSha();
		if (!head) return;

		const lastSync = await readFile(STAMP_FILE, "utf8").then((s) => s.trim()).catch(() => null);
		if (lastSync === head) return;

		try {
			const { stdout } = await execFileAsync(SYNC_SCRIPT, [], { timeout: 30000 });
			await mkdir(join(homedir(), ".pi", "agent"), { recursive: true });
			await writeFile(STAMP_FILE, `${head}\n`);

			const added = stdout.match(/^added \((\d+)\)/m)?.[1] ?? "0";
			const updated = stdout.match(/^updated \((\d+)\)/m)?.[1] ?? "0";
			if (added !== "0" || updated !== "0") {
				ctx.ui.notify(
					`MCP marketplace sync: added ${added}, updated ${updated}. Restart pi to load; re-auth updated servers with /mcp-auth <name>.`,
					"warning",
				);
			}
		} catch (err) {
			ctx.ui.notify(`MCP marketplace sync failed: ${err instanceof Error ? err.message : String(err)}`, "warning");
		}
	});
}
