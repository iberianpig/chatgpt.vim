# Vim ChatGPT Plugin

This Vim plugin allows users to interact directly with OpenAI's ChatGPT from within their Vim text editor. It provides a convenient way to send code or text selections to ChatGPT and display responses within Vim.

## Features

- **Send Selected Code/Text:** Easily transmit selected lines of text to ChatGPT.
- **Asynchronous Operations:** Utilize asynchronous job execution to keep the Vim editor responsive while waiting for ChatGPT's response.
- **Session Logging:** Save ChatGPT session logs for future reference.
- **Code Block Diffing:** Create diffs within code blocks to identify and review changes.

## Directory Structure

```
.
├── autoload
│   └── chatgpt.vim
├── commands
│   ├── cat-repo
│   ├── gh-issue
│   └── gh-pr
└── plugin
    └── chatgpt.vim
```

### File Overview

- **autoload/chatgpt.vim**: Defines Vim functions for sending selected text to ChatGPT asynchronously, cleaning ANSI escape codes, and more.
  
- **commands/cat-repo**: Script to display files in a specified Git repository.

- **commands/gh-issue**: Script to view a GitHub issue and its comments using the GitHub CLI.

- **commands/gh-pr**: Script to view a GitHub pull request, view diffs, and comments.

- **plugin/chatgpt.vim**: Contains the plugin settings and defines commands for interacting with ChatGPT and generating code block diffs.

## Requirements

- Vim with support for job-control (`+job`).
- [chatgpt-cli](https://github.com/kojix2/chatgpt-cli) installed and accessible in your system's PATH.
- A valid OpenAI API key accessible by the kojix2/chatgpt-cli.

## Installation

1. **Install kojix2/chatgpt-cli:** Follow the installation instructions from the [kojix2/chatgpt-cli GitHub repository](https://github.com/kojix2/chatgpt-cli) and ensure it is in your system's PATH.

2. **Clone the Plugin:**

Using [Vim-Plug](https://github.com/junegunn/vim-plug) or another Vim plugin manager, add the following to your `.vimrc` or `init.vim`:

```vim
Plug 'your-username/vim-chatgpt'
```
Run `:PlugInstall` within Vim.

3. **Configuration:**
   Add the following configurations to your Vim configuration file:

```vim
" Sample ChatGPT settings
let g:chatgpt_system_message = 'Please summarize the following. The response should be in "Japanese."'
let g:chatgpt_model = 'gpt-4o'
let g:chatgpt_system_marker = '-----🤖-----'
let g:chatgpt_user_marker = '-----✍------'

" Command to search ChatGPT session history
command! -bang -nargs=* ChatGPTHistories
     \ call fzf#vim#grep("rg --column --line-number --no-heading --color=always --smart-case --glob '*.md' ".shellescape(<q-args>), 1,
     \ fzf#vim#with_preview({'dir': expand('~/.config/chatgpt-cli/history'), 'options': ['--layout=reverse']}), <bang>0)

" Mapping to send selected text to ChatGPT
vnoremap ,a :ChatGPT<CR>
" Mapping to activate ChatGPT in normal mode
noremap ,a :ChatGPT<CR>
" Mapping to view ChatGPT session history
noremap ,h :ChatGPTHistories!<CR>
" Mapping to create a diff within a code block
nnoremap <leader>d :call DiffWithinCodeBlock()<CR>
```

## Troubleshooting

- Ensure the [chatgpt commands](https://github.com/kojix2/chatgpt-cli/) are in your PATH. If not, check the path and adjust your shell configuration.
- Review error logs in `/tmp/vim-chatgpt-err.log` for job errors.

## License

This plugin is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more information.
