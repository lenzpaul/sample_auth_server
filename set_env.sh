# Iterate over all the environment variables and set them in the current shell.
# This is useful for quickly setting up a shell environment from a file.

# if no parameter is given, print usage
if [ $# -eq 0 ]; then
    echo "Usage: $0 <env_file>"

# if file does not exist, print error
elif [ ! -f $1 ]; then
    echo "Error: $1 does not exist"

# if file exists, set environment variables
else
    # loop through each line in env file
    while read -r line; do
        # check if line is not empty
        if [ -n "$line" ]; then
            # set environment variable
            export "$line"
        fi
    done < "$1"
fi