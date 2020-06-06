#!/bin/bash

# Ricky Palaguachi
# June 2020
# Desc: "search.sh" takes in one command line argument, "keyword_file". "keyword_file" is the name of a 
#       .txt **in the same directory as this script**  file which contains one query of keywords per 
#       line. This script performs a search of each query through Twitter's Standard 
#       Search API, and then writes it to an output file named "<date>_data.json", 
#       where <date> is the output of the shell command "$ date +%F". This output file 
#       will have no duplicate records of tweets, based on the id.

# search_twitter(): Perform a search of $query with $params and return the raw JSON response
# $query:           Keyword(s) used for this current serach
# $params:          Any parameters to pass into the API
function search_twitter {
    local query=$1
    local params=$2
    local endpt="/1.1/search/tweets.json"

    # Return to the caller the raw JSON response
    echo $(twurl "${endpt}?q=${query}&$params")
}

# to_json(): Process the API response into an organized JSON file and 
#            extract only relevant features.
# $response: (String) raw json response returned from the API.
# $of:       (String) output file name, including extension.
# $clear:    (Integer) 1 if you want to start with a blank file, 
#            0 if you want to append to the data set.
function to_json {
    local response=$1
    local of=$2
    local clear=$3

    if [ $clear -eq 1 ]; then # Start with a blank dataset
        # Add opening bracket for JSON standard compliance
        echo "[" > $of
        echo "Cleared $of."

    else # Append to an existing or initialize a new dataset 
        if [ -f $of ]; then
            echo "Appending to existing dataset within $of"
            # Remove closing bracket, then add a comma to extend JSON dataset
            sed -i '' '$d' $of
            echo "," >> $of
        else 
            echo -e "${YELLOW}Flag to append to dataset was raised; however, no dataset exists. Initializing new dataset...${NC}"
            echo "[" > $of;
        fi
    fi
    
    # Iterate over the statuses received and process each status
    for i in $(seq 0 $NUM_RESPONSES); do
        # Access the i-th status
        s=".statuses[${i}]"
        
        # Extract the relevant data from $response and output it to $of
        echo $response | jq ". | {created_at: $s.created_at, lang: $s.lang, \
        id: $s.id, id_str: $s.id_str, text: $s.text, \
        truncated: $s.truncated, coordinates: $s.coordinates, geo: $s.geo, \
        place: $s.place, hashtags: $s.entities.hashtags, user_id: $s.user.id, \
        user_at: $s.user.screen_name, user_location: $s.user.location}" >> $of
    
        # Separate records with commas in between each record to comply with JSON standard
        if ((i < $NUM_RESPONSES-1)); then
            echo "," >> $of;
        else
            break
        fi
    done

    # Add closing bracket for JSON standard compliance
    echo "]" >> $of
    echo -e "Response from ${BLUE}$q${NC} processed into $of."
}

# init vars
RED="\033[0;31m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
BLUE="\033[1;36m"
NC="\033[0m"
url="https://api.twitter.com"
NUM_RESPONSES=10
params="result_type=mixed&lang=en&count=$NUM_RESPONSES"
keyword_file=$1
of="$(date +%F)_data1.json"

# Constants used for testing data processing. $CLEAR_YES to start with a blank dataset, 
# $CLEAR_NO to append to an existing dataset.
CLEAR_YES=1
CLEAR_NO=0

echo "Num args: $#"
if [ $# -lt 1 ]; then
    echo "Expected keyword_file as command line argument. Filename must be in the same directory as this script."
    exit 1
elif [ $# -gt 1 ]; then
    echo "Too many command line arguments. Expected keyword_file as command line argument."
elif [ $# -eq 1 ]; then
    echo "Reading from ${GREEN}$keyword_file${NC}"
fi

# Populate a dataset using the keywords from lines $keyword_file
while read q; do
    echo -e "Performing a search on: ${BLUE}$q${NC}"

    # Generate an API request, and then process it to file $of
    raw_response=$(search_twitter "$q" "$params")
    to_json "$raw_response" "$of" $CLEAR_NO
done <"$keyword_file"

# Use the pandas python library to read the entire dataset and remove duplicates.
python remove_duplicates.py "$of"
cat "nodup_$of" | jq '.' > $of
rm "nodup_$of"

# KNOWN ISSUES:
# The 'text' field in the finished JSON response might have entries that are truncated. To fix this,
# we need to check if the 'truncated' field is 'True', and if True, we must scrape the full tweet another way.
# In Twitter's Premium Search API, this truncated-ness can be avoided, and the full tweet can be visible.

echo -e "${GREEN}Done!${NC}"