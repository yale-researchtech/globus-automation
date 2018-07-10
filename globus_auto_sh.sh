#!/bin/bash

function help_and_exit () {

    echo -e 'Usage:' \
        "$0 --source-endpoint <UUID> --source-path <PATH> --shared-endpoint <UUID> --destination-path <PATH> [-d|--delete] [-h|--help]"
    echo ''
    echo 'The following options are available:'
    echo ''
    echo '  --source-endpoint: The endpoint UUID you want to copy data from. To search for an'
    echo '     source endpoint, use -source "find" .'
    echo '  -s-path: The path to the folder you want to copy to '
    echo '    your "--shared-endpoint"'
    echo '  --shared-endpoint: A shared endpoint UUID you have created'
    echo '    globus.org/app/transfer by clicking "share". To search for an endpoint,'
    echo '    use -shared "find" .'
    echo '  -dest-path: The path where "--source-path" folder'
    echo '    will be copied'
    echo '  -dir: Specifies that a folder will be recursively transferred. New folder will be created in -dest-path.'
    echo '  --sync: Sync data between source and destination directories. Will transfer'
    echo '    data the does not already exist and files more recent than in destination.'
    echo '  -find: Use to specify string to search for. Not recommended if searching for multiple endpoints.'
    echo '  -ep-scope: Used to search for endpoints, specify scope to search for endpoint.'
    echo '    Suggestions: "recently-used" (default), "my-endpoints", "shared-with-me" .'
    echo '  -l: Label for transfer'
    echo '  -d: Delete destination folder if it already exists'
    echo '  -h: Print this help message'
    echo ''
    echo "Example: $0 --source-endpoint ddb59aef-6d04-11e5-ba46-22000b92c6ec --source-path /share/godata --destination-path /shared_folder_example --shared-endpoint <your-shared-endpoint>"
    echo ''
    echo 'Go to "globus.org/app/transfer", navigate to your endpoint, and click'
    echo '"share" to create a shared endpoint'
    echo ''
    exit 0

}

if [ $# -eq 0 ]; then
    help_and_exit
fi
##Options
label = "Example"

while [ $# -gt 0 ]; do
    key="$1"
    case $1 in
        -source|--source-endpoint)
            shift
            source_endpoint=$1
        ;;
        -shared|--shared-endpoint)
            shift
            shared_endpoint=$1
        ;;
        -find|--find-endpoint)
            shift
            filter=$1
        ;;
        -ep-scope|--endpoint-scope)
            shift
            scope=$1
        ;;
        -s-path|--source-path)
            shift
            source_path=$1
        ;;
        -dest-path|--destination-path)
            shift
            destination_path=$1
        ;;
        -d|--delete)
            delete='yes'
        ;;
        --sync)
            sync='yes'
        ;;
        -l|--label)
            shift
            label=$1
        ;;
        -dir|--directory)
            directory='yes'
        ;;
        -h|--help)
            help_and_exit
        ;;
        *)
            echo ''
            echo "Error: Unknown Option: '$1'"
            echo ''
            echo "$0 --help for options and more information."
            exit 1
    esac
    shift
done

#Make sure paths are specified and exist
if [-z $source_path] || [-z $destination_path]; then
    echo "Source path and destination path must be specified."
    exit 1
else
  globus ls "$shared_endpoint:$destination_path" 1>/dev/null
  if [$? -ne 0]; then
      echo "Destination path does not exist"
      exit 1
  fi
  globus ls "$source_endpoint:$source_path" 1>/dev/null
  if [$? -ne 0]; then
      echo "Source path does not exist"
      exit 1
  fi
fi

## search endpoints if not provideds
if [-z $scope]; then
    scope = "recently-used"
fi
if [-z $filter]; then
    filter = ""
fi
if [-z $source_endpoint] || [-z $shared_endpoint]; then
    echo 'Source and Shared endpoints must be defined. If unknown, specify "find". Use -h for more info.'
    exit 1
fi
if [$source_endpoint == "find"]; then
    globus endpoint search --filter-scope $scope $filter
    echo "Copy and paste ID of desired source endpoint"
    read source_endpoint
fi
if [shared_endpoint == "find"]; then
  echo "Copy and paste ID of desired shared endpoint"
  read source_endpoint
fi

## Do delete or sync stuffs
basename=`basename "$source_path"`
new_directory = "$destination_path$basename/"
if [-n $directory]; then
    globus ls "$shared_endpoint:$new_directory" 1>/dev/null 2>/dev/null
    if [$? -eq 0]; then
        if [-n $delete]; then
            echo "Destination directory, $new_directory, exists and will be deleted"
            task_id=`globus delete --jmespath 'task_id' --label 'Share Data Example' -r "$shared_endpoint:$destination_directory" | tr -d '"'`
            globus task wait --timeout 600 $task_id
            echo "Creating destination directory $new_directory"
            globus mkdir "$shared_endpoint:$new_directory"
        elif [-n $sync]; then
            echo "Destination directory, $new_directory, exists and will be synced."
        else
            echo "Destination, $new_directory, exists. Please specify delete or sync. Use -h for help."
            exit 1
        fi
    else
      echo "Creating destination directory $new_directory"
      globus mkdir "$shared_endpoint:$new_directory"
    fi
fi
##do the actual transferring
if [-n "$directory"]; then
    echo "transferring directory to: $new_directory"
    exec globus transfer --recursive --label $label "$source_endpoint:$source_path" "$shared_endpoint:$new_directory"
elif [-n $sync]; then
    echo "syncing files between source $source_path and destination $destination_path"
    exec globus transfer --recursive --sync-level mtime --label $label "$source_endpoint:$source_path" "$shared_endpoint:$new_directory"
else
    echo "transferring file: $destination_path"
    exec globus transfer --label $label "$source_endpoint:$source_path" "$shared_endpoint:$destination_path"

fi
