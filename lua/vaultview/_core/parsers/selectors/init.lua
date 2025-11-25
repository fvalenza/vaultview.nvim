
local M = {}

M.default_input_selectors = {
    ["*"] = [[find %q -type f | sort ]], -- all files
    ["*.md"] = [[find %q -type f -name '*.md' | sort ]], -- all markdown files
    ["yyyy-mm-dd.md"] = [[find %q -type f | sort | grep -E '/[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])\.md$']], -- all markdown files with name matching yyyy-mm-dd.md
}

M.default_entry_content_selectors = {
    headings = [=[grep -E '^#+[[:space:]]+.+' %q | sed -E 's/^#+[[:space:]]+//' ]=],
    h1 = [=[grep -E '^#[[:space:]]+.+' %q | sed -E 's/^#[[:space:]]+//' ]=],
    h2 = [=[grep -E '^##[[:space:]]+.+' %q | sed -E 's/^##[[:space:]]+//' ]=],
    h3 = [=[grep -E '^###[[:space:]]+.+' %q | sed -E 's/^###[[:space:]]+//' ]=],
    h4 = [=[grep -E '^####[[:space:]]+.+' %q | sed -E 's/^####[[:space:]]+//' ]=],
    h2_awk_noexcalidraw = [=[awk '/^# Excalidraw Data/ { exit } /^##[[:space:]]+.+/ { sub(/^##[[:space:]]+/, ""); print }' %q]=],
    h2_rg_noexcalidraw = [=[rg --until-pattern '^# Excalidraw Data' '^##[[:space:]]+.+$' %q | sed -E 's/^##[[:space:]]+//' ]=],
    uncompleted_tasks = [=[grep -E '^\s*-\s*\[ \]' %q | sed -E 's/^\s*-\s*\[ \]\s*//' ]=], -- TODO test
    completed_tasks = [=[grep -E '^\s*-\s*\[x\]' %q | sed -E 's/^\s*-\s*\[x\]\s*//' ]=], -- TODO test
    tasks = [=[grep -E '^\s*-\s*\[[ x]\]' %q | sed -E 's/^\s*-\s*\[[ x]\]\s*//' ]=], -- TODO test
}

return M
