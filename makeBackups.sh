CDIR=$(cd $(dirname $0); pwd)

. $CDIR/commonVars
INFOSCRIPT=$CDIR/getBackupInfo.py
. $CDIR/utils.sh


BACKUPINFO=backupList.xml

function INIT
{

  ALL_BACKUPS=$(python3 $INFOSCRIPT backupList $BACKUPINFO |  awk '{printf "%s ",$0}')

  if [ "$BACKUP_LIST" == "all" ]; then
    BACKUP_LIST=$ALL_BACKUPS
  fi

  FS_RESET_LOG_FILE $LOG_FILE
  FS_TRACE INFO "BACKUP_LIST : $BACKUP_LIST"

}


function FS_USAGE 
{ 
  FS_TRACE WARNING "USAGE:"
  cat<<EOF

  $CMD_NAME [-B <backupXmlFile:=backupList.xml>] [-v] [<backup_list> | all]

OPTIONS:
  -v               : Verbose
  -B               : backupXmlFile

PARAMETERS:  <backup_list> | all
  
  If all is specified, next backups will be considered:

  $(python3 $INFOSCRIPT backupList $BACKUPINFO |  awk '{printf "- %s\n  ",$0}')


EXAMPLES:

  $CMD_NAME -v all

 
EOF
}

while getopts :hvB:L: name
do
    case $name in
	h)
	    FS_USAGE
	    exit 1
	    ;;
	B) 
	    export BACKUPINFO=$OPTARG
	    ;;
	:)
	    echo "Option $OPTARG requires argument"
	    FS_USAGE
	    exit 1
	    ;;
	\?)
	    echo "Invalid option $OPTARG"
	    FS_USAGE
	    ;;
    esac
done

INDEX=$(($OPTIND-1))
ARGS=${@:1:$INDEX}
shift $INDEX


if [ $# -eq 0 ]; then
  FS_USAGE
  FS_TRACE FATAL "Backup selection should be provided:  <backup_list> | all"
  exit 2
fi

BACKUP_LIST=$*


INIT

for BACKUP in $BACKUP_LIST; do

  FS_TRACE INFO "Starting backup for: $BACKUP"    
    $CDIR/backup.sh $ARGS $BACKUP

done
