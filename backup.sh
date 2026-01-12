CDIR=$(dirname $0)

. $CDIR/commonVars
EXPECT=$CDIR/m_scp_exec.exp
function timeout() { /usr/bin/perl -e 'alarm shift; exec @ARGV' "$@"; }

function FS_CHECK_EXIT_STATUS
{
  _STATUS=$1
  _MSG=$2
  _ABORT=${3:-1}
  if [ $_STATUS -ne 0 ]; then
    FS_TRACE ERROR "$_MSG (Exit Status: $_STATUS)"
    if [ $_ABORT -eq 1 ]; then
      exit $_STATUS
    fi
  fi
}

function SET_DEFAULTS
{
  BACKUP_SRCUSER=$USER
  BACKUP_SRCHOST=__NONE__
  BACKUP_SRCPATH=""
  BACKUP_SRCPASS=__NONE__
  BACKUP_SRCPORT=22
  
  BACKUP_TGTUSER=$USER
  BACKUP_TGTHOST=__NONE__
  BACKUP_TGTPATH=""
  BACKUP_TGTPASS=__NONE__
  BACKUP_TGTPORT=22

  BACKUP_DESC=$1
  BACKUP_EXCLUDELIST=""
  BACKUP_OPTIONS=""
  
}


function PRECHECK_AND_SET_BACKUP
{

    BACKUP=$1
    SET_DEFAULTS $BACKUP
    
    echo  python $INFOSCRIPT $BACKUP $BACKUPINFO
    if ! python $INFOSCRIPT $BACKUP $BACKUPINFO > $TMP_FILE 2>>$LOG_FILE_ERR ; then
	FS_TRACE ERROR "$BACKUP info couldn't be selected from configuration file (PHASE:$CURRENT_PHASE)"   
	exit -1 
    else
	. $TMP_FILE
    fi

  
    export PASSWORD=$BACKUP_PASSWORD

}


function CHECK_CONNECTIVITY_NC
{
    _HOST=$1
    _PORT=$2
    echo nc -z $_HOST $_PORT
    timeout 2 nc -z $_HOST $_PORT
    FS_CHECK_EXIT_STATUS $? "Couldn't establish remote connection with $BACKUP_HOST:$BACKUP_PORT"
}
function CHECK_CONNECTIVITY 
{
    local SSH_HOST="$1"

    local HOST
    local PORT

    HOST=$(ssh -G "$SSH_HOST" | awk '/^hostname / {print $2}')
    PORT=$(ssh -G "$SSH_HOST" | awk '/^port / {print $2}')

    echo "nc -z $HOST $PORT"
    timeout 2 nc -z "$HOST" "$PORT"
}
function FS_CREATE_TGT_DIR
{
    if [ ! -d $BACKUP_TGTPATH ]; then
	if [[ $BACKUP_TGTPATH == */ ]]; then
	    _TGT_DIR=$BACKUP_TGTPATH
	else
	    _TGT_DIR=$(dirname $BACKUP_TGTPATH)
	    BACKUP_SRCPATH="$BACKUP_SRCPATH/"
	    BACKUP_TGTPATH="$BACKUP_PATH/"
	fi
	FS_TRACE WARNING "Creating $_TGT_DIR"
	
	mkdir -p $_TGT_DIR
	FS_CHECK_EXIT_STATUS $? "Couldn't create local directory: $_TGT_DIR"
    fi   
}

function RSYNC_REMOTE_TO_REMOTE
{
    FS_TRACE FATAL "NOT_IMPLEMENTED YET: RSYNC_REMOTE_TO_REMOTE"
}


function RSYNC_REMOTE_TO_LOCAL
{
    FS_TRACE INFO RSYNC_REMOTE_TO_LOCAL
    
    FS_CREATE_TGT_DIR
    
    CHECK_CONNECTIVITY $BACKUP_SRCHOST $BACKUP_SRCPORT

    BACKUP_COMMAND="rsync -a  -e \"ssh -p $BACKUP_SRCPORT\" $BACKUP_OPTIONS $EXCLUDE_OPTIONS $BACKUP_SRCUSER@$BACKUP_SRCHOST:$BACKUP_SRCPATH $BACKUP_TGTPATH"
    PASSWORD=$BACKUP_SRCPASS
      
}

function RSYNC_LOCAL_TO_REMOTE
{
    FS_TRACE INFO RSYNC_LOCAL_TO_REMOTE

    CHECK_CONNECTIVITY $BACKUP_TGTHOST $BACKUP_TGTPORT
    
    BACKUP_COMMAND="rsync -a  -e \"ssh -p $BACKUP_SRCPORT\" $BACKUP_OPTIONS $EXCLUDE_OPTIONS $BACKUP_SRCPATH $BACKUP_TGTUSER@$BACKUP_TGTHOST:$BACKUP_TGTPATH"
    
    PASSWORD=$BACKUP_TGTPASS
}

function RSYNC_LOCAL_TO_LOCAL
{
    FS_TRACE INFO RSYNC_LOCAL_TO_LOCAL

    FS_CREATE_TGT_DIR
    
    PASSWORD=__NONE__
    BACKUP_COMMAND="rsync -a $BACKUP_OPTIONS $EXCLUDE_OPTIONS $BACKUP_SRCPATH $BACKUP_TGTPATH"
}

function RSYNC_BACKUP
{

  if [ "$VERBOSE" == "YES" ]; then
      BACKUP_OPTIONS="$BACKUP_OPTIONS -v"
  fi
 
  if [ ! -z "$BACKUP_EXCLUDELIST" ]; then
      for EXCLUDE in $BACKUP_EXCLUDELIST; do
	  EXCLUDE_OPTIONS="$EXCLUDE_OPTIONS --exclude=$EXCLUDE"
      done
  fi

  FS_TRACE INFO "SYNCR TASK:         $BACKUP_NAME started at $(date)"

  FS_TRACE INFO "BACKUP_SRCUSER         = $BACKUP_SRCUSER" 
  FS_TRACE INFO "BACKUP_SRCHOST         = $BACKUP_SRCHOST"
  FS_TRACE INFO "BACKUP_SRCPATH         = $BACKUP_SRCPATH" 
  FS_TRACE INFO "BACKUP_SRCPASS         = $BACKUP_SRCPASS" 
  FS_TRACE INFO "BACKUP_SRCPORT         = $BACKUP_SRCPORT"
  
  FS_TRACE INFO "BACKUP_TGTUSER         = $BACKUP_TGTUSER" 
  FS_TRACE INFO "BACKUP_TGTHOST         = $BACKUP_TGTHOST"
  FS_TRACE INFO "BACKUP_TGTPATH         = $BACKUP_TGTPATH" 
  FS_TRACE INFO "BACKUP_TGTPASS         = $BACKUP_TGTPASS" 
  FS_TRACE INFO "BACKUP_TGTPORT         = $BACKUP_TGTPORT"

  FS_TRACE INFO "BACKUP_EXCLUDELIST     = $BACKUP_EXCLUDELIST" 
  FS_TRACE INFO "BACKUP_SRCPATH         = $BACKUP_SRCPATH" 
  FS_TRACE INFO "BACKUP_TGTPATH         = $BACKUP_TGTPATH" 
  FS_TRACE INFO "BACKUP_OPTIONS         = $BACKUP_OPTIONS"
  

  if [ $BACKUP_SRCHOST != "__NONE__" -a $BACKUP_TGTHOST != "__NONE__" ]; then
      RSYNC_REMOTE_TO_REMOTE
  elif [ $BACKUP_SRCHOST != "__NONE__" ]; then
      RSYNC_REMOTE_TO_LOCAL
  elif [ $BACKUP_TGTHOST != "__NONE__" ]; then
      RSYNC_LOCAL_TO_REMOTE
  elif [ $BACKUP_SRCHOST == "__NONE__" -a $BACKUP_TGTHOST == "__NONE__" ]; then
      RSYNC_LOCAL_TO_LOCAL
  fi

  
  
  if [ 1 -eq 0 ] ; then
      FS_TRACE INFO "$BACKUP_COMMAND"
      echo expect -f $EXPECT Local \
	  -password $PASSWORD \
	  -command "$BACKUP_COMMAND"
      expect -f $EXPECT Local \
	  -password $PASSWORD \
	  -command "$BACKUP_COMMAND"
      FS_CHECK_EXIT_STATUS ${PIPESTATUS[0]} "Error Syncring Task $BACKUP_NAME"
  else
      eval $BACKUP_COMMAND | tee -a $LOG_FILE_OUT
      FS_CHECK_EXIT_STATUS ${PIPESTATUS[0]} "Error Syncring Task $BACKUP_NAME"
      
  fi

  

}

function INIT
{

  FS_SET_LOG_FILE $LOG_FILE
  
  
}


function CLEANUP
{
  rm -f $TMP_FILE
}
function FS_USAGE 
{ 
  FS_TRACE WARNING "USAGE:"
  cat<<EOF

  $CMD_NAME [-v] <backup_list> | all

OPTIONS:
  -v               : Verbose

PARAMETERS:  <backup_list> | all
  
  If all is specified, next backups will be considered:

  * $ALL_BACKUPS

EXAMPLES:

  $CMD_NAME -v all

 
EOF
}

VERBOSE=NO

while getopts :hvB:L: name
do
    case $name in
	h)
	    FS_USAGE
	    exit 1
	    ;;
	:)
	    echo "Option $OPTARG requires argument"
	    FS_USAGE
	    exit 1
	    ;;
	B) 
	    BACKUP_XML=$OPTARG
	    ;;
	v)
	    VERBOSE=YES
	    ;;
	L) 
	    LOG_FILE="$OPTARG"
	    ;;
	\?)
	    echo "Invalid option $OPTARG"
	    FS_USAGE
	    ;;
    esac
done

shift `expr $OPTIND - 1`

if [ $# -eq 0 ]; then
  FS_USAGE
  FS_TRACE FATAL "Backup selection should be provided:  <backup>"
  exit 2
fi

BACKUP=$1

export JOBS=$JOBS

INIT

FS_TRACE_PHASE INFO " *** BACKUP: $BACKUP ***"

FS_TRACE_PHASE INFO "CHECKING BACKUP INFO ($BACKUP)"
PRECHECK_AND_SET_BACKUP $BACKUP

RSYNC_BACKUP

CLEANUP

