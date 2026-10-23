/** @type {import("./npm/node_modules/pi-vimmode/config").VimConfig} */
export default (vim) => {
  vim.keymap.set(["normal", "visual", "visualLine", "visualBlock"], "y", '"+y');
  vim.keymap.set("normal", "Y", '"+Y');
};
