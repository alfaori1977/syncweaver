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
  BACKUP_SRCUSER=
  BACKUP_SRCHOST=__NONE__
  BACKUP_SRCPATH=""
  BACKUP_SRCPASS=__NONE__
  BACKUP_SRCPORT=
  
  BACKUP_TGTUSER=
  BACKUP_TGTHOST=__NONE__
  BACKUP_TGTPATH=""
  BACKUP_TGTPASS=__NONE__
  BACKUP_TGTPORT=

  BACKUP_DESC=$1
  BACKUP_EXCLUDELIST=""
  BACKUP_OPTIONS=""
  
}


function PRECHECK_AND_SET_BACKUP
{

    BACKUP=$1
    SET_DEFAULTS $BACKUP
    
    FS_TRACE DEBUG  "python3 $INFOSCRIPT $BACKUP $BACKUPINFO"
    if ! python3 $INFOSCRIPT $BACKUP $BACKUPINFO > $TMP_FILE 2>>$LOG_FILE_ERR ; then
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
    local SSH_PORT="$2"

    # Validate input
    if [ -z "$SSH_HOST" ]; then
        FS_TRACE ERROR "SSH_HOST parameter is empty"
        return 1
    fi

    local HOST
    local PORT

    # Extract hostname and port from SSH config (considers ~/.ssh/config)
    HOST=$(ssh -G "$SSH_HOST" 2>/dev/null | awk '/^hostname / {print $2}')
    PORT=$(ssh -G "$SSH_HOST" 2>/dev/null | awk '/^port / {print $2}')

    # Check if hostname resolution was successful
    if [ -z "$HOST" ]; then
        FS_TRACE ERROR "Could not resolve hostname for '$SSH_HOST' from SSH config"
        return 1
    fi

    # Default port to 22 if not found in config
    if [ -z "$PORT" ]; then
        FS_TRACE WARNING "Could not resolve port for '$SSH_HOST' from SSH config, using default port 22"
        PORT=22
    fi

    # Override port if user explicitly specified it and it differs from config
    if [ -n "$SSH_PORT" ] && [ "$SSH_PORT" != "22" ] && [ "$SSH_PORT" != "$PORT" ]; then
        FS_TRACE WARNING "Overriding SSH config port $PORT with user specified port $SSH_PORT"
        PORT=$SSH_PORT
    elif [ -n "$SSH_PORT" ] && [ "$SSH_PORT" != "22" ] && [ "$PORT" = "22" ]; then
        FS_TRACE WARNING "Using user specified port $SSH_PORT instead of default"
        PORT=$SSH_PORT
    fi

    # Check if nc command is available
    if ! command -v nc &> /dev/null; then
        FS_TRACE ERROR "nc (netcat) command not found. Please install netcat."
        return 1
    fi

    # Perform connectivity check
    FS_TRACE DEBUG "Testing connectivity to $HOST:$PORT"
    if timeout 2 nc -z "$HOST" "$PORT" 2>/dev/null; then
        FS_TRACE DEBUG "Successfully connected to $HOST:$PORT"
        return 0
    else
        FS_TRACE ERROR "Could not establish connection to $HOST:$PORT"
        return 1
    fi
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

    E_SSH_OPTIONS=""
    if [ -n "$BACKUP_SRCPORT" ]; then        
        E_SSH_OPTIONS="-e \"ssh -p $BACKUP_SRCPORT\""
    fi
    _SSH_USER=""
    if [ -n "$BACKUP_SRCUSER" ]; then
        _SSH_USER="$BACKUP_SRCUSER@"
    fi

    BACKUP_COMMAND="rsync -a $E_SSH_OPTIONS $BACKUP_OPTIONS $EXCLUDE_OPTIONS ${_SSH_USER}$BACKUP_SRCHOST:$BACKUP_SRCPATH $BACKUP_TGTPATH"
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

  
  
  if [ $BACKUP_SRCPASS == "__NONE__" -a $BACKUP_TGTPASS == "__NONE__" ]; then
    FS_TRACE INFO "$BACKUP_COMMAND"
    eval $BACKUP_COMMAND | tee -a $LOG_FILE_OUT
    FS_CHECK_EXIT_STATUS ${PIPESTATUS[0]} "Error Syncring Task $BACKUP_NAME"
  else
    FS_TRACE INFO "$BACKUP_COMMAND"
    echo expect -f $EXPECT Local \
	  -password $PASSWORD \
	  -command "$BACKUP_COMMAND"
    expect -f $EXPECT Local \
	  -password $PASSWORD \
	  -command "$BACKUP_COMMAND"
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

