let s:content = []
function! bufftree#Build()
	let dir = getcwd()
	let buffers=[]
	for b in range(1, bufnr('$'))
		let name = fnamemodify(buffer_name(b), ':p')
		if findfile(name, '') !=# name
			continue
		endif
		let name = substitute(name, dir.'/', './', '')
		let bu = { 'buffer': b , 'name': name}
		call add(buffers, bu)
	endfor
	let s:buffers = sort(buffers, "bufftree#Compare")
	let s:tree = {'dirs':[], 'name':'', 'files':[], 'level': -1}
	let s:current = s:tree
	let s:level = 0
	for bu in s:buffers
		let dirs = split(bu.name, '/')
		let len  = len(dirs)
		let s:current = s:tree
		for dir in dirs
			let index = index(dirs, dir)
			if index ==# len - 1
				let bu.dir  = bu.name
				let bu.name = dir
				call add(s:current.files, bu)
				break
			endif
			let idx = -1
			for ii in s:current.dirs
				if ii.name ==# dir
					let idx = index(s:current.dirs, ii)
					break
				endif
			endfor
			if idx ==# -1
				let nu = {'dirs':[], 'name':dir, 'files':[], 'level':index}
				call add(s:current.dirs, nu)
				let s:current = nu
			else
				let s:current = s:current.dirs[idx]
			endif
		endfor
	endfor
	let s:content = split(bufftree#Get(s:tree, 0, 0, ''), '\v\n')


	if bufwinnr('__BUFF_TREE__') ># -1
		call bufftree#Toggle()
	endif

"	call bufftree#Print(s:tree)
endfun
function! bufftree#Toggle()
	let winnr = bufwinnr('__BUFF_TREE__')
	if winnr ==# -1
		if len(s:content) ==# 0
			call bufftree#Build()
		endif
		vsplit __BUFF_TREE__
		setlocal filetype=bufftree
		setlocal buftype=nofile
		setlocal foldmethod=indent
	endif
	setlocal modifiable
	setlocal noreadonly
	normal! ggdG
	call append(0, s:content)
	normal! gg
	setlocal readonly
	setlocal nomodifiable
endfunction
function! bufftree#Get(tree, level, parentVisible, parentName)
	let content = ''
	let level = a:level
	let parentVisible = a:parentVisible
	let parentName    = a:parentName .'/'.a:tree.name
	if a:parentName ==# '/'
		if a:tree.name !=# '.'
			let parentName = '/'.a:tree.name
		else
			let parentName = a:tree.name
		endif
	endif
	if (parentVisible || len(a:tree.dirs) ># 1 || len(a:tree.files) ># 0)
		if a:tree.level > -1
			if parentVisible
				let parentName = a:tree.name
			endif
			let content .= bufftree#StrPad(parentName, level, 0)."\n"
			let parentVisible = 1
		else
			let level -= 1
		endif
	else
		let level -= 1
	endif
	let dirs = get(a:tree, 'dirs', [])
	for dir in dirs
		let content .= bufftree#Get(dir, level + 1, parentVisible, parentName)
	endfor
	for file in a:tree.files
		let content .= bufftree#StrPad(file.name, level + 1, 0).' ['.file.buffer.']'."\n"
		"echom bufftree#StrPad(file.dir, 4*a:tree.level + 4, 0)
	endfor
	return content
endfunction

function! bufftree#Print(tree)
	"if (len(a:tree.dirs) ># 1 || len(a:tree.files) ># 0)
		if a:tree.level > -1
			echom bufftree#StrPad(a:tree.name, 4*a:tree.level, 0)
		endif
	"endif
	let dirs = get(a:tree, 'dirs', [])
	for dir in dirs
		call bufftree#Print(dir)
	endfor
	for file in a:tree.files
		echom bufftree#StrPad(file.name, 4*a:tree.level + 4, 0).' ['.file.buffer.']'
		"echom bufftree#StrPad(file.dir, 4*a:tree.level + 4, 0)
	endfor
endfunction
function! bufftree#Compare(a, b)
	if a:a.name ==# a:b.name
		return 0
	endif
	if a:a.name =~# '^./' && a:b.name !~ '^./'
		return -1
	endif
	if a:b.name =~# '^./' && a:a.name !~ '^./'
		return 1
	endif
	let splitA = split(a:a.name, '/')
	let splitB = split(a:b.name, '/')
	let countA = len(splitA)
	let countB = len(splitB)
	let diff   = countA - countB

	if diff <# 0
		let splitC = splitA
		let splitD = splitB
		let countC = len(splitA)
		let countD = len(splitB)
	else
		let splitC = splitB
		let splitD = splitA
		let countC = len(splitB)
		let countD = len(splitA)
	endif

	for dir in splitC
		let ii = index(splitC, dir)
		if dir ==# splitD[ii]
			continue
		endif

		if ii ==# countC - 1
			if diff !=# 0
				return -1 * diff
			endif
			if diff <# 0
				if dir ># splitB[ii]
					return -1
				else
					return 1
				endif
			else
				if dir ># splitA[ii]
					return -1
				else
					return 1
				endif
			endif
		endif

		if diff <# 0
			if dir ># splitB[ii]
				return 1
			else
				return -1
			endif
		else
			if dir ># splitA[ii]
				return -1
			else
				return 1
			endif
		endif
	endfor

	return 0
endfun
function! bufftree#StrPad(s,amt, padLeft)
	if a:padLeft
		return repeat("\t", a:amt - len(a:s)).a:s
	else
		return repeat("\t", a:amt).a:s
	endif
endfunction
autocmd! BufNew * call bufftree#Build()
autocmd! BufUnload * call bufftree#Build()
command! BufferTreeBuild call bufftree#Build()
command! BufferTreeShow call bufftree#Toggle()
