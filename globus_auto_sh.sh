#!/bin/bash

function help_and_exit () {

    echo -e 'Usage:' \
        "$0 [OPTIONS] -source <UUID> -s-path <PATH> -shared <UUID> -dest-path <PATH>"
    echo ''
    echo 'Reminder: source and destination endpoints MUST be shared. Info on creating shared endpoints:' 
    echo '    https://docs.globus.org/how-to/share-files/'
    echo  ''
    echo 'The following options are available:'
    echo ''
    echo '  -source || --source-endpoint: The endpoint UUID you want to copy data from. To search for'
    echo '     a source endpoint, use -source "find" .'
    echo '  -s-path: The path to the folder you want to copy from '
    echo '    your "--source-endpoint"'
    echo '  -shared || --shared-endpoint: A shared endpoint UUID you have created'
    echo '    globus.org/app/transfer by clicking "share". To search for an endpoint,'
    echo '    use -shared "find" .'
    echo '  -dest-path: The path where "--source-path" folder'
    echo '    will be copied'
    echo '  -dir: Specifies that a folder will be recursively transferred. New folder will be created in -dest-path'
    echo '     if -sync not specified'
    echo '  -sync: Sync data between source and destination directories. Will transfer'
    echo '    data the does not already exist and files more recent than in destination. Use with -dir option.'
    echo '  -find: Use to specify string to search for. Not recommended if searching for multiple endpoints.'
    echo '  -ep-scope: Used to search for endpoints, specify scope to search for endpoint.'
    echo '    Suggestions: "recently-used" (default), "my-endpoints", "shared-with-me" .'
    echo '  -l: Label for transfer'
    echo '  -del: Delete destination folder if it already exists'
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
label="Example"

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
        -del|--delete)
            delete='yes'
        ;;
        -sync|--sync)
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

## search endpoints if not provideds
if [ -z $scope ]; then
    scope="recently-used"
fi
if [ -z $filter ]; then
    filter=""
fi
if [ -z $source_endpoint ] || [ -z $shared_endpoint ]; then
    echo 'Source and Shared endpoints must be defined. If unknown, specify "find". Use -h for more info.'
    exit 1
fi
if [ $source_endpoint == "find" ]; then
    globus endpoint search --filter-scope $scope $filter
    echo "Copy and paste ID of desired source endpoint"
    read source_endpoint
fi
if [ $shared_endpoint == "find" ]; then
  echo "Copy and paste ID of desired shared endpoint"
  read shared_endpoint
fi
#Check to see that endpoints are activated
globus endpoint is-activated $source_endpoint

if [ $? -ne 0 ]; then
  echo 'Source endpoint not activated. Activating ... (if failure, will EXIT)'
  globus endpoint activate $source_endpoint || globus endpoint activate --web $source_endpoint || exit 1
fi
globus endpoint is-activated $shared_endpoint

if [ $? -ne 0 ]; then
  echo 'Destination endpoint not activated. Activating ... (if failure, will EXIT)'
  globus endpoint activate $source_endpoint || globus endpoint activate --web $source_endpoint || exit 1
fi

#Make sure paths are specified and exist
dirname_source=`dirname "$source_path"`
dirname_dest=`dirname "$destination_path"`

if [ -z $source_path ] || [ -z $destination_path ]; then
    echo "Source path and destination path must be specified."
    exit 1
elif [ -z $directory ]; then 
  globus ls "$shared_endpoint:$dirname_dest" 1>/dev/null
  if [ $? -ne 0 ]; then
      echo "Destination directory $dirname_dest does not exist"
      exit 1
  fi
  globus ls "$source_endpoint:$dirname_source" 1>/dev/null
  if [ $? -ne 0 ]; then
      echo "Source directory $dirname_source does not exist"
      exit 1
  fi
fi

## Do delete or sync stuffs, if just one file then get that set up properly
basename_source=`basename "$source_path"`
basename_dest=`basename "$destination_path"`
new_directory="$destination_path$basename_source"

if [ -n "$directory" ]; then
    globus ls "$shared_endpoint:$new_directory" 1>/dev/null 2>/dev/null
    if [ $? -eq 0 ]; then
        if [ -n "$delete" ]; then
            echo "Destination directory, $new_directory, exists and will be deleted"
            task_id=`globus delete --jmespath 'task_id' --label "$label" -r "$shared_endpoint:$new_directory" | tr -d '"'`
            globus task wait --timeout 600 $task_id
            echo "Delete successful. Creating destination directory $new_directory"
            globus mkdir "$shared_endpoint:$new_directory"
        elif [ -n "$sync" ]; then
            echo "Destination directory, $new_directory, exists and will be synced."
        else
            echo "Destination, $new_directory, exists. Please specify delete or sync. Use -h for help."
            exit 1
        fi
    else
      echo "Creating destination directory $new_directory"
      globus mkdir "$shared_endpoint:$new_directory"
    fi
#if just one file make sure it gets transferred as one
elif [ "$basename_source" != "$basename_dest" ]; then
    dir=`dirname "$destination_path"`
    destination_path="$dir$basename_source"
fi

##do the actual transferring
if [ -n "$directory" ]; then
    echo "transferring directory to: $new_directory"
    exec globus transfer --recursive --label "$label" "$source_endpoint:$source_path" "$shared_endpoint:$new_directory"
elif [ -n "$sync" ]; then
    echo "syncing files between source $source_path and destination $destination_path"
    exec globus transfer --recursive --sync-level mtime --label "$label" "$source_endpoint:$source_path" "$shared_endpoint:$new_directory"
else
    echo "transferring file to : $destination_path"
    exec globus transfer --label "$label" "$source_endpoint:$source_path" "$shared_endpoint:$destination_path"

fi
