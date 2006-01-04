" perl_synwrite.vim : check syntax of Perl before writing
" author : Ricardo Signes <rjbs-vim@public.manxome.org>
" $Id: /my/rjbs/conf/vim/perl_synwrite.vim 17215 2006-01-04T23:15:46.674588Z rjbs  $

""" to make syntax checking happen automatically on write, set
""" perl_synwrite_au; this is quirky, though, and isn't really advised
""" failing that, this script will map :Write to act like :write, but 
""" check syntax before writing;  :W[rite]! will write even if the syntax
""" check fails

""" if you have installed Vi::QuickFix (1.124 or later) you can assign
""" a true value to perl_synwrite_qf to use it to provide quickfix data
""" for the buffer

""" You can use the following lines to set perl_synwrite_qf automatically based
""" on whether it is likely to work:
"""   silent call system("perl -e0 -MVi::QuickFix")
"""   let perl_synwrite_qf = ! v:shell_error

"" abort if b:did_perl_synwrite is true: already loaded or user pref
if exists("b:did_perl_synwrite")
	finish
endif
let b:did_perl_synwrite = 1

"" set buffer :au pref: if defined globally, inherit; otherwise, false
if (exists("perl_synwrite_au") && !exists("b:perl_synwrite_au"))
	let b:perl_synwrite_au = perl_synwrite_au
elseif !exists("b:perl_synwrite_au")
	let b:perl_synwrite_au = 0
endif

"" set buffer quickfix pref: if defined globally, inherit; otherwise, false
if (exists("perl_synwrite_qf") && !exists("b:perl_synwrite_qf"))
	let b:perl_synwrite_qf = perl_synwrite_qf
elseif !exists("b:perl_synwrite_qf")
	let b:perl_synwrite_qf = 0
endif

"" execute the given do_command if the buffer is syntactically correct perl
"" -- or if do_anyway is true
function! s:PerlSynDo(do_anyway,do_command)
  let command = "!perl -c"

	if (b:perl_synwrite_qf)
    " this env var tells Vi::QuickFix to replace "-" with actual filename
		let $VI_QUICKFIX_SOURCEFILE=expand("%")
    let command = command . " -MVi::QuickFix"
	endif

  " respect taint checking
  if (match(getline(1), "^#!.\\+perl.\\+-T") == 0)
    let command = command . " -T"
  endif

  echo command
  " we need to cat here because :exec would add a space between ! and command
  " let to_exec = "write !" . command
  exec "write" command

	silent! cgetfile " try to read the error file
	if !v:shell_error || a:do_anyway
		exec a:do_command
		set nomod
	endif
endfunction

"" set up the autocommand, if b:perl_synwrite_au is true
if (b:perl_synwrite_au > 0)
	let b:undo_ftplugin = "au! perl_synwrite * " . expand("%")

	augroup perl_synwrite
		exec "au BufWriteCmd,FileWriteCmd " . expand("%") . " call s:PerlSynDo(0,\"write <afile>\")"
	augroup END
endif

"" the :Write command
command -buffer -nargs=* -complete=file -range=% -bang Write call s:PerlSynDo("<bang>"=="!","<line1>,<line2>write<bang> <args>")
