#!/bin/bash

set -euo pipefail

#fortunky='/usr/share/games/fortunes/linuxcookie'
#fortunky='/usr/share/games/fortunes/cs/pratchett'
#fortunky_type='pratchett'

#fortunky='/usr/share/games/fortunes/cs/stopar'
#fortunky_type='stopar'

fortunky='/usr/share/games/fortunes/cs/cimrman'
fortunky_type='cimrman'

rm insert.sql || true

echo "INSERT INTO fortunky(fortunka_type, fortunka_text) VALUES" >> insert.sql

# I need to know if the loop reached the last line
# Without it, the last fortune won't be flushed and it's missed
last_line=$(wc -l < $fortunky)
current_line=0
is_it_last_line=false

jedna_cela_fortunka=""

while IFS= read -r line; do
    current_line=$(($current_line + 1))

    # check whether we deal with last line of the file or not
    # good to know so we don't miss the last fortune, becuase there is not the fortune delimiter
    # which normally causes flushing the fortune out to the sql
    # and also the last line means last fotune and last entry in SQL INSERT, so a semicolon is
    # put there at the end instead of a comma which just delimits multiple insert rows
    if [ $current_line -eq $last_line ]; then
        is_it_last_line=true
    fi

    # We hit fortune delimiter or this is a last line
    if [ "$line" == "%" ] || [ $is_it_last_line = true ]; then 
        if [ $is_it_last_line = true ]; then
            sql_insert_end=';'
        else
            sql_insert_end=','
        fi

        echo "('${fortunky_type}', '${jedna_cela_fortunka}')${sql_insert_end}" >> insert.sql
	jedna_cela_fortunka=''
	continue
    fi

    # Add newline or not
    if [ -z "${jedna_cela_fortunka}" ]; then
        jedna_cela_fortunka+="${line}"
    else
        jedna_cela_fortunka+="\n${line}"
    fi

done < ${fortunky}

