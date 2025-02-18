local api = require('gemini.api')
local util = require('gemini.util')

local M = {}

local default_model_config = {
  model_id = api.MODELS.GEMINI_2_0_FLASH,
  temperature = 0.2,
  top_k = 20,
  max_output_tokens = 8196,
  response_mime_type = 'text/plain',
}

local default_chat_config = {
  enabled = true,
}

local default_instruction_config = {
  enabled = true,
  menu_key = '<Leader><Leader><Leader>g',
  prompts = {
    {
      name = 'Unit Test',
      command_name = 'GeminiUnitTest',
      menu = 'Unit Test 🚀',
      get_prompt = function(lines, bufnr)
        local code = vim.fn.join(lines, '\n')
        local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
        local prompt = 'Context:\n\n```%s\n%s\n```\n\n'
            .. 'Objective: Write unit test for the above snippet of code\n'
        return string.format(prompt, filetype, code)
      end,
    },
    {
      name = 'Code Review',
      command_name = 'GeminiCodeReview',
      menu = 'Code Review 📜',
      get_prompt = function(lines, bufnr)
        local code = vim.fn.join(lines, '\n')
        local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
        local prompt = 'Context:\n\n```%s\n%s\n```\n\n'
            .. 'Objective: Do a thorough code review for the following code.\n'
            .. 'Provide detail explaination and sincere comments.\n'
        return string.format(prompt, filetype, code)
      end,
    },
    {
      name = 'Code Explain',
      command_name = 'GeminiCodeExplain',
      menu = 'Code Explain',
      get_prompt = function(lines, bufnr)
        local code = vim.fn.join(lines, '\n')
        local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
        local prompt = 'Context:\n\n```%s\n%s\n```\n\n'
            .. 'Objective: Explain the following code.\n'
            .. 'Provide detail explaination and sincere comments.\n'
        return string.format(prompt, filetype, code)
      end,
    },
  }
}

local default_hints_config = {
  enabled = true,
  hints_delay = 2000,
  insert_result_key = '<S-Tab>',
  get_prompt = function(node, bufnr)
    local code_block = vim.treesitter.get_node_text(node, bufnr)
    local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
    local prompt = [[
Instruction: Use 1 or 2 sentences to describe what the following {filetype} function does:

```{filetype}
{code_block}
```
]]
    prompt = prompt:gsub('{filetype}', filetype)
    prompt = prompt:gsub('{code_block}', code_block)
    return prompt
  end
}

local default_completion_config = {
  enabled = true,
  blacklist_filetypes = { 'help', 'qf', 'json', 'yaml', 'toml' },
  blacklist_filenames = { '.env' },
  completion_delay = 600,
  insert_result_key = '<S-Tab>',
  move_cursor_end = false,
  get_system_text = function()
    return "You are a coding AI assistant that autocomplete user's code at a specific cursor location marked by <insert_here></insert_here>."
      .. '\nDo not wrap the code in ```'
  end,
  get_prompt = function(bufnr, pos)
    local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
    local prompt = 'Below is the content of a %s file `%s`:\n'
        .. '```%s\n%s\n```\n\n'
        .. 'Insert the most likely appear code at <insert_here></insert_here>.\n'
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local line = pos[1]
    local col = pos[2]
    local target_line = lines[line]
    if target_line then
      lines[line] = target_line:sub(1, col) .. '<insert_here></insert_here>' .. target_line:sub(col + 1)
    else
      return nil
    end
    local code = vim.fn.join(lines, '\n')
    local filename = vim.api.nvim_buf_get_name(bufnr)
    prompt = string.format(prompt, filetype, filename, filetype, code)
    return prompt
  end
}

M.set_config = function(opts)
  opts = opts or {}

  M.config = {
    model = vim.tbl_extend('force', default_model_config, opts.model_config or {}),
    chat = vim.tbl_extend('force', default_chat_config, opts.chat_config or {}),
    hints = vim.tbl_extend('force', default_hints_config, opts.hints or {}),
    completion = vim.tbl_extend('force', default_completion_config, opts.completion or {}),
    instruction = vim.tbl_extend('force', default_instruction_config, opts.instruction or {}),
  }
end

M.get_config = function(keys)
  return util.table_get(M.config, keys)
end

M.get_gemini_generation_config = function()
  return {
    temperature = M.get_config({ 'model', 'temperature' }) or 0.9,
    top_k = M.get_config({ 'model', 'top_k' }) or 1.0,
    max_output_tokens = M.get_config({ 'model', 'max_output_tokens' }) or 8196,
    response_mime_type = M.get_config({ 'model', 'response_mime_type' }) or 'text/plain',
  }
end

return M
