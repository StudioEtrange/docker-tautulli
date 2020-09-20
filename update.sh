#!/bin/bash
_CURRENT_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
_CURRENT_RUNNING_DIR="$( cd "$( dirname "." )" && pwd )"

STELLA_LOG_STATE="OFF"
. "${_CURRENT_FILE_DIR}/stella-link.sh" include

cd "${_CURRENT_FILE_DIR}"

# PARAMETERS ----------------------------
GITHUB_REPO="Tautulli/Tautulli"
# remove this string to tag/release name  to use it as docker version (ex : with 'build' value, 'build507' becomes '507')
DOCKER_TAG_FILTER_NAME=""

VERSION_SEPARATOR="."
# revert version ordering for letter behind number (ex: with 'ON' value, 1.2 is newer than 1.2rc1)
VERSION_INVERSE_LAST_CHAR="ON"

# Use github tags instead of github releases
USE_TAG_AS_RELEASE="0"

# exclude some unwanted/malformed tag/release name
EXCLUDE_VERSION=""

# see filter_version_list doc in https://github.com/StudioEtrange/stella/blob/stable/nix/common/common.sh
VERSION_CONSTRAINT=">=v2.1.42"

# GITHUB AUTHENTIFICATION --------------------------------
# use your account to request github api
#	./update.sh username:password
CURL_AUTH=
GITHUB_BASIC_AUTH="$1"
if [ ! -z "${GITHUB_BASIC_AUTH}" ]; then
	CURL_AUTH="-u ${GITHUB_BASIC_AUTH}"
fi

# INITIALIZE ----------------------------
version_order_option=
if [ "${VERSION_INVERSE_LAST_CHAR}" = "ON" ]; then
	version_order_option="ENDING_CHAR_REVERSE"
	[ ! "${VERSION_SEPARATOR}" = "" ] && version_order_option="${version_order_option} SEP ${VERSION_SEPARATOR}"
fi

# UPDATE FUNCTIONS ----------------------------
update_dockerfile() {
	local path="$1"
	local version="$2"

	sed -i.bak -e "s,ENV SERVICE_VERSION.*,ENV SERVICE_VERSION ${version}," "${path}"
	rm -f "${path}.bak"
}


update_readme() {
	local path="$1"
	local version="$2"
	local list="$3"

	sed -i.bak -e "s/latest,.*/latest, ${list}/" "${path}"
	sed -i.bak -e "s/^Current latest tag is version __.*__/Current latest tag is version __"${version}"__/" "${path}"
	
	rm -f "${path}.bak"
}


# GENERIC FUNCTIONS ----------------------------

create_version_folder() {
	local docker_tag_version="$1"
	local service_version="$2"

	echo " * Create release ${service_version}"
	echo " ** Docker tag : ${docker_tag_version}"

	mkdir -p "${_CURRENT_FILE_DIR}/ver/${docker_tag_version}"
	cp -f "${_CURRENT_FILE_DIR}/Dockerfile" "ver/${docker_tag_version}/Dockerfile"
	update_dockerfile "${_CURRENT_FILE_DIR}/ver/${docker_tag_version}/Dockerfile" "${service_version}"
	mkdir -p "${_CURRENT_FILE_DIR}/ver/${docker_tag_version}/files"
	cp -R "${_CURRENT_FILE_DIR}"/files/* "${_CURRENT_FILE_DIR}/ver/${docker_tag_version}/files/"

}

# GITHUB FUNCTIONS ----------------------------


# github releases have a 'name' which is a version name and a 'tag_name' wich is often a version number
# so we use 'tag_name' attribute
github_releases() {
	local nb="$1"

	local result=""
	local last_page=$(curl ${CURL_AUTH} -i -sL "https://api.github.com/repos/${GITHUB_REPO}/releases" | grep rel=\"last\" | cut -d "," -f 2 | cut -d "=" -f 2 | cut -d ">" -f 1)
	for i in $(seq 1 ${last_page}); do 
		result="${result} $(curl ${CURL_AUTH} -sL https://api.github.com/repos/${GITHUB_REPO}/releases?page=${i} | grep tag_name | cut -d '"' -f 4)"
	done

	result="$($STELLA_API filter_list_with_list "${result}" "${EXCLUDE_VERSION}" "FILTER_REMOVE")"

	local sorted

	if [ "${VERSION_CONSTRAINT}" = "" ]; then
		[ "${nb}" = "" ] && sorted="$($STELLA_API sort_version "${result}" "DESC ${version_order_option}")" \
			|| sorted="$($STELLA_API sort_version "${result}" "DESC ${version_order_option} LIMIT ${nb}")"
	else
		[ "${nb}" = "" ] && sorted="$($STELLA_API filter_version_list "${VERSION_CONSTRAINT}" "${result}" "DESC ${version_order_option}")" \
			|| sorted="$($STELLA_API filter_version_list "${VERSION_CONSTRAINT}" "${result}" "DESC ${version_order_option} LIMIT ${nb}")"
	fi

	echo "${sorted}"
}

# github tags have only a 'name' which is often a version number
# so we use 'name' attribute
github_tags() {
	local nb="$1"

	local result=""
	local last_page=$(curl ${CURL_AUTH} -i -sL "https://api.github.com/repos/${GITHUB_REPO}/tags" | grep rel=\"last\" | cut -d "," -f 2 | cut -d "=" -f 2 | cut -d ">" -f 1)
	for i in $(seq 1 ${last_page}); do 
		result="${result} $(curl ${CURL_AUTH} -sL https://api.github.com/repos/${GITHUB_REPO}/tags?page=${i} | grep name | cut -d '"' -f 4)"
	done

	result="$($STELLA_API filter_list_with_list "${result}" "${EXCLUDE_VERSION}" "FILTER_REMOVE")"

	local sorted

	if [ "${VERSION_CONSTRAINT}" = "" ]; then
		[ "${nb}" = "" ] && sorted="$($STELLA_API sort_version "${result}" "DESC ${version_order_option}")" \
			|| sorted="$($STELLA_API sort_version "${result}" "DESC ${version_order_option} LIMIT ${nb}")"
	else
		[ "${nb}" = "" ] && sorted="$($STELLA_API filter_version_list "${VERSION_CONSTRAINT}" "${result}" "DESC ${version_order_option}")" \
			|| sorted="$($STELLA_API filter_version_list "${VERSION_CONSTRAINT}" "${result}" "DESC ${version_order_option} LIMIT ${nb}")"
	fi
	
	echo "${sorted}"
}










# MAIN ----------------------------
rm -Rf "ver"

# sed regexp can not be empty, so a foo string is used
[ "${DOCKER_TAG_FILTER_NAME}" = "" ] && DOCKER_TAG_FILTER_NAME="XXXXXXXXXXXX"


echo
echo "******** UPDATE LAST ********"
# Update last release

if [ "${USE_TAG_AS_RELEASE}" = "1" ]; then
	last_release=$(github_tags "1")
else
	last_release=$(github_releases "1")
fi

echo " * Create release ${last_release}"
echo " ** Docker tag : latest"
update_dockerfile "${_CURRENT_FILE_DIR}/Dockerfile" "${last_release}"


echo
echo "******** UPDATE ALL ********"
# Update all releases
if [ "${USE_TAG_AS_RELEASE}" = "1" ]; then
	releases="$(github_tags)"
else
	releases="$(github_releases)"
fi

for rel in ${releases}; do

	docker_version_number="$(echo ${rel} | sed -e "s,${DOCKER_TAG_FILTER_NAME},,g")"
	create_version_folder "${docker_version_number}" "${rel}" 

	echo
done

echo "******** UPDATE README ********"
list_release=$(echo ${releases} | sed -e "s,${DOCKER_TAG_FILTER_NAME},,g" | sed -e 's/ /\, /g')
last_release_tag=$(echo ${last_release} | sed -e "s,${DOCKER_TAG_FILTER_NAME},,g")

update_readme "README.md" "${last_release_tag}" "${list_release}"

echo
echo "************************************"
echo " YOU SHOULD NOW ADD MISSING VERSION THROUGH"
echo " Docker Hub WebUI : AUTOMATED BUILD REPOSITORY"
