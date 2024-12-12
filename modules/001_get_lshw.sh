#!/bin/sh

# Function to check thermal throttle counts and write to JSON file
list_lshw() {
    module_name="lshw_info"
    description="Lists lshw output"
    version="1.0"

    output_file="$1"

    # Check if the output file is set to stdout
    if [ "$output_file" = "-" ]; then
        # If stdout, use a temporary file
        tmp_file="$(mktemp)"
        trap 'rm -f "$tmp_file"' EXIT
        output_file="$tmp_file"
    fi

    # Create an initial JSON structure
    printf "{ \"Module\": \"%s\", \"Description\": \"%s\", \"Version\": \"%s\", \"Results\": [" > "$output_file"

    # Iterate through all available CPUs
    lshw -json -quiet >>  $output_file
    if [ "$1" = "-" ]; then
        # If stdout was used, cat the temporary file to stdout
        cat "$output_file"
    else
        echo "Results written to: $output_file"
    fi
}

# Function to initialize
initialize() {
    list_lshw "${LOG_MY_WORK_FOLDER_RESULT_FOLDER}/lshw_initial.json"
}

# Function to finalize
finalize() {
    list_lshw "${LOG_MY_WORK_FOLDER_RESULT_FOLDER}/lshw_final.json"
}

# Function to check status
status() {
    list_lshw "${LOG_MY_WORK_FOLDER_RESULT_FOLDER}/lshw_`date +%s%N`_final.json"
    cat "${LOG_MY_WORK_FOLDER_RESULT_FOLDER}/lshw_`date +%s%N`_final.json"
}


# Main program
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <initialize|status|finalize>"
    exit 1
fi

which lshw 2>/dev/null >/dev/null
# if it is not a platform that supports the used files, skip this
if [ $? -ne 0 ]; then
  return
fi

case "$1" in
    "initialize")
        initialize
        ;;
    "status")
        status
        ;;
    "finalize")
        finalize
        ;;
    *)
        echo "Invalid argument. Usage: $0 <initialize|status|finalize>"
        exit 1
        ;;
esac
