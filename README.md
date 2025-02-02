# Vim ChatGPT Plugin

This Vim plugin allows users to interact directly with OpenAI's ChatGPT from within their Vim text editor. It provides a convenient way to send code or text selections to ChatGPT and display responses within Vim.

[![asciicast](https://asciinema.org/a/5GesY9uJe6BDL6pesN5B9dd36.svg)](https://asciinema.org/a/5GesY9uJe6BDL6pesN5B9dd36)

## Features

- **Send Selected Code/Text:** Send selected lines of code or text and display ChatGPT's response in a split window to the right.
- **Asynchronous Operations:** Maintain Vim editor responsiveness by utilizing asynchronous job execution while waiting for ChatGPT's response.
- **Session Logging:** Save ChatGPT session logs to resume interactions at a later time.
- **Code Block Diffing:** Create and review `diffthis` within code blocks enclosed by triple backticks.
- **Text Expansion:** Utilize `%!{ command }` to expand the content of the text sent to ChatGPT.

The plugin includes the following utility commands:

```bash
# %!{ command } to customize and expand the content of the text sent to ChatGPT.

# Display the file structure and contents within a local repository.
$ cat-repo /path/to/local/repo

# Retrieve and display comments from a GitHub Issue.
$ gh-issue https://github.com/iberianpig/fusuma/issues/173 

# Retrieve and display diffs and comments from a GitHub Pull Request.
$ gh-pr http://github.com/iberianpig/chatgpt.vim/pulls/1 
```

```bash
## You can also combine your favorite %!{ command } with ChatGPT to enhance your workflow.
# Convert HTML retrieved with the curl command to markdown with html2markdown
$ curl https://github.com/iberianpig/chatgpt.vim | html2markdown
```

## Requirements

- Vim with support for job-control (`+job`).
- [kojix2/chatgpt-cli](https://github.com/kojix2/chatgpt-cli) installed and accessible in your system's PATH.
- A valid OpenAI API key accessible by the [kojix2/chatgpt-cli](https://github.com/kojix2/chatgpt-cli)

## Installation

### Install kojix2/chatgpt-cli

Follow the installation instructions from the [kojix2/chatgpt-cli GitHub repository](https://github.com/kojix2/chatgpt-cli) and ensure it is in your system's PATH.

### Setup the Plugin

Using [Vim-Plug](https://github.com/junegunn/vim-plug) or another Vim plugin manager, add the following to your `.vimrc` or `init.vim`:

```vim
Plug 'iberianpig/chatgpt.vim'
```
Run `:PlugInstall` within Vim.

**Configuration:**
   Add the following configurations to your Vim configuration file:

```vim
" Sample ChatGPT settings
let g:chatgpt_system_message = 'Please summarize the following. The response should be in "Japanese."'
let g:chatgpt_model = 'gpt-4o'
let g:chatgpt_system_marker = '-----🤖-----'
let g:chatgpt_user_marker = '-----✍------'

" Send selected text to ChatGPT
vnoremap ,a :ChatGPT<CR>
" Send current buffer to ChatGPT
noremap ,a :ChatGPT<CR>
" Jump to ChatGPT session history
noremap ,h :ChatGPTHistories!<CR>
" Create a diff within a code block
nnoremap ,d :call DiffWithinCodeBlock()<CR>
```

Below is the configuration for using [FZF](https://github.com/junegunn/fzf.vim) to search through ChatGPT session histories:

```vim
" Command for searching through ChatGPT session histories
command! -bang -nargs=* ChatGPTHistories
     \ call fzf#vim#grep("rg --column --line-number --no-heading --color=always --smart-case --glob '*.md' ".shellescape(<q-args>), 1,
     \ fzf#vim#with_preview({'dir': expand('~/.config/chatgpt-cli/history'), 'options': ['--layout=reverse']}), <bang>0)
```

## Troubleshooting

- Ensure [chatgpt command](https://github.com/kojix2/chatgpt-cli/) is in your PATH. If not, check the path and adjust your shell configuration.
- Review error logs in `/tmp/vim-chatgpt-err.log` for job errors.

## License

This plugin is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more information.
