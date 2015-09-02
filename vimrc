set all& " reset all settings
let s:path = expand('<sfile>:p:h')
execute 'source ' . s:path . '/vimrc.plugins'
execute 'source ' . s:path . '/vimrc.settings'

