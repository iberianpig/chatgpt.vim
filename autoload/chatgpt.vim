" Completion function for agent selection
function! chatgpt#agent_completion(ArgLead, CmdLine, CursorPos) abort
  let l:agents = keys(g:chatgpt_agents)
  if a:ArgLead == ''
    return l:agents
  endif
  return filter(l:agents, 'v:val =~ "^" . a:ArgLead')
endfunction

" Get system message for an agent
function! chatgpt#get_agent_message(agent) abort
  if has_key(g:chatgpt_agents, a:agent)
    return g:chatgpt_agents[a:agent]
  endif
  return a:agent
endfunction

function! chatgpt#send_selected_range(startline, endline) abort
  let l:command = 'chatgpt -M ' . g:chatgpt_model

  let l:startline = a:startline
  let l:resume_file = expand('%:p') . '.post_data.json'

  if filereadable(l:resume_file)
    let l:command = l:command . ' -l ' . l:resume_file

    " Save current cursor position, search for user marker, and restore position
    let l:save_pos = getpos('.')
    call cursor(1, 1)
    let l:markerline = search('^' . g:chatgpt_user_marker . '$', 'bnw')
    call setpos('.', l:save_pos)
    if l:markerline == a:endline
      echomsg 'ChatGPT canceled: Write something to send after ' . g:chatgpt_user_marker
      return
    endif
    let l:startline = l:markerline + 1
  else
    " Prompt for agent selection or custom system message when no resume file is found
    try
      cnoremap <buffer> <silent> <Esc> __CANCELED__<CR>
      let l:input = input('System Message (or agent: ' . join(keys(g:chatgpt_agents), '/') . '): ', '', 'customlist,chatgpt#agent_completion')
      let l:input = l:input =~# '__CANCELED__$' ? 0 : l:input
    catch /^Vim:Interrupt$/
      let l:input = -1
    finally
      silent! cnoremap <buffer> <Esc>

      " If input is canceled, exit the function
      if l:input ==# '0' || l:input ==# '-1'
        echomsg 'ChatGPT canceled'
        return
      endif
    endtry

    " Use the provided system message, agent message, or a default one
    if l:input ==# ''
      let l:system_message = g:chatgpt_system_message
    else
      let l:agent_message = chatgpt#get_agent_message(l:input)
      let l:system_message = shellescape(l:agent_message, 1)
    endif
    let l:command = l:command . ' -s ' . '"' . l:system_message . '"'
  endif

  let l:current_file = expand('%:p')
  " Create a timestamp for session logging and ensure directory exists
  let l:timestamp = strftime("%Y%m%d%H%M%S")
  " find the git root directory

  if l:current_file =~# '\.response\.md$'
    let l:base_directory = fnamemodify(l:current_file, ':h')
  else
    let l:git_root = trim(system('git rev-parse --show-toplevel 2> /dev/null'))
    if v:shell_error == 0 && l:git_root != ''
      " If in a git repository, use the git root directory for history
      let l:base_directory = l:git_root . '/.chatgpt_history'
    else
      let l:base_directory = expand('~/.config/chatgpt-cli/history')
    endif
  endif

  if l:current_file =~# l:base_directory . '/.*\.response\.md$'
    exec 'edit ' . l:current_file

    let l:outputfile = l:current_file
    call append(line('$'), ["", g:chatgpt_system_marker, ""])
  else
    let l:new_dir = l:base_directory . '/' . l:timestamp
    call mkdir(l:new_dir, "p")
    let l:outputfile = l:new_dir . '/' . 'chatgpt' . '.response.md'
    exec 'vsplit ' . l:outputfile
    call setline(1, [l:system_message, "", g:chatgpt_system_marker, ""])
    exec 'wincmd p'
  endif

  " Start an asynchronous job to execute the command and handle input/output
  call job_start(l:command, {
        \ 'in_io': 'buffer',
        \ 'in_buf': bufnr('%'),
        \ 'in_top': l:startline,
        \ 'in_bot': a:endline,
        \ 'out_io': 'buffer',
        \ 'out_buf': bufnr(l:outputfile),
        \ 'err_io' : 'file',
        \ 'err_name': '/tmp/vim-chatgpt-err.log',
        \ 'exit_cb': function('chatgpt#job_callback', [l:outputfile]),
        \ })
endfunction

" Callback after the job completes to handle the output
function! chatgpt#job_callback(outputfile, job, status) abort
  echomsg 'Chat GPT request finished. status: ' . a:status . ' outputfile: ' . a:outputfile

  " If the job was unsuccessful, append an error message
  if a:status != 0
    call setbufline(bufnr(a:outputfile), '$', ['', 'Chat GPT request failed', '', 'see /tmp/vim-chatgpt-err.log for details'])
    return
  endif

  call chatgpt#delete_ansi_and_replace_hr(a:outputfile)
  call appendbufline(bufnr(a:outputfile), '$', ['', g:chatgpt_user_marker, ''])

  if bufnr('%') == bufnr(a:outputfile)
    call cursor(1, 1)
  endif
  let l:system_markerline = search('^' . g:chatgpt_system_marker . '$', 'bnw')
  if l:system_markerline > 0
    if bufnr('%') == bufnr(a:outputfile)
      call cursor(l:system_markerline, 1)
    endif
  endif

  " Save a copy of the post data
  let l:post_data = expand('~/.config/chatgpt-cli/post_data.json')
  let l:post_data_json = a:outputfile . '.post_data.json'
  call system('cp ' . l:post_data . ' ' . l:post_data_json)

  echomsg 'Chat GPT response received'
endfunction

" Remove ANSI escape sequences and format horizontal rules
function! chatgpt#delete_ansi_and_replace_hr(filepath)
  if a:filepath == ''
    let a:filepath = expand('%:p')
  endif

  " Delete ANSI escape codes from the file
  call setbufline(bufnr(a:filepath), 1, map(getbufline(a:filepath, 1, '$'), {k,v -> substitute(v, '\%x1b\[[0-9;]*[a-zA-Z]', '', 'g')}))
  " Replace long horizontal lines with Markdown code block markers
  call setbufline(bufnr(a:filepath), 1, map(getbufline(a:filepath, 1, '$'), {k,v -> substitute(v, '─\{3,}\([A-z]*\)?*\s*$', '```\1', 'g')}))
endfunction

" Function to create a diff within code blocks marked by triple backticks
function! chatgpt#diff_within_code_block()
  let l:startline = search('^```', 'bnW')
  let l:endline = search('^```', 'nW')

  " Check if code block exists
  if l:startline == 0 || l:endline == 0
    echoerr " No code block found. Please check your cursor position."
    return
  endif

  " Retrieve the lines of the code block
  let l:code_block = getline(l:startline + 1, l:endline - 1)
  let l:buffer_name = 'code_block'
  let l:buffer_number = bufnr(l:buffer_name)

  " Delete previous buffer with the same name if it exists
  if l:buffer_number != -1
    execute 'bdelete ' . l:buffer_number
  endif

  " Open a new buffer for diffing the code block
  enew
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile

  echomsg "Creating a new buffer named " . l:buffer_name
  execute "file " . l:buffer_name

  call setline(1, l:code_block)
  setlocal filetype=diff
  windo diffthis
endfunction
