set normal (set_color normal)
set magenta (set_color magenta)
set yellow (set_color yellow)
set green (set_color green)
set red (set_color red)
set gray (set_color -o black)

# Fish git prompt
set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate 'yes'
set __fish_git_prompt_showuntrackedfiles 'yes'
set __fish_git_prompt_showupstream 'yes'
set __fish_git_prompt_color_branch yellow
set __fish_git_prompt_color_upstream_ahead green
set __fish_git_prompt_color_upstream_behind red

# Status Chars
set __fish_git_prompt_char_dirtystate '⚡'
set __fish_git_prompt_char_stagedstate '→'
set __fish_git_prompt_char_untrackedfiles '☡'
set __fish_git_prompt_char_stashstate '↩'
set __fish_git_prompt_char_upstream_ahead '+'
set __fish_git_prompt_char_upstream_behind '-'

set PATH $PATH ~/bin

function fish_prompt
  set last_status $status

  printf '[%s%s%s] ' (set_color green) (date "+%d.%m.%y %H:%S") (set_color normal)
  
  printf '%s@%s %s%s%s%s ' (whoami) (hostname | cut -d . -f 1) (set_color $fish_color_cwd) \
                            (echo $PWD) (set_color normal) (__fish_git_prompt)
    
  set_color normal

  set -l suffix

  switch $USER
  case root toor
    set_color red
    set suffix '#'
  case '*'
    set suffix '$'
  end

  echo -e "\n$suffix "(set_color normal)
end
