###############
# Environment #
###############

export EDITOR="vim"

###############
# Aliases     #
###############


################
# History      #
################
setopt histignorealldups sharehistory

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

[[ -n "${key[PageUp]}"   ]]  && bindkey  "${key[PageUp]}"    history-beginning-search-backward
[[ -n "${key[PageDown]}" ]]  && bindkey  "${key[PageDown]}"  history-beginning-search-forward

################
# Completion   #
################
# Use modern completion system
autoload -Uz compinit
compinit

zstyle ':completion:*' list-colors ''

zstyle ':completion:*' menu select
eval "$(dircolors -b)"
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,user,%cpu,tty,cputime,cmd'

##############
# VCS        #
##############
begin_with() {
    local string="${1}"
    shift
    local element=''
    for element in "$@"; do
        if [[ "${string}" =~ "^${element}" ]]; then
            return 0
        fi
    done
    return 1

}

git_check_if_worktree() {
    # This function intend to be only executed in chpwd().
    # Check if the current path is in git repo. 

    # We would want stop this function, on some big git repos it can take some time to cd into.
    if [ -n "${skip_zsh_git}" ]; then
        git_pwd_is_worktree='false'
        return 1
    fi
    # The : separated list of paths where we will run check for git repo.
    # If not set, then we will do it only for /root and /home.
    if [ "${UID}" = '0' ]; then
        # running 'git' in repo changes owner of git's index files to root, skip prompt git magic if CWD=/home/*
        git_check_if_workdir_path="${git_check_if_workdir_path:-/root:/etc}"
    else
        git_check_if_workdir_path="${git_check_if_workdir_path:-/home}"
        git_check_if_workdir_path_exclude="${git_check_if_workdir_path_exclude:-${HOME}/_sshfs}"
    fi

    if begin_with "${PWD}" ${=git_check_if_workdir_path//:/ }; then
        if ! begin_with "${PWD}" ${=git_check_if_workdir_path_exclude//:/ }; then
            local git_pwd_is_worktree_match='true'
        else
            local git_pwd_is_worktree_match='false'
        fi
    fi

    if ! [ "${git_pwd_is_worktree_match}" = 'true' ]; then
        git_pwd_is_worktree='false'
        return 1
    fi

    # todo: Prevent checking for /.git or /home/.git, if PWD=/home or PWD=/ maybe...
    #   damn annoying RBAC messages about Access denied there.
    if [ -d '.git' ] || [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = 'true' ]; then
        git_pwd_is_worktree='true'
        git_worktree_is_bare="$(git config core.bare)"
    else
        unset git_branch git_worktree_is_bare
        git_pwd_is_worktree='false'
    fi
}

chpwd() {
    git_check_if_worktree
}

display_counter() {
  local counter=${1}
  local format="${fg[red]}"
  
  if [ ${counter} = 0 ]; then
    format="${fg[green]}"
  fi
  
  format="${format}(${counter})${reset_color}"

  echo ${format}
}

function prompt_precmd {
  local commits_ahead=0
  local deleted=0
  local modified=0
  local staged=0
  local sum=0
  local untracked=0
  
  if [ "${git_pwd_is_worktree}" = 'true' ]; then 
    local status_file_list="$(git status --porcelain)"
    commits_ahead=$(git rev-list @{u}..HEAD | wc -l)

    while IFS= read -r line; do
        local pattern="${line:0:2}"

        if [ "${pattern}" = " D" ]; then
           deleted=$((deleted + 1))
        fi

        if [ "${pattern}" = " M" ]; then
           modified=$((modified + 1))
        fi

        if [ "${pattern}" = '??' ]; then
           untracked=$((untracked + 1))
        fi

	if [ "${pattern}" = "M " ] || [ "${pattern}" = "A " ] || [ "${pattern}" = "D " ] || [ "${pattern}" = "R " ] || [ "${pattern}" = "C " ]; then
	   staged=$((staged +1))
        fi 
    done <<< "$status_file_list"

    sum=$((staged + deleted + modified + untracked))

    local staged_status
    
    if [ ${staged} -lt ${sum} ]; then
      staged_status="${fg_bold[red]}☆"
    else
      staged_status="${fg_bold[green]}★"
    fi

    staged_status="${staged_status}(${staged}/${sum})${reset_color}"

    local filestatus="∣ ${staged_status} ${fg[red]}×${reset_color}$(display_counter ${deleted}) ${fg[yellow]}≠${reset_color}$(display_counter ${modified}) ${fg[cyan]}?${reset_color}$(display_counter ${untracked})"
    local branch="${fg_bold[yellow]}%b%i${reset_color}%f ∣ ⬆$(display_counter ${commits_ahead})"

    branch_format="[${branch} ${filestatus}]"

    zstyle ':vcs_info:*:prompt:*' formats "${branch_format}"
	
  fi

  vcs_info 'prompt'
}


###############
# Prompt      #
###############
setopt promptsubst

function prompt_setup {
  # Load required functions.
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info
  autoload -U colors && colors

  # Add hook for calling vcs_info before each command.
  add-zsh-hook precmd prompt_precmd

  # Formats:
  #   %b - branchname
  #   %u - unstagedstr (see below)
  #   %c - stagedstr (see below)
  #   %a - action (e.g. rebase-i)
  #   %R - repository path
  #   %S - path in the repository
  local branch_format=" (${fg_bold[yellow]}%b%f%u%c)"
  local action_format=" (%a%f)"
  local unstaged_format=" ${fg[red]}●%f"
  local staged_format=" ${fg[green]}●%f"

  # Set vcs_info parameters.
  zstyle ':vcs_info:*' enable bzr git hg svn
  zstyle ':vcs_info:*:prompt:*' check-for-changes true
  zstyle ':vcs_info:*:prompt:*' unstagedstr "${unstaged_format}"
  zstyle ':vcs_info:*:prompt:*' stagedstr "${staged_format}"
  zstyle ':vcs_info:*:prompt:*' actionformats "${branch_format}${action_format}"
  zstyle ':vcs_info:*:prompt:*' formats "${branch_format}"
  zstyle ':vcs_info:*:prompt:*' nvcsformats   ""

  NEWLINE=$'\n'


  PROMPT='%(!.%{$fg_bold[red]%}.%{$fg_bold[cyan]%})%n%{$reset_color%}@%{$fg_bold[blue]%}%m %{$fg_no_bold[green]%}%d %{$reset_color%}${vcs_info_msg_0_}${NEWLINE}# '
  RPROMPT='[%{$fg_no_bold[yellow]%}%?%{$reset_color%}]'
}

prompt_setup "$@"
