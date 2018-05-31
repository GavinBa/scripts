# fetch_from_repo <url> <directory> <ref> <ref_subdir>
# <url>: remote repository URL
# <directory>: local directory; subdir for branch/tag will be created
# <ref>:
#	branch:name
#	tag:name
#	head(*)
#	commit:hash@depth(**)
#
# *: Implies ref_subdir=no
# **: Not implemented yet
# <ref_subdir>: "yes" to create subdirectory for tag or branch name
#
fetch_from_repo()
{
	local url=$1
	local dir=$2
	local ref=$3
	local ref_subdir=$4

	[[ -z $ref || ( $ref != tag:* && $ref != branch:* && $ref != head ) ]] && exit_with_error "Error in configuration"
	local ref_type=${ref%%:*}
	if [[ $ref_type == head ]]; then
		local ref_name=HEAD
	else
		local ref_name=${ref##*:}
	fi

	display_alert "Checking git sources" "$dir $ref_name" "info"

	# get default remote branch name without cloning
	# local ref_name=$(git ls-remote --symref $url HEAD | grep -o 'refs/heads/\S*' | sed 's%refs/heads/%%')
	# for git:// protocol comparing hashes of "git ls-remote -h $url" and "git ls-remote --symref $url HEAD" is needed

	if [[ $ref_subdir == yes ]]; then
		local workdir=$dir/$ref_name
	else
		local workdir=$dir
	fi
	mkdir -p $SRC/cache/sources/$workdir
	cd $SRC/cache/sources/$workdir

	# check if existing remote URL for the repo or branch does not match current one
	# may not be supported by older git versions
	local current_url=$(git remote get-url origin 2>/dev/null)
	if [[ -n $current_url && $(git rev-parse --is-inside-work-tree 2>/dev/null) == true && \
				$(git rev-parse --show-toplevel) == $(pwd) && \
				$current_url != $url ]]; then
		display_alert "Remote URL does not match, removing existing local copy"
		rm -rf .git *
	fi

	if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) != true || \
				$(git rev-parse --show-toplevel) != $(pwd) ]]; then
		display_alert "Creating local copy"
		git init -q .
		git remote add origin $url
	fi

	local changed=false

	local local_hash=$(git rev-parse @ 2>/dev/null)
	case $ref_type in
		branch)
		# TODO: grep refs/heads/$name
		local remote_hash=$(git ls-remote -h $url "$ref_name" | head -1 | cut -f1)
		[[ -z $local_hash || $local_hash != $remote_hash ]] && changed=true
		;;

		tag)
		local remote_hash=$(git ls-remote -t $url "$ref_name" | cut -f1)
		if [[ -z $local_hash || $local_hash != $remote_hash ]]; then
			remote_hash=$(git ls-remote -t $url "$ref_name^{}" | cut -f1)
			[[ -z $remote_hash || $local_hash != $remote_hash ]] && changed=true
		fi
		;;

		head)
		local remote_hash=$(git ls-remote $url HEAD | cut -f1)
		[[ -z $local_hash || $local_hash != $remote_hash ]] && changed=true
		;;
	esac

	if [[ $changed == true ]]; then
		# remote was updated, fetch and check out updates
		display_alert "Fetching updates"
		case $ref_type in
			branch) git fetch --depth 1 origin $ref_name ;;
			tag) git fetch --depth 1 origin tags/$ref_name ;;
			head) git fetch --depth 1 origin HEAD ;;
		esac
		display_alert "Checking out"
		git checkout -f -q FETCH_HEAD
	elif [[ -n $(git status -uno --porcelain --ignore-submodules=all) ]]; then
		# working directory is not clean
		if [[ $FORCE_CHECKOUT == yes ]]; then
			display_alert "Checking out"
			git checkout -f -q HEAD
		else
			display_alert "Skipping checkout"
		fi
	else
		# working directory is clean, nothing to do
		display_alert "Up to date"
	fi
	if [[ -f .gitmodules ]]; then
		display_alert "Updating submodules" "" "ext"
		# FML: http://stackoverflow.com/a/17692710
		for i in $(git config -f .gitmodules --get-regexp path | awk '{ print $2 }'); do
			cd $SRC/cache/sources/$workdir
			local surl=$(git config -f .gitmodules --get "submodule.$i.url")
			local sref=$(git config -f .gitmodules --get "submodule.$i.branch")
			if [[ -n $sref ]]; then
				sref="branch:$sref"
			else
				sref="head"
			fi
			fetch_from_repo "$surl" "$workdir/$i" "$sref"
		done
	fi
} #############################################################################

