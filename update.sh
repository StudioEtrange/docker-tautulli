#!/bin/bash
set -e

_CURRENT_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$_CURRENT_FILE_DIR"

# PARAMETERS ----------------------------
GITHUB_REPO="Tautulli/Tautulli"
# remove this string to version name (ex : with 'build' value, 'build507' becomes '507')
FILTER_VERSION_NAME=""

VERSION_SEPARATOR="."
# revert version ordering for letter behind number (ex: with 'ON' value, 1.2 is newer than 1.2rc1)
VERSION_INVERSE_LAST_CHAR=ON

# Use github tags instead of github releases
USE_TAG_AS_RELEASE=0

# exclude these tag/release name
EXCLUDE_VERSION=""

# INITIALIZE ----------------------------
version_order_option=
if [ "$VERSION_INVERSE_LAST_CHAR" = "ON" ]; then
	version_order_option="ENDING_CHAR_REVERSE"
	[ ! "$VERSION_SEPARATOR" = "" ] && version_order_option="$version_order_option SEP $VERSION_SEPARATOR"
fi

# SPECIFIC FUNCTIONS ----------------------------
function update_dockerfile() {
	local path=$1
	local version=$2

	sed -i.bak -e "s,ENV SERVICE_VERSION.*,ENV SERVICE_VERSION $version," "$path"
	rm -f "$path".bak
}


function update_readme() {
	local path=$1
	local version=$2
	local list="$3"

	sed -i.bak -e "s/latest,.*/latest, $list/" "$path"
	sed -i.bak -e "s/^Current latest tag is version __.*__/Current latest tag is version __"$version"__/" "$path"
	
	rm -f "$path".bak
}


# GENERIC FUNCTIONS ----------------------------
# sort a list of version

#sorted=$(sort_version "build507 build510 build403 build4000 build" "ASC")
#echo $sorted
# > build build403 build507 build510 build4000
#sorted=$(sort_version "1.1.0 1.1.1 1.1.1a 1.1.1b" "ASC SEP .")
#echo $sorted
# > 1.1.0 1.1.1 1.1.1a 1.1.1b
#sorted=$(sort_version "1.1.0 1.1.1 1.1.1a 1.1.1b" "DESC SEP .")
#echo $sorted
# > 1.1.1b 1.1.1a 1.1.1 1.1.0
#sorted=$(sort_version "1.1.0 1.1.1 1.1.1alpha 1.1.1beta1 1.1.1beta2" "ASC ENDING_CHAR_REVERSE SEP .")
#echo $sorted
# > 1.1.0 1.1.1alpha 1.1.1beta1 1.1.1beta2 1.1.1
#sorted=$(sort_version "1.1.0 1.1.1 1.1.1alpha 1.1.1beta1 1.1.1beta2" "DESC ENDING_CHAR_REVERSE SEP .")
#echo $sorted
# > 1.1.1 1.1.1beta2 1.1.1beta1 1.1.1alpha 1.1.0
#sorted=$(sort_version "1.9.0 1.10.0 1.10.1.1 1.10.1 1.10.1alpha1 1.10.1beta1 1.10.1beta2 1.10.2 1.10.2.1 1.10.2.2 1.10.0RC1 1.10.0RC2" "DESC ENDING_CHAR_REVERSE SEP .")
#echo $sorted
# > 1.10.2.2 1.10.2.1 1.10.2 1.10.1.1 1.10.1 1.10.1beta2 1.10.1beta1 1.10.1alpha1 1.10.0 1.10.0RC2 1.10.0RC1 1.9.0


# NOTE : ending characters in a version number can be ordered in the opposite way example :
# 			1.0.1 is more recent than 1.0.1beta so in ASC : 1.0.1beta 1.0.1 and in DESC : 1.0.1 1.0.1beta
# 			To activate this behaviour use "ENDING_CHAR_REVERSE" option
# 			we must indicate separator with SEP if we use ENDING_CHAR_REVERSE and if there is any separator (obviously)
sort_version() {
	local list=$1
	local opt="$2"

	local opposite_order_for_ending_chars="OFF"
	local mode="ASC"

	local separator=

	local flag_sep=OFF
	for o in $opt; do
		[ "$o" = "ASC" ] && mode=$o
		[ "$o" = "DESC" ] && mode=$o
		[ "$o" = "ENDING_CHAR_REVERSE" ] && opposite_order_for_ending_chars=ON
		# we need separator only if we use ENDING_CHAR_REVERSE and if there is any separator (obviously)
		[ "$flag_sep" = "ON" ] && separator="$o" && flag_sep=OFF
		[ "$o" = "SEP" ] && flag_sep=ON
	done

	local internal_separator="}"
	local new_list=
	local match_list=
	local max_number_of_block=0
	local number_of_block=0
	for r in $list; do
		# separate each block of number and block of letter
		[ ! "$separator" = "" ] && new_item="$(echo $r | sed "s,\([0-9]*\)\([^0-9]*\)\([0-9]*\),\1$internal_separator\2$internal_separator\3,g" | sed "s,^\([0-9]\),$internal_separator\1," | sed "s,\([0-9]\)$,\1$internal_separator$separator$internal_separator,")"
		[ "$separator" = "" ] && new_item="$(echo $r | sed "s,\([0-9]*\)\([^0-9]*\)\([0-9]*\),\1$internal_separator\2$internal_separator\3,g" | sed "s,^\([0-9]\),$internal_separator\1," | sed "s,\([0-9]\)$,\1$internal_separator,")"

		if [ "$opposite_order_for_ending_chars" = "OFF" ]; then
			[ "$mode" = "ASC" ] && substitute=A
			[ "$mode" = "DESC" ] && substitute=A
		else
			[ "$mode" = "ASC" ] && substitute=z
			[ "$mode" = "DESC" ] && substitute=z
		fi

		[ ! "$separator" = "" ] && new_item="$(echo $new_item | sed "s,\\$separator,$substitute,g")"

		new_list="$new_list $new_item"
		match_list="$new_item $r $match_list"

		number_of_block="${new_item//[^$internal_separator]}"
		[ "${#number_of_block}" -gt "$max_number_of_block" ] && max_number_of_block="${#number_of_block}"
	done
	max_number_of_block=$[max_number_of_block +1]

	# we detect block made with non-number characters for reverse order of block with non-number characters (except the first one)
	local count=0
	local b
	local i
	local char_block_list=

	for i in $new_list; do
		count=1

		for b in $(echo $i | tr "$internal_separator" "\n"); do
			count=$[$count +1]

			if [ ! "$(echo $b | sed "s,[0-9]*,,g")" = "" ]; then
				char_block_list="$char_block_list $count"
			fi
		done
	done

	# make argument for sort function
	# note : for non-number characters : first non-number character is sorted as wanted (ASC or DESC) and others non-number characters are sorted in the opposite way
	# example : 1.0.1 is more recent than 1.0.1beta so in ASC : 1.0.1beta 1.0.1 and in DESC : 1.0.1 1.0.1beta
	# example : build400 is more recent than build300 so in ASC : build300 build400 and in DESC : build400 build300
	count=0
	local sorted_arg=
	local j
	while [  "$count" -lt "$max_number_of_block" ]; do
		count=$[$count +1]

		block_arg=

		block_is_char=
		for j in $char_block_list; do
			[ "$count" = "$j" ] && block_is_char=1
		done
		if [ "$block_is_char" = "" ]; then
			block_arg=n$block_arg
			[ "$mode" = "ASC" ] && block_arg=$block_arg
			[ "$mode" = "DESC" ] && block_arg=r$block_arg
		else
			[ "$mode" = "ASC" ] && block_arg=$block_arg
			[ "$mode" = "DESC" ] && block_arg=r$block_arg
		fi

		sorted_arg="$sorted_arg -k $count,$count"$block_arg
	done
	[ "$mode" = "ASC" ] && sorted_arg="-t$internal_separator $sorted_arg"
	[ "$mode" = "DESC" ] && sorted_arg="-t$internal_separator $sorted_arg"

	sorted_list="$(echo "$new_list" | tr ' ' '\n' | sort $(echo "$sorted_arg") | tr '\n' ' ')"

	# restore original version strings (alternative to hashtable...)
	local result_list=
	local flag_found=OFF
	local flag=KEY
	for r in $sorted_list; do
		flag_found=OFF
		flag=KEY
		for m in $match_list; do
			if [ "$flag_found" = "ON" ]; then
				result_list="$result_list $m"
				break
			fi
			if [ "$flag" = "KEY" ]; then
				[ "$m" = "$r" ] && flag_found=ON
			fi
		done
	done

	echo "$result_list" | sed -e 's/^ *//' -e 's/ *$//'

}

# github releases have a 'name' which is a version name and a 'tag_name' wich is often a version number
# so we use 'tag_name' attribute
function github_releases() {
	local max=$1

	local result=""
	local last_page=$(curl -i -sL "https://api.github.com/repos/$GITHUB_REPO/releases" | grep rel=\"last\" | cut -d "," -f 2 | cut -d "=" -f 2 | cut -d ">" -f 1)
	for i in $(seq 1 $last_page); do 
		result="$result $(curl -sL https://api.github.com/repos/$GITHUB_REPO/releases?page=$i | grep tag_name | cut -d '"' -f 4)"
	done

	for e in $EXCLUDE_VERSION; do
		result="$(echo $result | sed -e "s,[[:space:]]*$e[[:space:]]*, ,")"
	done
	
	local sorted
	[ "$max" = "" ] && sorted=$(echo "$(sort_version "$result" "DESC $version_order_option")" | sed -e 's/^ *//' -e 's/ *$//')
	[ ! "$max" = "" ] && sorted=$(echo "$(sort_version "$result" "DESC $version_order_option")" | tr ' ' '\n' | head -n $max | tr '\n' ' ' | sed -e 's/^ *//' -e 's/ *$//' )
	echo "$sorted"
}

# github tags have only a 'name' which is often a version number
# so we use 'name' attribute
function github_tags() {
	local max=$1

	local result=""
	local last_page=$(curl -i -sL "https://api.github.com/repos/$GITHUB_REPO/tags" | grep rel=\"last\" | cut -d "," -f 2 | cut -d "=" -f 2 | cut -d ">" -f 1)
	for i in $(seq 1 $last_page); do 
		result="$result $(curl -sL https://api.github.com/repos/$GITHUB_REPO/tags?page=$i | grep name | cut -d '"' -f 4)"
	done

	for e in $EXCLUDE_VERSION; do
		result="$(echo $result | sed -e "s,[[:space:]]*$e[[:space:]]*, ,")"
	done
	
	local sorted
	[ "$max" = "" ] && sorted="$(echo "$(sort_version "$result" "DESC $version_order_option")" | sed -e 's/^ *//' -e 's/ *$//')"
	[ ! "$max" = "" ] && sorted="$(echo "$(sort_version "$result" "DESC $version_order_option")" | tr ' ' '\n' | head -n $max | tr '\n' ' ' | sed -e 's/^ *//' -e 's/ *$//' )"
	echo "$sorted"
}










# MAIN ----------------------------
# sed regexp can not be empty, so a foo string is used
[ "$FILTER_VERSION_NAME" = "" ] && FILTER_VERSION_NAME="XXXXXXXXXXXX"

echo
echo "******** UPDATE LAST ********"
# Update last release
[ "$USE_TAG_AS_RELEASE" = "1" ] && last_release=$(github_tags "1")
[ ! "$USE_TAG_AS_RELEASE" = "1" ] && last_release=$(github_releases "1")

version_full_number="$last_release"
version_number=$(echo $version_full_number | sed -e "s,$FILTER_VERSION_NAME,,g")
echo " ** version number : $version_number"

update_dockerfile "Dockerfile" "$version_full_number"

echo
echo "******** UPDATE ALL ********"
# Update all releasese
rm -Rf "ver"
[ "$USE_TAG_AS_RELEASE" = "1" ] && releases=$(github_tags)
[ ! "$USE_TAG_AS_RELEASE" = "1" ] && releases=$(github_releases)

for rel in $releases; do
	version_full_number="$rel"
	version_number=$(echo $version_full_number | sed -e "s,$FILTER_VERSION_NAME,,g")
	echo " * Process last release $version_full_number"
	echo " ** version number : $version_number"

	mkdir -p "ver/$version_number"
	cp -f supervisord* "ver/$version_number"
	cp -f Dockerfile "ver/$version_number/Dockerfile"
	cp -f docker-entrypoint.sh "ver/$version_number/docker-entrypoint.sh"
	update_dockerfile "ver/$version_number/Dockerfile" "$version_full_number"
	echo
done

echo "******** UPDATE README ********"
list_release=$(echo $releases | sed -e "s,$FILTER_VERSION_NAME,,g" | sed -e 's/ /\, /g')
last_release_tag=$(echo $last_release | sed -e "s,$FILTER_VERSION_NAME,,g")

update_readme "README.md" "$last_release_tag" "$list_release"

echo
echo "************************************"
echo " YOU SHOULD NOW ADD MISSING VERSION THROUGH"
echo " Docker Hub WebUI : AUTOMATED BUILD REPOSITORY"





