--- symbol ranking helpers ported from ty_mcp utils.py.
--- provides fzf_score, rank_and_limit, and LSP symbol kind constants.

local M = {}

-- result limits
M.MIN_RESULTS = 10
M.MAX_RESULTS = 50
M.SCORE_THRESHOLD = 30
M.DEBOUNCE_MS = 250
M.MAX_INPUT = 5000  -- cap scoring input (ty can return 600K+ for short queries)

-- LSP symbol kind values (mirrors SymbolKind in utils.py)
M.SymbolKind = {
  FILE = 1,
  MODULE = 2,
  NAMESPACE = 3,
  PACKAGE = 4,
  CLASS = 5,
  METHOD = 6,
  PROPERTY = 7,
  FIELD = 8,
  CONSTRUCTOR = 9,
  ENUM = 10,
  INTERFACE = 11,
  FUNCTION = 12,
  VARIABLE = 13,
  CONSTANT = 14,
  STRING = 15,
  NUMBER = 16,
  BOOLEAN = 17,
  ARRAY = 18,
  OBJECT = 19,
  KEY = 20,
  NULL = 21,
  ENUM_MEMBER = 22,
  STRUCT = 23,
  EVENT = 24,
  OPERATOR = 25,
  TYPE_PARAM = 26,
}

-- reverse lookup: number -> lowercase name
M.KIND_NAMES = {}
for name, val in pairs(M.SymbolKind) do
  M.KIND_NAMES[val] = name:lower()
end

-- kind groups for filtered searches
M.KIND_GROUPS = {
  class    = { M.SymbolKind.CLASS, M.SymbolKind.ENUM, M.SymbolKind.INTERFACE, M.SymbolKind.STRUCT },
  func     = { M.SymbolKind.METHOD, M.SymbolKind.CONSTRUCTOR, M.SymbolKind.FUNCTION },
  variable = {
    M.SymbolKind.PROPERTY, M.SymbolKind.FIELD, M.SymbolKind.VARIABLE,
    M.SymbolKind.CONSTANT, M.SymbolKind.ENUM_MEMBER,
  },
}

local function make_kind_set(kinds)
  local s = {}
  for _, k in ipairs(kinds) do
    s[k] = true
  end
  return s
end

M.KIND_SETS = {}
for group, kinds in pairs(M.KIND_GROUPS) do
  M.KIND_SETS[group] = make_kind_set(kinds)
end

local byte = string.byte
local UNDERSCORE = byte('_')
local HYPHEN = byte('-')
local SPACE = byte(' ')
local UPPER_A, UPPER_Z = byte('A'), byte('Z')
local LOWER_A, LOWER_Z = byte('a'), byte('z')

local function is_lower(b) return b >= LOWER_A and b <= LOWER_Z end
local function is_upper(b) return b >= UPPER_A and b <= UPPER_Z end
local function to_lower(b) return is_upper(b) and (b + 32) or b end

local function underscore_eq(a, alen, b, blen)
  local ai, bi = 1, 1
  while ai <= alen and bi <= blen do
    while ai <= alen and byte(a, ai) == UNDERSCORE do ai = ai + 1 end
    while bi <= blen and byte(b, bi) == UNDERSCORE do bi = bi + 1 end
    if ai > alen and bi > blen then return true end
    if ai > alen or bi > blen then return false end
    if to_lower(byte(a, ai)) ~= to_lower(byte(b, bi)) then return false end
    ai, bi = ai + 1, bi + 1
  end
  while ai <= alen and byte(a, ai) == UNDERSCORE do ai = ai + 1 end
  while bi <= blen and byte(b, bi) == UNDERSCORE do bi = bi + 1 end
  return ai > alen and bi > blen
end

local function fuzzy_loop(query, q_len, name, name_len)
  if q_len > name_len then return 0 end

  local score = 0
  local q_idx = 1
  local prev_match = -2
  for i = 1, name_len do
    local nb = to_lower(byte(name, i))
    if q_idx <= q_len and nb == to_lower(byte(query, q_idx)) then
      score = score + 10

      if i == 1 then
        score = score + 20
      else
        local prev_b = byte(name, i - 1)
        if prev_b == UNDERSCORE or prev_b == HYPHEN or prev_b == SPACE then
          score = score + 20
        elseif is_lower(prev_b) and is_upper(byte(name, i)) then
          score = score + 20
        end
      end

      if i == prev_match + 1 then
        score = score + 15
      end

      prev_match = i
      q_idx = q_idx + 1
    end
  end

  if q_idx <= q_len then return 0 end

  score = score - math.floor(name_len / 10)
  return math.max(score, 1)
end

function M.fzf_score(query, name)
  local name_len = #name
  local q_len = #query

  if q_len == name_len then
    local ci_match = true
    local cs_match = true
    for i = 1, q_len do
      local qb, nb = byte(query, i), byte(name, i)
      if qb ~= nb then cs_match = false end
      if to_lower(qb) ~= to_lower(nb) then
        ci_match = false
        break
      end
    end
    if cs_match then return 10500 end
    if ci_match then return 10000 end
  end

  if underscore_eq(query, q_len, name, name_len) then
    return 9000
  end

  local primary = fuzzy_loop(query, q_len, name, name_len)

  local cross = 0
  if query:find('_', 1, true) then
    local stripped = query:gsub('_', '')
    local stripped_len = #stripped
    local s = fuzzy_loop(stripped, stripped_len, name, name_len)
    if s > 0 then cross = math.max(s - 5, 1) end
  end

  return math.max(primary, cross)
end

local function find_priority_indices(results, query, q_len)
  local priority = {}
  local total = #results
  for i = 1, total do
    local name = results[i].name or ''
    local name_len = #name
    if name_len >= q_len then
      local match = true
      for j = 1, q_len do
        if to_lower(byte(query, j)) ~= to_lower(byte(name, j)) then
          match = false
          break
        end
      end
      if match then priority[i] = true end
    end
  end
  return priority
end

function M.rank_and_limit(results, query)
  local total = #results
  if total == 0 then return {} end

  local q_len = #query

  local priority = find_priority_indices(results, query, q_len)

  local indices = {}
  for i, _ in pairs(priority) do
    indices[#indices + 1] = i
  end
  local slots_used = #indices
  for i = 1, total do
    if slots_used >= M.MAX_INPUT then break end
    if not priority[i] then
      indices[#indices + 1] = i
      slots_used = slots_used + 1
    end
  end

  local n = #indices

  local scores = {}
  for pos = 1, n do
    scores[pos] = M.fzf_score(query, results[indices[pos]].name or '')
  end

  local kind_pri = {}
  for pos = 1, n do
    local k = results[indices[pos]].kind or 0
    if k == M.SymbolKind.CLASS or k == M.SymbolKind.ENUM or k == M.SymbolKind.STRUCT or k == M.SymbolKind.INTERFACE then
      kind_pri[pos] = 1
    elseif k == M.SymbolKind.FUNCTION or k == M.SymbolKind.METHOD or k == M.SymbolKind.CONSTRUCTOR then
      kind_pri[pos] = 2
    else
      kind_pri[pos] = 3
    end
  end

  local positions = {}
  for pos = 1, n do positions[pos] = pos end
  table.sort(positions, function(a, b)
    if scores[a] ~= scores[b] then return scores[a] > scores[b] end
    return kind_pri[a] < kind_pri[b]
  end)

  local output = {}
  for rank = 1, math.min(n, M.MAX_RESULTS) do
    local pos = positions[rank]
    local s = scores[pos]
    if rank <= M.MIN_RESULTS or s >= M.SCORE_THRESHOLD then
      output[#output + 1] = results[indices[pos]]
    else
      break
    end
  end

  return output
end

return M
