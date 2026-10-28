/**
 * Insert-mode mapping: jj within 300 ms exits immediately.
 * A lone j is displayed immediately; bracketed paste and normal mode are unchanged.
 * User-owned extension, independent of Homebrew and managed plugin installs.
 * Disable with disabledExtensions: [extension-module:vim-jj] in profile config.
 */
import { CustomEditor, type ExtensionAPI, type ExtensionContext } from "@oh-my-pi/pi-coding-agent";
import { matchesKey } from "@oh-my-pi/pi-tui";

const _timeoutMs = 300;
type _EditorFactory = NonNullable<Parameters<ExtensionContext["ui"]["setEditorComponent"]>[0]>;

export default function vimJj(pi: ExtensionAPI): void {
	let installedFactory: _EditorFactory | undefined;

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		const previousFactory = ctx.ui.getEditorComponent();
		if (installedFactory && previousFactory === installedFactory) return;

		installedFactory = (tui, theme, keybindings) => {
			const editor = previousFactory?.(tui, theme, keybindings) ?? new CustomEditor(tui, theme, keybindings);
			const forward = editor.handleInput.bind(editor);
			let pending: { at: number; revision: number; line: number; col: number } | undefined;

			editor.handleInput = (data: string): void => {
				const previous = pending;
				pending = undefined;
				if (!editor.vimEnabled || editor.vimMode !== "insert" || editor.pasteInFlight || !matchesKey(data, "j")) {
					forward(data);
					return;
				}

				const now = performance.now();
				const cursor = editor.getCursor();
				if (previous && now - previous.at <= _timeoutMs && editor.textRevision === previous.revision &&
					cursor.line === previous.line && cursor.col === previous.col) {
					forward("\x7f");
					forward("\x1b");
					if (editor.vimMode === "insert" && editor.vimEnabled) forward("\x1b");
					return;
				}

				const revision = editor.textRevision;
				forward(data);
				const after = editor.getCursor();
				if (editor.vimMode === "insert" && editor.textRevision !== revision &&
					after.line === cursor.line && after.col === cursor.col + 1) {
					pending = { at: now, revision: editor.textRevision, line: after.line, col: after.col };
				}
			};
			return editor;
		};
		ctx.ui.setEditorComponent(installedFactory);
	});
}
