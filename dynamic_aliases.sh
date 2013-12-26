#!/bin/bash -e
#
# Meant to be run as a cronjob. Make a local copy to call from your crontab.
# Run crontab -e and add an entry similar to the following example:
# 0 19 * * 3-6 /path/to/local/copy/of/dynamic_aliases
#
# Also, add the following to your .bashrc to read the .dynamic_aliases file.
#
#ALIAS_FILE="~/.dynamic_aliases"
#if [ -f ${ALIAS_FILE} ]; then
#    . ${ALIAS_FILE}
#fi
#

# Edit this list of paths as required.
DIR_LIST=( "/path/to/add0/"
           "/path/to/add1/" )

ALIAS_FILE="~/.dynamic_aliases"
TEMP_FILE=/tmp/.dynamic_aliases

# Remove the existing file and create a new one.
[[ -f ${TEMP_FILE} ]] && rm ${TEMP_FILE}
touch ${TEMP_FILE}
# Iterate each path, and use 'find' to locate files. Before each file
for file in $(find -L ${DIR_LIST[@]} -maxdepth 1 -perm /111 \
                -type f ! -name '.*' -printf '%p\n'); do
  file_name="${file##*/}"
  # Get the full path of the existing alias (if there is one)
  existing_file=$(grep "alias ${file_name}=" ${TEMP_FILE} \
                    | awk -F '=' '{print $2}')
  if [[ -s "${existing_file}" ]]; then
    # Get the last modified time of the existing file and candidate file
    existing_file_time=$(stat --printf="%Y\n" ${existing_file})
    new_file_time=$(stat --printf="%Y\n" ${file})

    # Compare last modified times and add the new one if it was
    # modified more recently plus delete the older one
    if [[ ${new_file_time} -gt ${existing_file_time} ]]; then
      sed -i '/alias '${file_name}'=/d' ${TEMP_FILE}
      echo "alias ${file_name}=${file}" >> ${TEMP_FILE}
    fi
  else
    echo "alias ${file_name}=${file}" >> ${TEMP_FILE}
  fi
done
cp -f "${TEMP_FILE}" "${ALIAS_FILE}"
