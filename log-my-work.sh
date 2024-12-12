#!/bin/sh


# Function to list module files and store in environment variable
list_module_files() {
    if [ -n "$LOG_MY_WORK_FOLDER" ]; then
        module_dir="$LOG_MY_WORK_FOLDER/modules"
        if [ -d "$module_dir" ]; then
            echo "Listing module files:"
            module_files=$(find "$module_dir" -type f -regex '.*/[0-9]+_[^/]+\.sh' | sort -n)
            export MODULE_SCRIPTS="$module_files"
            echo "MODULE_SCRIPTS environment variable set to: $MODULE_SCRIPTS"
        else
            echo "Module directory not found: $module_dir"
        fi
    else
        echo "LOG_MY_WORK_FOLDER environment variable not set."
    fi
}

# Function to execute initialize function in module scripts
execute_module_initialize() {
    list_module_files
    if [ -n "$MODULE_SCRIPTS" ]; then
        for module_script in $MODULE_SCRIPTS; do
            echo "Executing initialize in module script: $module_script"
            $module_script initialize
        done
    else
        echo "No module scripts found."
    fi
}

# Function to execute status function in module scripts
execute_module_status() {
    list_module_files
    if [ -n "$MODULE_SCRIPTS" ]; then
        for module_script in $MODULE_SCRIPTS; do
            echo "Executing status in module script: $module_script"
            $module_script status
        done
    else
        echo "No module scripts found."
    fi
}

# Function to execute finalize function in module scripts
execute_module_finalize() {
    list_module_files
    if [ -n "$MODULE_SCRIPTS" ]; then
        for module_script in $MODULE_SCRIPTS; do
            echo "Executing finalize in module script: $module_script"
            $module_script finalize
        done
    else
        echo "No module scripts found."
    fi
}

# Function to initialize
initialize() {
    if [ -d "$LOG_MY_WORK_FOLDER_RESULT_FOLDER" ]; then
        echo "This folder has already started a log. Delete \"$LOG_MY_WORK_FOLDER_RESULT_FOLDER\" to start over"
        exit 1
    else
        mkdir -p ${LOG_MY_WORK_FOLDER_RESULT_FOLDER}
        if [ $? -ne 0 ]; then
           RET=${?}
           echo "Could not create result directory '${LOG_MY_WORK_FOLDER_RESULT_FOLDER}' (${RET})"
           return $?
        fi
        execute_module_initialize
    fi
}

# Function to finalize
finalize() {
    if [ -d "$LOG_MY_WORK_FOLDER_RESULT_FOLDER" ]; then
        execute_module_finalize
    else
        echo "This folder was not initialized to log. Call \"$0 initialize\" to start a session"
        exit 1
    fi
}

# Function to check status
status() {
    if [ -d "$LOG_MY_WORK_FOLDER_RESULT_FOLDER" ]; then
        execute_module_status
    else
        echo "This folder was not initialized to log. Call \"$0 initialize\" to start a session"
        exit 1
    fi
}

# Main program
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <initialize|status|finalize>"
    exit 1
fi

LOG_MY_WORK_FOLDER=$(cd "$(dirname "$0")" && pwd)

export LOG_MY_WORK_FOLDER_RESULT_FOLDER=`pwd`/.log_my_work

echo "Script is located in: $LOG_MY_WORK_FOLDER"

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
        ;;
esac

