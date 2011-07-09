" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
autoload/screen.vim	[[[1
994
" Author: Eric Van Dewoestine <ervandew@gmail.com>
"
" License: {{{
"   Copyright (c) 2009 - 2011
"   All rights reserved.
"
"   Redistribution and use of this software in source and binary forms, with
"   or without modification, are permitted provided that the following
"   conditions are met:
"
"   * Redistributions of source code must retain the above
"     copyright notice, this list of conditions and the
"     following disclaimer.
"
"   * Redistributions in binary form must reproduce the above
"     copyright notice, this list of conditions and the
"     following disclaimer in the documentation and/or other
"     materials provided with the distribution.
"
"   * Neither the name of Eric Van Dewoestine nor the names of its
"     contributors may be used to endorse or promote products derived from
"     this software without specific prior written permission of
"     Eric Van Dewoestine.
"
"   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
"   IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
"   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
"   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
"   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
"   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
"   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
"   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
"   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
"   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
"   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
" }}}

let s:save_cpo=&cpo
set cpo&vim

" Script Variables {{{

  if has('win32') || has('win64') || has('win32unix')
    let s:terminals = ['bash']
  elseif has('mac') && has('gui_running')
    let s:terminals = ['Terminal.app']
  else
    let s:terminals = [
        \ 'gnome-terminal', 'konsole',
        \ 'urxvt', 'multi-aterm', 'aterm', 'mrxvt', 'rxvt',
        \ 'xterm',
      \ ]
  endif

" }}}

" ScreenShellCommands() {{{
function! screen#ScreenShellCommands()
  command -nargs=? -complete=shellcmd ScreenShell
    \ :call screen#ScreenShell('<args>', 'horizontal')
  command -nargs=? -complete=customlist,screen#CommandCompleteScreenSessions
    \ ScreenShellAttach :call screen#ScreenShellAttach('<args>')

  if !has('gui_running') &&
   \ !g:ScreenShellExternal &&
   \ (g:ScreenImpl == 'Tmux' || g:ScreenShellGnuScreenVerticalSupport != '')
    command -nargs=? -complete=shellcmd ScreenShellVertical
      \ :call screen#ScreenShell('<args>', 'vertical')
  endif
endfunction " }}}

" ScreenShell(cmd, orientation) {{{
" Open a split shell.
function! screen#ScreenShell(cmd, orientation)
  if g:ScreenImpl != 'GnuScreen' && g:ScreenImpl != 'Tmux'
    echohl WarningMsg
    echom 'Unsupported g:ScreenImpl value "' . g:ScreenImpl . '".  ' .
      \ 'Supported values included "GnuScreen" or "Tmux".'
    echohl Normal
    return
  endif

  if !s:screen{g:ScreenImpl}.isValid()
    return
  endif

  let s:orientation = a:orientation

  " Specifies a name to be supplied to vim's --servername arg when invoked in
  " a new screen session.
  if !exists('g:ScreenShellServerName')
    " Perform this here so that g:ScreenShellExternal can be set after vim
    " starts.
    let s:servername = g:ScreenShellExternal ? '' : 'vim'
  else
    let s:servername = g:ScreenShellServerName
  endif

  try
    let bootstrap = !has('gui_running') &&
      \ !exists('g:ScreenShellBootstrapped') &&
      \ expand('$TERM') !~ '^screen'

    " if using an external shell without the need to set the vim servername,
    " then don't bootstrap
    if bootstrap
      if g:ScreenShellExternal &&
       \ (s:servername == '' || g:ScreenImpl == 'Tmux' ||
       \  !has('clientserver') || has('win32') || has('win64'))
        let bootstrap = 0
      endif
    endif

    if bootstrap
      call s:ScreenBootstrap(a:cmd)
    else
      call s:ScreenInit(a:cmd)
    endif
  finally
    " wrapping in a try without catching anything just cleans up the vim error
    " produced by an exception thrown from one of the above functions.
  endtry
endfunction " }}}

" ScreenShellAttach(session) {{{
" Attach to an existing screen session.
function! screen#ScreenShellAttach(session)
  if !s:screen{g:ScreenImpl}.isValid()
    return
  endif

  let g:ScreenShellSession = s:screen{g:ScreenImpl}.attachSession(a:session)

  if g:ScreenShellSession != '0'
    if !exists(':ScreenSend')
      command -nargs=0 -range=% ScreenSend :call <SID>ScreenSend(<line1>, <line2>)
      let g:ScreenShellSend = s:ScreenSendFuncRef()
      let g:ScreenShellFocus = s:ScreenFocusFuncRef()
    endif

    if g:ScreenShellAttachTargetCurrent
      let g:ScreenShellWindow = 'screenshell'
      call s:screen{g:ScreenImpl}.setTitle()
    endif
  endif
endfunction " }}}

" s:ScreenBootstrap(cmd) {{{
" Bootstrap a new screen session.
function! s:ScreenBootstrap(cmd)
  try
    let g:ScreenShellBootstrapped = 1
    let g:ScreenShellSession = s:screen{g:ScreenImpl}.newSessionName()

    wa
    let save_sessionoptions = &sessionoptions
    set sessionoptions+=globals
    set sessionoptions-=tabpages
    let sessionfile = substitute(tempname(), '\', '/', 'g')
    exec 'mksession ' . sessionfile

    " when transitioning from windows vim to cygwin vim, the session file
    " needs to be purged of windows line endings.
    if has('win32') || has('win64')
      let winrestcmd = winrestcmd()
      try
        exec '1split ' . sessionfile
        set ff=unix
        exec "%s/\<c-m>$//g"
        wq
      finally
        exec winrestcmd
      endtry
    endif

    " support for taglist
    if exists(':TlistSessionSave') &&
     \ exists('g:TagList_title') &&
     \ bufwinnr(g:TagList_title)
      let g:ScreenShellTaglistSession = sessionfile . '.taglist'
      exec 'TlistSessionSave ' . g:ScreenShellTaglistSession
      exec 'silent! !echo "Tlist | TlistSessionLoad ' .
        \ g:ScreenShellTaglistSession . '" >> "' . sessionfile . '"'
    endif

    let bufend = bufnr('$')
    let bufnum = 1
    while bufnum <= bufend
      if bufnr(bufnum) != -1
        call setbufvar(bufnum, 'save_swapfile', getbufvar(bufnum, '&swapfile'))
        call setbufvar(bufnum, '&swapfile', 0)

        " suppress prompt and auto reload changed files for the user when
        " returning to this vim session
        augroup screenshell_filechanged
          exec 'autocmd! FileChangedShell <buffer=' . bufnum . '>'
          exec 'autocmd FileChangedShell <buffer=' . bufnum . '> ' .
            \ 'let v:fcs_choice = (v:fcs_reason == "changed" ? "reload" : "ask") | ' .
            \ 'autocmd! screenshell_filechanged FileChangedShell <buffer=' . bufnum . '>'
        augroup END
      endif
      let bufnum = bufnum + 1
    endwhile

    " supply a servername when starting vim if supported
    let server = ''
    if has('clientserver') && s:servername != ''
      let server = '--servername "' . s:servername . '" '
    endif

    " when transitioning from windows console vim to cygwin vim, we don't know
    " if the cygwin version support clientserver, so error on the safe side
    " (in my environment the cygwin vim doesn't support client server).
    if has('win32') || has('win64')
      let server = ''
    endif

    call s:screen{g:ScreenImpl}.bootstrap(server, sessionfile, a:cmd)
  finally
    redraw!

    unlet g:ScreenShellBootstrapped

    " if there was an error writing files, then we didn't get far enough to
    " need this cleanup.
    if exists('save_sessionoptions')
      let &sessionoptions = save_sessionoptions
      call delete(sessionfile)

      " remove taglist session file
      if exists('g:ScreenShellTaglistSession')
        call delete(g:ScreenShellTaglistSession)
      endif

      redraw!

      let possible_detach = 0
      let bufnum = 1
      let winrestcmd = winrestcmd()
      new
      try
        while bufnum <= bufend
          if bufnr(bufnum) != -1
            try
              call setbufvar(bufnum, '&swapfile', getbufvar(bufnum, 'save_swapfile'))
            catch /E325/
              let possible_detach = 1
              exec 'buffer ' . bufnum
              try
                redraw
                edit
              catch
              endtry
            endtry
          endif
          let bufnum = bufnum + 1
        endwhile
      finally
        quit!
        exec winrestcmd
      endtry

      if possible_detach
        echohl WarningMsg
        echom 'Warning: detatching from a screen session started by ' .
            \ ':ScreenShell may result in conflicting swap files like those ' .
            \ 'just encountered. Due to this possibility, detaching from a ' .
            \ 'screen session started by :ScreenShell is discouraged.  ' .
            \ 'Instead you should issue a :ScreenQuit or exit the vim ' .
            \ 'instance in screen normally (:qa)'
        echohl None
      endif
    endif
  endtry
endfunction " }}}

" s:ScreenInit(cmd) {{{
" Initialize the current screen session.
function! s:ScreenInit(cmd)
  let g:ScreenShellWindow = 'screenshell'
  " use a portion of the command as the title, if supplied
  "if a:cmd != '' && a:cmd !~ '^\s*vim\>'
  "  let g:ScreenShellWindow = s:ScreenCmdName(a:cmd)[:15]
  "endif

  " when already running in a screen session, never use an external shell
  let external = !exists('g:ScreenShellBootstrapped') &&
        \ expand('$TERM') =~ '^screen' ? 0 : g:ScreenShellExternal
  " w/ gvim always use an external shell
  let external = has('gui_running') ? 1 : external

  if exists('g:ScreenShellBootstrapped') || external
    command -nargs=0 ScreenQuit :call <SID>ScreenQuit(0)
    if g:ScreenShellQuitOnVimExit
      augroup screen_shell
        autocmd!
        autocmd VimLeave * call <SID>ScreenQuit(1)
      augroup END
    endif
  endif

  " use screen regions
  if !external
    let result = s:screen{g:ScreenImpl}.openRegion()

    if !v:shell_error && a:cmd != ''
      let result = s:screen{g:ScreenImpl}.send(a:cmd)
    endif

  " use an external terminal
  else
    let g:ScreenShellSession = exists('g:ScreenShellSession') ?
      \ g:ScreenShellSession : s:screen{g:ScreenImpl}.newSessionName()

    " This block should only be hit in console mode with external terminal +
    " vim server name set.
    " Not supported by tmux since it doesn't appear that you can have
    " more than one terminal connected to a session without them all
    " focusing the same window.
    if !has('gui_running') &&
     \ exists('g:ScreenShellBootstrapped') &&
     \ g:ScreenImpl != 'Tmux'

      let result = s:screen{g:ScreenImpl}.newWindow(0)

      if !v:shell_error
        let result = s:screen{g:ScreenImpl}.newTerminalMulti()

        if !v:shell_error && result != '0' && a:cmd != ''
          let result = s:screen{g:ScreenImpl}.send(a:cmd)
        endif
      endif

    else
      let result = s:screen{g:ScreenImpl}.newTerminal()
      if has('win32') || has('win64') || has('win32unix') || has('mac')
        " like, the sleep hack below, but longer for windows.
        sleep 3000m
      else
        " looks like this is needed for ubuntu as well... ugg.
        sleep 1000m
      endif

      if !v:shell_error && result != '0'
        " Hack, but should be plenty of time to let screen get to a state
        " where it will apply the title command.
        sleep 500m
        let result = s:screen{g:ScreenImpl}.setTitle()

        " execute the supplied command if any
        if !v:shell_error && a:cmd != ''
          let result = s:screen{g:ScreenImpl}.send(a:cmd)
        endif
      endif
    endif
  endif

  if v:shell_error
    delcommand ScreenQuit
    echoerr result
  else
    if !exists(':ScreenSend')
      command -nargs=0 -range=% ScreenSend :call <SID>ScreenSend(<line1>, <line2>)
      let g:ScreenShellSend = s:ScreenSendFuncRef()
      let g:ScreenShellFocus = s:ScreenFocusFuncRef()
      " remove :ScreenShell command to avoid accidentally calling it again.
      delcommand ScreenShell
      delcommand ScreenShellAttach
      if exists(':ScreenShellVertical')
        delcommand ScreenShellVertical
      endif

      " Hook for creating keybindings (or similar)
      let g:ScreenShellActive = 1
      let g:ScreenShellCmd = a:cmd
      try
        doautoall ScreenShellEnter User
      catch /E216/
      endtry
    endif
  endif
endfunction " }}}

" s:ScreenSend(string or list<string> or line1, line2) {{{
" Send lines to the screen shell.
function! s:ScreenSend(...)
  if a:0 == 1
    let argtype = type(a:1)
    if argtype == 1
      let lines = split(a:1, "\n")
    elseif argtype == 3
      let lines = a:1
    else
      echoe 'ScreenShell: Argument must be a string or list.'
      return
    endif
  elseif a:0 == 2
    if type(a:1) != 0 || type(a:2) != 0
      echoe 'ScreenShell: Arguments must be positive integer line numbers.'
      return
    endif

    let lines = getline(a:1, a:2)
    let mode = visualmode(1)
    if mode != '' && line("'<") == a:1
      if mode == "v"
        let start = col("'<") - 1
        let end = col("'>") - 1
        " slice in end before start in case the selection is only one line
        let lines[-1] = lines[-1][: end]
        let lines[0] = lines[0][start :]
      elseif mode == "\<c-v>"
        let start = col("'<")
        if col("'>") < start
          let start = col("'>")
        endif
        let start = start - 1
        call map(lines, 'v:val[start :]')
      endif
    endif
  else
    echoe 'ScreenShell: Invalid number of arguments for ScreenSend.'
    return
  endif

  if g:ScreenShellExpandTabs
    let expanded = ''
    let index = 0
    while index < &shiftwidth
      let expanded .= ' '
      let index += 1
    endwhile
    call map(lines, 'substitute(v:val, "\\t", expanded, "g")')
  endif

  let tmp = tempname()
  call writefile(lines, tmp)
  try
    let result = s:screen{g:ScreenImpl}.sendTempBuffer(tmp)
  finally
    call delete(tmp)
  endtry

  if v:shell_error
    echoerr result
  endif
endfunction " }}}

" s:ScreenFocus() {{{
function! s:ScreenFocus()
  let result = s:screen{g:ScreenImpl}.focus()

  if v:shell_error
    echoerr result
  endif
endfun " }}}

" s:ScreenSendFuncRef() {{{
function! s:ScreenSendFuncRef()
  let sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_ScreenSendFuncRef$')
  return function(printf('<SNR>%s_ScreenSend', sid))
endfun " }}}

" s:ScreenFocusFuncRef() {{{
function! s:ScreenFocusFuncRef()
  let sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_ScreenFocusFuncRef$')
  return function(printf('<SNR>%s_ScreenFocus', sid))
endfun " }}}

" s:ScreenQuit(onleave) {{{
" Quit the current screen session (short cut to manually quiting vim and
" closing all screen windows.
function! s:ScreenQuit(onleave)
  if exists('g:ScreenShellBootstrapped')
    if !a:onleave
      wa
    endif

    let bufend = bufnr('$')
    let bufnum = 1
    while bufnum <= bufend
      if bufnr(bufnum) != -1
        call setbufvar(bufnum, '&swapfile', 0)
      endif
      let bufnum = bufnum + 1
    endwhile
  else
    call screen#ScreenShellCommands()
    delcommand ScreenQuit
    delcommand ScreenSend
    unlet g:ScreenShellSend
    unlet g:ScreenShellFocus
    augroup screen_shell
      autocmd!
    augroup END

    " Hook for creating keybindings (or similar)
    let g:ScreenShellActive = 0
    let g:ScreenShellCmd = ''
    try
      doautoall ScreenShellExit User
    catch /E216/
    endtry
  endif

  let result = s:screen{g:ScreenImpl}.quit()

  if v:shell_error
    if result !~ 'No screen session found'
      echoerr result
    endif
  endif
endfunction " }}}

" s:ScreenCmdName(cmd) {{{
" Generate a name for the given command.
function! s:ScreenCmdName(cmd)
  let cmd = substitute(a:cmd, '^\s*\(\S\+\)\s.*', '\1', '')
  " if the command is a path to one, use the tail of the path
  if cmd =~ '/'
    let cmd = fnamemodify(cmd, ':t')
  endif
  return cmd
endfunction " }}}

" s:StartTerminal(command) {{{
function! s:StartTerminal(command)
  let terminal = s:GetTerminal()
  if !s:ValidTerminal(terminal)
    echoerr 'Unable to find a terminal, please set g:ScreenShellTerminal'
    return
  endif

  " handle using cygwin bash
  if has('win32') || has('win64') || has('win32unix')
    let result = ''
    let command = 'start "' . terminal . '"'
    if has('win32unix')
      let command = substitute(command, '\', '/', 'g')
      let command = 'cmd /c ' . command
    endif
    let command .= ' --login -c "' . a:command . '"'
    exec 'silent !' . command
    redraw!

  elseif has('mac') && has('gui_running')
    let result = ''
    exec s:MacGuiCmd(a:command, terminal)

  " gnome-terminal needs quotes around the screen call, but konsole and
  " rxvt based terms (urxvt, aterm, mrxvt, etc.) don't work properly with
  " quotes.  xterm seems content either way, so we'll treat gnome-terminal
  " as the odd ball here.
  elseif terminal == 'gnome-terminal'
    let result = system(terminal . ' -e "' . a:command . '" &')

  else
    let result = system(terminal . ' -e ' . a:command . ' &')
  endif
  return result
endfunction " }}}

" s:GetScreenSessions() {{{
" Gets a list of screen [session, state] pairs.
function! s:GetScreenSessions()
  let results = split(system('screen -wipe'), "\n")
  call filter(results, 'v:val =~ "(\\w\\+)"')
  call map(results, '[' .
    \ 'substitute(v:val, "^\\s*\\(\\S*\\).*", "\\1", ""), ' .
    \ 'tolower(substitute(v:val, "(\\(\\w\\+\\))$", "\\1", ""))]')
  return results
endfunction " }}}

" s:GetSize() {{{
function! s:GetSize()
  if s:orientation == 'vertical'
    let size = g:ScreenShellWidth
    let sizefunc = 'winwidth'
  else
    let size = g:ScreenShellHeight
    let sizefunc = 'winheight'
  endif

  if size <= 0
    exec 'let size = ' . sizefunc . '(winnr()) / 2'
  endif
  return size
endfunction " }}}

" s:GetTerminal() {{{
" Generate a name for the given command.
function! s:GetTerminal()
  if g:ScreenShellTerminal == ''
    for term in s:terminals
      if s:ValidTerminal(term)
        let g:ScreenShellTerminal = term
        break
      endif
    endfor
  endif
  return g:ScreenShellTerminal
endfunction " }}}

" s:ValidTerminal(term) {{{
function! s:ValidTerminal(term)
  if a:term == ''
    return 0
  endif

  " assumes that Terminal.app, or whatever the user may have set, is available
  if has('mac') && has('gui_running')
    return 1
  endif

  if has('win32unix')
    if !executable(a:term)
      let term = substitute(a:term, '\', '/', 'g')
      let term = substitute(system('cygpath "' . term . '"'), '\n', '', 'g')
      return executable(term)
    endif
  endif

  return executable(a:term)
endfunction " }}}

" s:MacGuiCmd(cmd, term) {{{
function! s:MacGuiCmd(cmd, term)
  if a:term != '0'
    return 'silent !osascript -e "tell application \"' . a:term .
      \ '\"" -e "do script \"' . a:cmd . '\"" -e "end tell"'
  endif

  let cmd = substitute(a:cmd, '"', "'", 'g')
  return 'silent !osascript -e "do shell script \"' . cmd . '\""'
endfunction " }}}

" CommandCompleteScreenSessions(argLead, cmdLine, cursorPos) {{{
function! screen#CommandCompleteScreenSessions(argLead, cmdLine, cursorPos)
  let cmdLine = strpart(a:cmdLine, 0, a:cursorPos)
  let cmdTail = strpart(a:cmdLine, a:cursorPos)
  let argLead = substitute(a:argLead, cmdTail . '$', '', '')

  if g:ScreenImpl == 'GnuScreen'
    let sessions = s:GetScreenSessions()
    if has('win32') || has('win64') || has('win32unix')
      call filter(sessions, 'v:val[1] != "detached"')
    endif
    call map(sessions, 'v:val[0]')
    if cmdLine !~ '[^\\]\s$'
      call filter(sessions, 'v:val =~ "^' . argLead . '"')
    endif

    return sessions
  endif

  return []
endfunction " }}}

let s:screenGnuScreen = {}

function s:screenGnuScreen.isValid() dict " {{{
  if !executable('screen')
    echoerr 'gnu screen not found in your path'
    return 0
  endif
  return 1
endfunction " }}}

function s:screenGnuScreen.attachSession(session) dict " {{{
  let sessions = s:GetScreenSessions()
  if a:session != ''
    let session = []
    for s in sessions
      if s[0] == a:session
        let session = s
        break
      endif
    endfor

    if len(session) == 0
      echoerr 'unable to find the gnu screen session "' . a:session . '"'
      return
    endif
  elseif len(sessions) > 0
    if has('win32') || has('win64') || has('win32unix')
      call filter(sessions, 'v:val[1] != "detached"')
    endif
    let session = sessions[0]
  else
    echoerr 'unable to find any gnu screen sessions'
    return
  endif

  if session[1] == 'detached'
    if has('win32') || has('win64') || has('win32unix')
      echoerr 'attaching to a session in the "Detached" state is not ' .
        \ 'supported on windows due to deficiencies in the cygwin version ' .
        \ 'of gnu screen.'
      return
    endif
    let result = s:screen{g:ScreenImpl}.newTerminalResume()
    if result == '0'
      return
    endif
    if v:shell_error
      echoerr result
    endif
  endif

  return session[0]
endfunction " }}}

function s:screenGnuScreen.bootstrap(server, sessionfile, cmd) dict " {{{
  let vertical = s:orientation == 'vertical' ? 'Vertical' : ''
  exec 'silent! !screen -S ' . g:ScreenShellSession .
    \ ' vim ' . a:server .
    \ '-c "silent source ' . escape(a:sessionfile, ' ') . '" ' .
    \ '-c "ScreenShell' . vertical . ' ' . a:cmd . '"'
endfunction " }}}

function s:screenGnuScreen.newSessionName() dict " {{{
  return substitute(tempname(), '\W', '', 'g')
endfunction " }}}

function s:screenGnuScreen.newTerminal() dict " {{{
  return s:StartTerminal('screen -S ' . g:ScreenShellSession)
endfunction " }}}

function s:screenGnuScreen.newTerminalMulti() dict " {{{
  return s:StartTerminal('screen -S ' . g:ScreenShellSession . ' -x')
endfunction " }}}

function s:screenGnuScreen.newTerminalResume() dict " {{{
  return s:StartTerminal('screen -r ' . g:ScreenShellSession)
endfunction " }}}

function s:screenGnuScreen.newWindow(focus) dict " {{{
  return self.exec(printf(
    \ '-X eval "screen -t %s" %s',
    \ g:ScreenShellWindow,
    \ a:focus ? '""' : '"other"'))
endfunction " }}}

function s:screenGnuScreen.openRegion() dict " {{{
  let splitcmd = 'split'
  if s:orientation == 'vertical'
    if g:ScreenShellGnuScreenVerticalSupport == 'patch'
      let splitcmd = 'vert_split'
    elseif g:ScreenShellGnuScreenVerticalSupport == 'native'
      let splitcmd = 'split -v'
    else
      echohl WarningMsg
      echom 'Unsupported g:ScreenShellGnuScreenVerticalSupport value "' .
        \ g:ScreenShellGnuScreenVerticalSupport . '". ' .
        \ 'Supported values included "patch" or "native".'
      echohl Normal
      let s:orientation = ''
    endif
  endif

  let focus = g:ScreenShellInitialFocus == 'shell' ? '' : ' "focus up"'
  let chdir = exists('g:ScreenShellBootstrapped') ? '' : '"chdir \"' . getcwd() . '\"" '
  let result = self.exec('-X eval ' .
    \ '"' . splitcmd . '" ' .
    \ '"focus down" ' .
    \ '"resize ' . s:GetSize() . '" ' .
    \ chdir .
    \ '"screen -t ' . g:ScreenShellWindow . '"' .
    \ focus)

  " if we ran a chdir, reset it
  if chdir != ''
    call self.exec('-X eval "chdir"')
  endif

  return result
endfunction " }}}

function s:screenGnuScreen.setTitle() dict " {{{
  return self.exec('-X title ' . g:ScreenShellWindow)
endfunction " }}}

function s:screenGnuScreen.send(value) dict " {{{
  let tmp = tempname()
  call writefile([a:value], tmp)
  try
    let result = s:screen{g:ScreenImpl}.sendTempBuffer(tmp)
  finally
    call delete(tmp)
  endtry
  return result
endfunction " }}}

function s:screenGnuScreen.sendTempBuffer(tmp) dict " {{{
  if exists('g:ScreenShellWindow')
    let result = self.exec(
      \ '-p ' . g:ScreenShellWindow .  ' -X eval ' .
      \ '"msgminwait 0" ' .
      \ '"msgwait 0" ' .
      \ '"readbuf ' . a:tmp . '" ' .
      \ '"at ' . g:ScreenShellWindow . ' paste ." ' .
      \ '"msgwait 5" ' .
      \ '"msgminwait 1"')
  else
    let result = self.exec(
      \ '-X eval ' .
      \ '"msgminwait 0" ' .
      \ '"msgwait 0" ' .
      \ '"readbuf ' . a:tmp . '" ' .
      \ '"paste ." ' .
      \ '"msgwait 5" ' .
      \ '"msgminwait 1"')
  endif
  return result
endfunction " }}}

function s:screenGnuScreen.focus() dict " {{{
  return self.exec('-X focus bottom')
endfunction " }}}

function s:screenGnuScreen.quit() dict " {{{
  return self.exec('-X quit')
endfunction " }}}

function s:screenGnuScreen.exec(cmd) dict " {{{
  let cmd = 'screen '
  if exists('g:ScreenShellSession')
    let cmd .= '-S ' . g:ScreenShellSession . ' '
  endif
  let cmd .= a:cmd

  if has('win32unix')
    let result = ''
    exec 'silent! !' . cmd
    redraw!
  elseif has('mac') && has('gui_running')
    let term = s:GetTerminal()
    let result = ''
    exec s:MacGuiCmd(cmd, '0')
  else " system() works for windows gvim too
    let result = system(cmd)
  endif
  return result
endfunction " }}}

let s:screenTmux = {}

function s:screenTmux.isValid() dict " {{{
  if !executable('tmux')
    echoerr 'tmux not found in your path'
    return 0
  endif

  if has('win32') || has('win64')
    echoerr 'ScreenShell does not currently support tmux on windows.'
    return 0
  endif

  return 1
endfunction " }}}

function s:screenTmux.attachSession(session) dict " {{{
  " TODO: currently unable to implement this since we use -S which creates a
  " new server, which a tmux list-sessions wouldn't be able to talk to.  As
  " for sessions created on the default server, we can get the list of
  " sessions, but tmux doesn't appear to have a way to send commands targeting
  " a specific session, which is why we use -S to target servers.
  echom 'Attaching to an existing session is currently not supported with tmux.'
  return
endfunction " }}}

function s:screenTmux.bootstrap(server, sessionfile, cmd) dict " {{{
  let vertical = s:orientation == 'vertical' ? 'Vertical' : ''
  exec printf('silent! !tmux %s -S %s new-session ' .
    \ '"vim %s -c \"silent source %s\" -c \"ScreenShell' . vertical . ' %s\""',
    \ g:ScreenShellTmuxInitArgs, g:ScreenShellSession,
    \ a:server, escape(a:sessionfile, ' '), a:cmd)
endfunction " }}}

function s:screenTmux.newSessionName() dict " {{{
  return tempname()
endfunction " }}}

function s:screenTmux.newTerminal() dict " {{{
  return s:StartTerminal(printf(
    \ 'tmux %s -S %s', g:ScreenShellTmuxInitArgs, g:ScreenShellSession))
endfunction " }}}

function s:screenTmux.newTerminalResume() dict " {{{
  return s:StartTerminal(printf(
    \ 'tmux %s -S %s  attach-session',
    \ g:ScreenShellTmuxInitArgs, g:ScreenShellSession))
endfunction " }}}

function s:screenTmux.newWindow(focus) dict " {{{
  return self.exec('new-window -n ' . g:ScreenShellWindow . (a:focus ? '' : ' -d'))
endfunction " }}}

function s:screenTmux.openRegion() dict " {{{
  let orient = s:orientation == 'vertical' ? '-h ' : ''
  let direction = s:orientation == 'vertical' ? '-L ' : '-U'
  let focus = g:ScreenShellInitialFocus == 'shell' ? '' : (' ; select-pane ' . direction)
  let result = self.exec(
    \ 'split ' .  orient . '-l ' . s:GetSize() . ' ; ' .
    \ 'rename-window ' . g:ScreenShellWindow .
    \ focus)
  if v:shell_error
    return result
  endif
endfunction " }}}

function s:screenTmux.setTitle() dict " {{{
  return self.exec('rename-window ' . g:ScreenShellWindow)
endfunction " }}}

function s:screenTmux.send(value) dict " {{{
  let tmp = tempname()
  call writefile([a:value], tmp)
  try
    let result = s:screen{g:ScreenImpl}.sendTempBuffer(tmp)
  finally
    call delete(tmp)
  endtry
  return result
endfunction " }}}

function s:screenTmux.sendTempBuffer(tmp) dict " {{{
  let result = self.focusWindow()
  if v:shell_error
    return result
  endif

  " hacky: how can we be sure the shell is at pane index 1 and vim at index 0?
  if exists('g:ScreenShellWindow') && !g:ScreenShellExternal
    call self.exec('select-pane -t 1')
  endif
  let result = self.exec(printf(
    \ 'load-buffer %s ; ' .
    \ 'paste-buffer', a:tmp
    \ ))
  if exists('g:ScreenShellWindow') && !g:ScreenShellExternal
    call self.exec('select-pane -t 0')
  endif

  return result
endfunction " }}}

function s:screenTmux.focus() dict " {{{
  return self.exec('select-pane -D')
endfunction " }}}

function s:screenTmux.quit() dict " {{{
  return self.exec('kill-session')
endfunction " }}}

function s:screenTmux.exec(cmd) dict " {{{
  let tmux = 'tmux '
  let cmd = a:cmd

  if exists('g:ScreenShellSession')
    let tmux .= '-S ' . g:ScreenShellSession . ' '
  endif

  " hack to account for apparent bug in tmux when redirecting stdout to a file
  " when attempting to list windows
  if cmd =~ 'list-windows'
    let cmd .= ' | cat'
  endif

  return system(tmux . escape(cmd, ';'))
endfunction " }}}

function s:screenTmux.focusWindow() dict " {{{
  if !exists('g:ScreenShellWindow')
    return
  endif

  let result = self.exec('list-windows')
  if v:shell_error
    return result
  endif

  let windows = filter(
    \ split(result, "\n"),
    \ 'v:val =~ "^\\s*\\d\\+:\\s\\+' . g:ScreenShellWindow . '"')
  if len(windows)
    let window = substitute(windows[0], '^\s*\(\d\+\):.*', '\1', '')
    return self.exec('select-window -t:' . window)
  endif
endfunction " }}}

let &cpo = s:save_cpo

" vim:ft=vim:fdm=marker
doc/screen.txt	[[[1
390
*screen.txt*

Author: Eric Van Dewoestine <ervandew@gmail.com>

This plugin is licensed under the terms of the BSD License.  Please see
screen.vim for the license in its entirety.

-----------------------------------------------------------------------------
Screen                                      *screen*

Introduction                         |screen-intro|
Screen Usage                         |screen-usage|
  :ScreenShell                       |screen-shell|
  :ScreenShellAttach                 |screen-shellattach|
  :ScreenSend                        |screen-send|
  :ScreenQuit                        |screen-quit|
Screen Options                       |screen-options|
  Terminal muliplexer                |screen-impl|
  Shell height                       |screen-shellheight|
  Quit on exit                       |screen-quitonexit|
  External shell                     |screen-externalshell|
  Server name                        |screen-servername|
  Terminal                           |screen-terminal|
Custom mappings                      |screen-mappings|
Script integration                   |screen-scriptintegration|
Gotchas                              |screen-gotchas|
Troubleshooting                      |screen-troubleshooting|

-----------------------------------------------------------------------------
Introduction                                *screen-intro*

This plugin aims to simulate an embedded shell in vim by allowing you to
easily convert your current vim session into one running in gnu screen with a
split gnu screen window containing a shell, and to quickly send
statements/code to whatever program is running in that shell (bash, python,
irb, etc.).  Spawning the shell in your favorite terminal emulator is also
supported for gvim users or anyone else that just prefers an external shell.

Currently tested on Linux and Windows (win32 gvim and cygwin vim), but
should also work on any unix based platform where screen is supported (OSX,
BSD, Solaris, etc.).  Note that in my testing of cygwin, invocations of screen
were significantly slower and less fluid than on Linux.  The Windows
experience is better when using gvim to spawn a cygwin shell running screen.

Tmux Users: On non-windows systems, tmux is also supported in place of gnu
screen.  To use tmux simply add the following to your vimrc:
  let g:ScreenImpl = 'Tmux'

  Note: With tmux, :ScreenShellAttach is currently not supported.

Windows Users: Whether you are using gvim or not, you will need cygwin
installed with cygwin's bin directory in your windows PATH.

-----------------------------------------------------------------------------
Screen usage                                *screen-usage*

Here is a sample workflow utilizing screen.vim to execute some python code in
the python interactive interpreter:

  1. Edit a python file
     $ vim something.py

  2. Decide you want to run all or pieces of the code in an interactive python
     shell
     :ScreenShell python

  3. Send code from a vim buffer to the shell
     :ScreenSend

  4. Quit the screen session and return to your original vim session
    :ScreenQuit
      or
    :qa

Below is a comprehensive list of the commands which screen.vim provides:

:ScreenShell [cmd]                  *screen-shell* *:ScreenShell*
  Starts a screen hosted shell performing the following steps depending on
  your environment.

  When running a console vim on a unix based OS (Linux, BSD, OSX):
    1. save a session file from your currently running vim instance
       (current tab only)
    2. start gnu screen with vim running in it
    3. load your saved session file
    4. create a lower gnu screen split window and start a shell, or if
       g:ScreenShellExternal is set, start an external terminal with
       screen running.
    5. if a command was supplied to :ScreenShell, run it in the new
       shell.
       Ex. :ScreenShell ipython

    Note: If you are already in a gnu screen session, then only steps
          4 and 5 above will be run.

  When running gvim:
    1. start an external terminal with screen running.
    2. if a command was supplied to :ScreenShell, run it in the new
       shell.
       Ex. :ScreenShell ipython

:ScreenShellVertical [cmd]     *screen-shell-vertical* *:ScreenShellVertical*
  Just like |:ScreenShell| but when creating the split region for the shell, a
  vertical split is used instead of the default horizontal split.  Supported
  via tmux by default, but gnu screen requires the vertical split patch
  (http://fungi.yuggoth.org/vsp4s/) or the unreleased screen 4.1 code and you
  must explicitly enable support for gnu screen vertical splitting in
  screen.vim by adding the following to your vimrc, indicating whether you are
  using a patched gnu screen or the 4.1 code base:
    let g:ScreenShellGnuScreenVerticalSupport = 'patch'
      or
    let g:ScreenShellGnuScreenVerticalSupport = 'native'


:ScreenShellAttach [session]        *screen-shellattach* *:ScreenShellAttach*
  Sets the necessary internal variables to allow :ScreenSend invocations to
  send to the specified screen session.  If no session is provided, then the
  first session found is used.  If the session is in the "Detached" state,
  then a new terminal is opened with a new screen instance attached to the
  session. Attaching to a detached session is not currently supported on
  windows due to deficiencies in the cygwin version of gnu screen.

  Note: for screen sessions attached to via this mechanism, :ScreenSend
  invocations will send the text to the active screen window instead of
  targeting the 'shell' window when used from :ScreenShell.  However, this
  behavior can be configured via the g:ScreenShellAttachTargetCurrent
  variable, which when non 0, will set the title on the currently focused gnu
  screen window and target it for all send commands.

:ScreenSend
  Send the visual selection or the entire buffer contents to the running gnu
  screen shell window.

:ScreenQuit
  Save all currently modified vim buffers and quit gnu screen, returning you
  to your previous vim instance running outside of gnu screen

  Note: :ScreenQuit is not available if you where already in a gnu
    screen session when you ran :ScreenShell.
  Note: By default, if the gnu screen session was started by
    :ScreenShell, then exiting vim will quit the gnu screen session as
    well (configurable via g:ScreenShellQuitOnVimExit).


-----------------------------------------------------------------------------
Screen Options                              *screen-options*

Screen is configured via several global variables that you can set in your
|vimrc| file according to your needs. Below is a comprehensive list of the
variables available.

Terminal Multiplexer                        *screen-impl*
                                            *g:ScreenImpl*

g:ScreenImpl (default value: 'GnuScreen')

This sets the name of the terminal multiplexer you want to use.  Support
values include 'GnuScreen' or 'Tmux'.


Shell height                                *screen-shellheight*
                                            *g:ScreenShellHeight*

g:ScreenShellHeight (default value: 15)

Sets the height of the gnu screen (or tmux) region used for the shell.  When
the value is less than or equal to 0, then half of vim's reported window
height will be used.


Shell width                                 *screen-shellwidth*
                                            *g:ScreenShellWidth*

g:ScreenShellWidth (default value: -1)

Sets the width of the gnu screen (or tmux) region used for the shell when
splitting the region vertically (vertical split support in gnu screen requires
the vertical split patch).  When the value is less than or equal to 0, then
half of vim's reported window width will be used.


Quit on exit                                *screen-quitonexit*
                                            *g:ScreenShellQuitOnVimExit*

g:ScreenShellQuitOnVimExit (default value: 1)

When non-zero and the gnu screen (or tmux) session was started by this script,
the screen session will be closed when vim exits.


External Shell                              *screen-externalshell*
                                            *g:ScreenShellExternal*

g:ScreenShellExternal (default value: 0)

When non-zero and not already in a screen session, an external shell will be
spawned instead of using a split region for the shell.  Note: when using gvim,
an external shell is always used.


Initial focus                               *screen-focus*
                                            *g:ScreenShellInitialFocus*

g:ScreenShellInitialFocus (default value: 'vim')

When set to 'shell' the newly created shell region will be focused when first
creating the shell region.


Server Name                                 *screen-servername*
                                            *g:ScreenShellServerName*

g:ScreenShellServerName (default value: 'vim')

If the gnu screen session is started by this plugin, then the value of this
setting will be used for the servername arg of the vim instance started in the
new gnu screen session (not applicable for gvim users).  The default is 'vim'
unless you have g:ScreenShellExternal enabled, in which case, if you still
want to restart vim in a screen session with a servername, then simply set
this variable in your vimrc.


Terminal                                    *screen-terminal*
                                            *g:ScreenShellTerminal*

g:ScreenShellTerminal (default value: '')

When g:ScreenShellExternal is enabled or you are running gvim, this value will
be used as the name of the terminal executable to be used.  If this value is
empty, a list of common terminals will be tried until one is found.


Expand Tabs                                 *screen-expandtabs*
                                            *g:ScreenShellExpandTabs*

g:ScreenShellExpandTabs (default value: 0)

When sending text from vim to an external program, that program may interpret
tabs as an attempt to perform completion resulting in the text sent not
performing the function you intended.  As a work around, you can set this
setting to a non 0 value resulting in all tabs being expanded to spaces before
sending the text to screen/tmux.

-----------------------------------------------------------------------------
Custom Mappings                             *screen-mappings*

Defining custom key mappings for for screen.vim can be accomplished like with
any other plugin: >
  nmap <C-c><C-c> :ScreenShell<cr>
>

But you may want to have different mappings depending on the whether you have
an active screen shell open or not. For this case screen.vim provides a couple
autocmd groups which you can use to listen for entering or exiting of a screen
shell session.  Here is an example which sets some global key bindings based
on the screen shell state: >

  function! s:ScreenShellListener()
    if g:ScreenShellActive
      nmap <C-c><C-c> :ScreenSend<cr>
      nmap <C-c><C-x> :ScreenQuit<cr>
    else
      nmap <C-c><C-c> :ScreenShell<cr>
    endif
  endfunction

  nmap <C-c><C-c> :ScreenShell<cr>
  augroup ScreenShellEnter
    autocmd User * call <SID>ScreenShellListener()
  augroup END
  augroup ScreenShellExit
    autocmd User * call <SID>ScreenShellListener()
  augroup END
>

You can also take this a step further and do the same as the above, but do so
on a per filetype basis, where the key binding are buffer local and interact
with the filetype's associated interpreter. Here is an example which can be
put in a python ftplugin: >

  function! s:ScreenShellListener()
    if g:ScreenShellActive
      if g:ScreenShellCmd == 'python'
        nmap <buffer> <C-c><C-c> :ScreenSend<cr>
      else
        nmap <buffer> <C-c><C-c> <Nop>
      endif
    else
      nmap <buffer> <C-c><C-c> :ScreenShell python<cr>
    endif
  endfunction

  call s:ScreenShellListener()
  augroup ScreenShellEnter
    autocmd User *.py call <SID>ScreenShellListener()
  augroup END
  augroup ScreenShellExit
    autocmd User *.py call <SID>ScreenShellListener()
  augroup END
>

Note how the :ScreenShell mapping starts the python interpreter. Before
mapping the :ScreenSend command, the function also checks if the shell was
started with the 'python' command, allowing you to unmap (<Nop> in this case
to counter act any global defined mapping) the send command if some other
shell command is running (irb, lisp interpreter, etc).

-----------------------------------------------------------------------------
Script Integration                          *screen-scriptintegration*

To permit integration with your own, or 3rd party, scripts, a funcref is made
globally available while the screen shell mode is enabled, allowing you to
send your own strings to the attached shell.

Here are some examples of using this funcref to send some commands to bash: >
  :call ScreenShellSend("echo foo\necho bar")
  :call ScreenShellSend('echo -e "foo\nbar"')
  :call ScreenShellSend("echo -e \"foo\\nbar\"")
>

Sending a list of strings is also supported: >
  :call ScreenShellSend(["echo foo", "echo bar"])
>

You can test that the funcref exists using: >
   exists('ScreenShellSend')
>

In addition to sending text to the screen shell, another funcref is available
allowing you to focus the shell region in screen.  Note: focusing an external
screen shell is not supported.

To focus the shell region from vim you can invoke the funcref like so: >
  :call ScreenShellFocus()
>

This will focus the bottom most region which is expected to be the one running
your shell or other program.


-----------------------------------------------------------------------------
Gotchas                                     *screen-gotchas*

While running vim in gnu screen, if you detach the session instead of
quitting, then when returning to the non-screen vim, vim will complain about
swap files already existing.  So try to avoid detaching.

Not all vim plugins support saving state to or loading from vim session files,
so when running :ScreenShell some buffers may not load correctly if they are
backed by such a plugin.


-----------------------------------------------------------------------------
Troubleshooting                             *screen-troubleshooting*

Below are a list of possible issues you may encounter and some info on
resolving those issues.

- When already in a screen session, running :ScreenShell results in a nested
  screen session instead of using the existing one.
                                            *screen-bootstrap*

  When running :ScreenShell from a console version of vim, screen.vim examines
  the $TERM environment variable which it expects to start with 'screen'
  ('screen', 'screen-256color', etc.) if you are in an existing screen/tmux
  session.  Should the TERM value not start with 'screen', then screen.vim
  assumes that a screen session must be started for you.

  The cause of TERM not containing a 'screen' values is usually the result of
  having a non-screen term value in your ~/.screenrc or the term value you are
  using doesn't have a corresponding terminfo file resulting in $TERM being
  set to some other value. Take a look at the |screen-256color| docs below for
  more information.

- 256 color support                         *screen-256color*

  To enable 256 color support in screen you'll need to add the following to
  your ~/.screenrc:

    term screen-256color

  Please note that this will set your $TERM to 'screen-256color' which will
  require that your system has a corresponding terminfo file.  Not all systems
  have this installed by default so you may need to install an additional
  package:

    ubuntu - $ apt-get install ncurses-term


vim:tw=78:ts=8:ft=help:norl:
plugin/screen.vim	[[[1
161
" Author: Eric Van Dewoestine <ervandew@gmail.com>
" Version: 1.4
" GetLatestVimScripts: 2711 1 :AutoInstall: screen.vim
"
" Description: {{{
"   This plugin aims to simulate an embedded shell in vim by allowing you to
"   easily convert your current vim session into one running in gnu screen
"   with a split gnu screen window containing a shell, and to quickly send
"   statements/code to whatever program is running in that shell (bash,
"   python, irb, etc.).  Spawning the shell in your favorite terminal emulator
"   is also supported for gvim users or anyone else that just prefers an
"   external shell.
"
" }}}
"
" License: {{{
"   Copyright (c) 2009 - 2011
"   All rights reserved.
"
"   Redistribution and use of this software in source and binary forms, with
"   or without modification, are permitted provided that the following
"   conditions are met:
"
"   * Redistributions of source code must retain the above
"     copyright notice, this list of conditions and the
"     following disclaimer.
"
"   * Redistributions in binary form must reproduce the above
"     copyright notice, this list of conditions and the
"     following disclaimer in the documentation and/or other
"     materials provided with the distribution.
"
"   * Neither the name of Eric Van Dewoestine nor the names of its
"     contributors may be used to endorse or promote products derived from
"     this software without specific prior written permission of
"     Eric Van Dewoestine.
"
"   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
"   IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
"   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
"   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
"   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
"   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
"   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
"   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
"   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
"   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
"   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
" }}}

let s:save_cpo=&cpo
set cpo&vim

" Global Variables {{{

  let g:ScreenVersion = '1.4'
  let g:ScreenShellActive = 0
  let g:ScreenShellCmd = ''

  if !exists('g:ScreenImpl')
    let g:ScreenImpl = 'GnuScreen'
    "let g:ScreenImpl = 'Tmux'
  endif

  if !exists('g:ScreenShellTmuxInitArgs')
    let g:ScreenShellTmuxInitArgs = ''
  endif

  " Sets the height of the gnu screen (or tmux) region used for the shell.
  if !exists('g:ScreenShellHeight')
    let g:ScreenShellHeight = 15
  endif

  " Sets the width of the screen window used for the shell.
  if !exists('g:ScreenShellWidth')
    let g:ScreenShellWidth = -1
  endif

  " Specifies whether or not to quit gnu screen when vim is closed and the
  " screen session was started via :ScreenShell.
  if !exists('g:ScreenShellQuitOnVimExit')
    let g:ScreenShellQuitOnVimExit = 1
  endif

  " When not 0, open the spawned shell in an external window (not currently
  " supported when running in cygwin).
  if !exists('g:ScreenShellExternal')
    let g:ScreenShellExternal = 0
  endif

  " Sets whether to focus 'vim' or the 'shell' when a shell region is opened.
  if !exists('g:ScreenShellInitialFocus')
    let g:ScreenShellInitialFocus = 'vim'
  endif

  " When g:ScreenShellExternal is set, this variable specifies the preferred
  " shell to use.  If not set, some common terminals will be tried.
  if !exists('g:ScreenShellTerminal')
    let g:ScreenShellTerminal = ''
  endif

  " Sets whether, and using which method, gnu screen supports vertical splits
  if !exists('g:ScreenShellGnuScreenVerticalSupport')
    let g:ScreenShellGnuScreenVerticalSupport = ''
  endif

  " Sets whether the current screen region should be targeted when attaching
  " to an existing screen session.
  if !exists('g:ScreenShellAttachTargetCurrent')
    let g:ScreenShellAttachTargetCurrent = 0
  endif

  " Sets whether tabs should be expand to prevent completion attempts by the
  " target application when sending text to it.
  if !exists('g:ScreenShellExpandTabs')
    let g:ScreenShellExpandTabs = 0
  endif

" }}}

" Commands {{{

  if !exists(':ScreenShell')
    " unfortunately, to reap the benefits of an autoload scripts, we can't
    " call this, but instead have to copy the commands inline.
    "call screen#ScreenShellCommands()

    command -nargs=? -complete=shellcmd ScreenShell
      \ :call screen#ScreenShell('<args>', 'horizontal')
    command -nargs=? -complete=customlist,screen#CommandCompleteScreenSessions
      \ ScreenShellAttach :call screen#ScreenShellAttach('<args>')

    if !has('gui_running') &&
     \ !g:ScreenShellExternal &&
     \ (g:ScreenImpl == 'Tmux' || g:ScreenShellGnuScreenVerticalSupport != '')
      command -nargs=? -complete=shellcmd ScreenShellVertical
        \ :call screen#ScreenShell('<args>', 'vertical')
    endif
  endif

" }}}

" Autocmds {{{

  " while nice for vim screen window titles, this can kind of screw things up
  " since when exiting vim there could now be more than one screen window with
  " the title 'shell'.
  "if expand('$TERM') =~ '^screen'
  "  augroup vim_screen
  "    autocmd!
  "    autocmd VimEnter,BufWinEnter,WinEnter *
  "      \ exec "silent! !echo -ne '\\ek" . expand('%:t') . "\\e\\\\'"
  "    autocmd VimLeave * exec "silent! !echo -ne '\\ekshell\\e\\\\'"
  "  augroup END
  "endif

" }}}

let &cpo = s:save_cpo

" vim:ft=vim:fdm=marker
