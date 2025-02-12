let g:chatgpt_model = get(g:, 'chatgpt_model', 'gpt-4o')
let g:chatgpt_system_marker = get(g:, 'chatgpt_system_marker', '-----🤖-----')
let g:chatgpt_user_marker = get(g:, 'chatgpt_user_marker', '-----✍------')
let g:chatgpt_system_message = get(g:, 'chatgpt_system_message', 'Please summarize the following.')
let g:chatgpt_cli_command_paths = get(g:, 'chatgpt_cli_command_paths', expand('<sfile>:p:h:h') . '/commands')

" Append the CLI path to system $PATH if not already included
if $PATH !~ g:chatgpt_cli_command_paths
  let $PATH .= ':' . g:chatgpt_cli_command_paths
endif

command! -range=% ChatGPT call chatgpt#send_selected_range(<line1>, <line2>)
command! DiffWithinCodeBlock :call chatgpt#diff_within_code_block()
