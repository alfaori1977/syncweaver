#!/bin/bash
KSH_DIR=$(cd $(dirname $BASH_SOURCE); pwd -L; cd - >/dev/null)
export EXPECT=$KSH_DIR/m_scp_exec.exp

export BLACK="\033[0;30m"
export DGRAY="\033[1;30m"
export BLUE="\033[0;34m"    
export LBLUE="\033[1;34m"
export GREEN="\033[0;32m"     
export LGREEN="\033[1;32m"
export CYAN="\033[0;36m"     
export LCYAN="\033[1;36m"
export RED="\033[0;31m"     
export LRED="\033[1;31m"  
export PURPLE="\033[0;35m"       
export LPURPLE="\033[1;35m"  
export BROWN="\033[0;33m"     
export YELLOW="\033[1;33m"
export LGRAY="\033[0;37m"    
export WHITE="\033[1;37m"

export OK=$BLUE
export DEBUG=$LPURPLE
export INFO=$GREEN
export WARNING=$YELLOW
export QUESTION=$YELLOW
export FATAL=$RED
export ERROR=$RED
export NONE="\033[0m"
export BOLD="\033[1m"

export LOG_FILE_NAME=_default
export LOG_FILE_OUT=_default.log
export LOG_FILE_ERR=_default.err
export LOG_FILE_XML=_default.xml
export LOG_FILE_HTML=_default.xml
export LOG_FILE_DEP=_default.dep
export LOG_FILE_BLST=_default.blstatus
export LOG_FILE_FILES=_default.files
export LOG_FILE_DIR=.

function FS_GET_COLOR_STR
{
  TEXT="$1"
  COLOR=$2
  printf "\${%s}%s\${%s}" "$COLOR" "$TEXT" "NONE"
}
export -f FS_GET_COLOR_STR

function FS_COLOR_STR
{
  TEXT="$1"
  COLOR=$2
  eval echo -e $(FS_GET_COLOR_STR "$TEXT" $COLOR)
}
export -f FS_COLOR_STR

function FS_TRACE
{
  LVL=$1
  MSG="$2"
  DATE=${3:-0}
  DATE_STR=""
  _ERROR_STATUS=${4:-2}
  shift $#
  if [ $DATE -eq 1 ]; then
    DATE_STR=" \${LBLUE}$(date +%Y%m%d@%H:%M:%S)\${NONE}"
  fi

  LF="\n"
  STRING=$(printf "%s %s: %s\n" \
    $(FS_COLOR_STR $LVL $LVL) \
    $(FS_COLOR_STR "$DATE_STR" LBLUE) \
    $MSG)

  if [ $LVL == "FATAL" -o  $LVL == "ERROR" ]; then
    #eval echo -e $STRING | tee -a $LOG_FILE_ERR
    eval echo -e "\$${LVL}\"#$LVL#\"\${NONE}$DATE_STR: \"$MSG\"" >> $LOG_FILE_OUT    
    eval echo -e "\$${LVL}\"#$LVL#\"\${NONE}$DATE_STR: \"$MSG\"" | tee -a $LOG_FILE_ERR
  else
    #eval echo -e $STRING | tee -a $LOG_FILE_OUT
    eval echo -e "\$${LVL}\"#$LVL#\"\${NONE}$DATE_STR: \"$MSG\"" | tee -a $LOG_FILE_OUT
  fi

  if [ $LVL == "FATAL" ]; then
    exit $_ERROR_STATUS
  fi
}
export -f FS_TRACE

function FS_TRACE_XML_OLD
{
    TAG_KIND=$1
    TAG_NAME=$2
    ATTRIBS=""
    NL=${4:-YES}
    if [ -n "$3" ]; then
	ATTRIBS=" $3"
    fi
    MOD=""

    if [ $TAG_KIND = "close" ]; then
       MOD="/"printf "<%s%s%s>" "$MOD" "$TAG_NAME" "$ATTRIBS" >> $LOG_FILE_XML
    fi

    if [ $NL == YES ] ; then
	printf "<%s%s%s>\n" "$MOD" "$TAG_NAME" "$ATTRIBS"  >> $LOG_FILE_XML
    else
	printf "<%s%s%s>" "$MOD" "$TAG_NAME" "$ATTRIBS" >> $LOG_FILE_XML
    fi
}
export -f FS_TRACE_XML_OLD

function FS_GET_USER_COMMAND_FULL_NAME
{
    echo $LOG_FILE_FILES/$FULL_PRODUCT.$CURRENT_PHASE_NAME
}
export -f FS_GET_USER_COMMAND_FULL_NAME

function FS_GET_USER_COMMAND_REL_NAME
{
    echo $(basename $LOG_FILE_FILES)/$FULL_PRODUCT.$CURRENT_PHASE_NAME
}
export -f FS_GET_USER_COMMAND_REL_NAME

function FS_TRACE_XML
{
    TAG_KIND=$1
    TAG_NAME=$2
    ATTRIBS=""
    if [ -n "$3" ]; then
	ATTRIBS=" $3"
    fi
    NL=${4:-YES}

    if [ $NL == YES ] ; then
	NL_MOD=\\n
    fi

    MOD=""
    if [ $TAG_KIND = "close" ]; then
       MOD="/"
    fi

    if [ $TAG_KIND = "open" ]; then
	format_str=$(printf "<%s%s>%s" %s %s $NL_MOD)
	printf $format_str "$TAG_NAME" "$ATTRIBS" >> $LOG_FILE_XML
    elif [ $TAG_KIND = "close" ]; then
	format_str=$(printf "</%s%s>%s" %s %s $NL_MOD)
        printf $format_str "$TAG_NAME" "$ATTRIBS" >> $LOG_FILE_XML
    elif [ $TAG_KIND = "openclose" ]; then
	format_str=$(printf "<%s%s/>%s" %s %s $NL_MOD)
        printf "<%s%s/>%s" "$TAG_NAME" "$ATTRIBS" >> $LOG_FILE_XML
    fi	

}
export -f FS_TRACE_XML

function FS_TRACE_XML_CDATA
{
    TAG_KIND=$1
    TAG_NAME=${2:-""}
    ATTRIBS=${3:-""}
    VALUE=${4:-""}

    if [ $TAG_KIND = "open" ]; then
	if [ -n "$TAG_NAME" ]; then
	    FS_TRACE_XML $TAG_KIND "$TAG_NAME" "$ATTRIBS" NO
	fi
	printf "<![CDATA[\n" >> $LOG_FILE_XML
	if [ -n "$VALUE" ]; then
	    printf "$VALUE" >> $LOG_FILE_XML
	fi
    else
	printf "]]>" >> $LOG_FILE_XML
	if [ -n "$TAG_NAME" ]; then
	    FS_TRACE_XML $TAG_KIND "$TAG_NAME"
	fi
    fi

}
export -f FS_TRACE_XML_CDATA

function FS_TRACE_XML_USER_TRACE
{
    LVL=$1
    MSG="$2"
    _STATUS=${3:-0}

    FS_TRACE_XML_CDATA open TRACE "level='$LVL' code='$_STATUS' date='$(date +%Y%m%d@%H:%M:%S)'" "$MSG"
    FS_TRACE_XML_CDATA close TRACE
}

export -f FS_TRACE_XML_USER_TRACE

function FS_MARK_PHASE_AS_FAILED
{
    _STATUS=$1
    CURRENT_PRODUCT_FAILED_PHASE=$CURRENT_PHASE_NAME
    CURRENT_PRODUCT_STATUS=$_STATUS
    CURRENT_PHASE_STATUS=$_STATUS
    
}
export -f FS_MARK_PHASE_AS_FAILED

function FS_ABORT_CURRENT_PHASE
{
    MSG="$1"
    _STATUS=$2
    LVL=${3:-FATAL}
    eval echo -e "\$${LVL}\"#$LVL#\"\${NONE}: \"$MSG\"" | tee -a $LOG_FILE_OUT    
    FS_TRACE_XML_USER_TRACE $LVL "$MSG" $_STATUS
    CURRENT_PHASE_STATUS=$_STATUS
    FS_TRACE_PHASE_END INFO
}
export -f FS_ABORT_CURRENT_PHASE

function FS_ABORT_CURRENT_PHASE_AND_PRODUCT
{
    MSG="$1"
    _STATUS=$2
    LVL=${3:-FATAL}
    #echo -e "${FATAL}#FATAL#${NONE}: $MSG" >> $LOG_FILE_OUT
    #echo -e "${FATAL}#FATAL#${NONE}: $MSG"  | tee -a $LOG_FILE_ERR
    eval echo -e "\$${LVL}\"#$LVL#\"\${NONE}: \"$MSG\"" | tee -a $LOG_FILE_OUT    
    FS_TRACE_XML_USER_TRACE $LVL "$MSG" $_STATUS
    CURRENT_PRODUCT_FAILED_PHASE=$CURRENT_PHASE_NAME
    CURRENT_PRODUCT_STATUS=$_STATUS
    CURRENT_PHASE_STATUS=$_STATUS
    FS_TRACE_PHASE_END INFO
    FS_TRACE_PRODUCT_END INFO $_STATUS

    #echo rm -f $TMP_FILE /tmp/*COMMAND.$AUTOBUILD_PID
    rm -f $TMP_FILE /tmp/*_COMMAND.$AUTOBUILD_PID*
    exit $_STATUS
}
export -f FS_ABORT_CURRENT_PHASE_AND_PRODUCT

function FS_DEBUG
{
  MSG="$1"
  DEBUG_LEVEL=${2:-$DEBUG_LEVEL}
  shift $#
  if [ "$DEBUG_LEVEL" == "DEBUG" ]; then
    FS_TRACE DEBUG "$MSG"
  fi

}
export -f FS_DEBUG

function FS_SEPARATOR
{
  FS_TRACE INFO "********************************************************************************"

}
export -f FS_SEPARATOR

function FS_QUESTION
{
  MSG=$1
  OPTIONS=${2:-""}
  COUNT=${3:-1000}
  LVL=QUESTION

  if [ -z "$OPTIONS" ]; then
    FS_TRACE QUESTION "$MSG :"
    read -e ANSWER
  else
    FS_TRACE QUESTION "$MSG [$OPTIONS]:"
    read -e ANSWER
    
  fi
}
export -f FS_QUESTION

function FS_TRACE_PRODUCT
{
  _LVL=$1
  _PRODUCT=$2
  _DATE_STR="$(date +%Y%m%d@%H:%M:%S)"

  FS_TRACE $_LVL  "--------------------------------------------------------------------------------"
  FS_TRACE $_LVL "- ${INFO}PRODUCT: $_PRODUCT${NONE}"
  FS_TRACE $_LVL "- ${LBLUE}$_DATE_STR${NONE}"
  FS_TRACE $_LVL "-"
  export CURRENT_PRODUCT=$_PRODUCT
  export CURRENT_PRODUCT_STATUS=0
  export CURRENT_PRODUCT_FAILED_PHASE=""
  FS_TRACE_XML open PRODUCT "name='$CURRENT_PRODUCT' date='$_DATE_STR'"
  FS_SEND_LOG_TO_LISTENER "$LISTENER_SOCKET" $_LVL "PRODUCT_START" "name $CURRENT_PRODUCT"
}
export -f FS_TRACE_PRODUCT

function FS_TRACE_PRODUCT_END
{
  _LVL=$1
  _STATUS=${2:-"?"}
  _DATE_STR="$(date +%Y%m%d@%H:%M:%S)"
  _STCOLOR=GREEN
  if [ $_STATUS != "0" ]; then
      _STCOLOR=RED
  fi
  
  FS_TRACE $_LVL "-"
  FS_TRACE $_LVL "- ${LBLUE}$_DATE_STR${NONE}"
  FS_TRACE $_LVL "- ${INFO}END_PRODUCT: $CURRENT_PRODUCT${NONE} STATUS: $(FS_GET_COLOR_STR $_STATUS $_STCOLOR)"
  FS_TRACE $_LVL  "--------------------------------------------------------------------------------"
  
  if [ $CURRENT_PRODUCT_STATUS -eq 0 ]; then
      FS_TRACE_XML openclose STATUS "code='$CURRENT_PRODUCT_STATUS' date='$(date +%Y%m%d@%H:%M:%S)'"
  else
     FS_TRACE_XML openclose STATUS "code='$CURRENT_PRODUCT_STATUS' failedPhase='$CURRENT_PRODUCT_FAILED_PHASE' date='$(date +%Y%m%d@%H:%M:%S)'"
  fi

  FS_TRACE_XML close PRODUCT
  FS_SEND_LOG_TO_LISTENER "$LISTENER_SOCKET" $_LVL "PRODUCT_END" "name $CURRENT_PRODUCT" "status $CURRENT_PRODUCT_STATUS" "failedPhase $CURRENT_PRODUCT_FAILED_PHASE"
  unset CURRENT_PRODUCT
  unset CURRENT_PRODUCT_STATUS
  unset CURRENT_PRODUCT_FAILED_PHASE
}
export -f FS_TRACE_PRODUCT_END


function FS_TRACE_PHASE
{
  _LVL=$1
  _MSG=$2
  _NAME=$3
  _DATE_STR="$(date +%Y%m%d@%H:%M:%S)"

  FS_TRACE $_LVL  "--------------------------------------------------------------------------------"
  FS_TRACE $_LVL "- ${INFO}PHASE: $_MSG${NONE}"
  FS_TRACE $_LVL "- ${LBLUE}$_DATE_STR${NONE}"
  FS_TRACE $_LVL "-"
  export CURRENT_PHASE_STATUS=0
  export CURRENT_PHASE=$_MSG
  export CURRENT_PHASE_NAME=$_NAME
  FS_TRACE_XML open PHASE "name='$CURRENT_PHASE_NAME' desc='$CURRENT_PHASE' date='$_DATE_STR'"
  FS_SEND_LOG_TO_LISTENER "$LISTENER_SOCKET" $_LVL \
    "PHASE_START" "name '$CURRENT_PHASE_NAME'" "desc '$CURRENT_PHASE'" "product '$CURRENT_PRODUCT'"
}
export -f FS_TRACE_PHASE

function FS_TRACE_PHASE_END
{
  _LVL=$1
  _DATE_STR="$(date +%Y%m%d@%H:%M:%S)"

  FS_TRACE $_LVL "-"
  FS_TRACE $_LVL "- ${LBLUE}$_DATE_STR${NONE}"
  FS_TRACE $_LVL "- ${INFO}END_PHASE: $CURRENT_PHASE${NONE}"
  FS_TRACE $_LVL  "--------------------------------------------------------------------------------"
  FS_TRACE_XML openclose STATUS "code='$CURRENT_PHASE_STATUS' date='$(date +%Y%m%d@%H:%M:%S)'"
  FS_TRACE_XML close PHASE
  FS_SEND_LOG_TO_LISTENER "$LISTENER_SOCKET" $_LVL "PHASE_END" "name '$CURRENT_PHASE_NAME'" "status $CURRENT_PHASE_STATUS"
  unset CURRENT_PHASE_NAME
  unset CURRENT_PHASE
  unset CURRENT_PHASE_STATUS
}
export -f FS_TRACE_PHASE_END

function FS_TRACE_SUBPHASE
{
  _LVL=$1
  _MSG=$2
  _DATE_STR="$(date +%Y%m%d@%H:%M:%S)"

  FS_TRACE $_LVL  "--------------------------------------------------------------------------------"
  FS_TRACE $_LVL "- ${INFO}SUBPHASE: $_MSG${NONE}"
  FS_TRACE $_LVL "- ${INFO}PHASE   : $CURRENT_PHASE${NONE}"
  FS_TRACE $_LVL "- ${LBLUE}$_DATE_STR${NONE}"
  FS_TRACE $_LVL "-"
  export CURRENT_SUBPHASE=$_MSG
}
export -f FS_TRACE_SUBPHASE

function FS_TRACE_SUBPHASE_END
{
  _LVL=$1
  _MSG=$2
  _DATE_STR="$(date +%Y%m%d@%H:%M:%S)"

  FS_TRACE $_LVL "-"
  FS_TRACE $_LVL "- ${LBLUE}$_DATE_STR${NONE}"
  FS_TRACE $_LVL "- ${INFO}PHASE   : $CURRENT_PHASE${NONE}"
  FS_TRACE $_LVL "- ${INFO}END_SUBPHASE: $_MSG${NONE}"
  FS_TRACE $_LVL  "--------------------------------------------------------------------------------"
  unset CURRENT_SUBPHASE
}
export -f FS_TRACE_SUBPHASE_END

function FS_SEND_TO_LISTENER
{
  if [ -z $LISTENER_SOCKET ]; then 
    return
  fi

  _ARGC=$#
  LISTENER_SOCKET=$1
  FS_COMPUTE_HOST_AND_PORT $LISTENER_SOCKET
  _KIND=$2
  shift 2
 
  DATA="$_KIND"
  for arg in $(seq 3 $_ARGC); do
    DATA=$DATA:$1
    shift
  done

  _DATE_STR="$(date +%Y%m%d@%H:%M:%S)"  
  DATA=$DATA:"date $_DATE_STR"

  FS_TRACE INFO "SENDING_DATA to $HOST:$PORT->$DATA"
  echo $DATA nc -u $HOST $PORT -w0
  echo $DATA | nc -u $HOST $PORT -w0 2>/dev/null

}
export -f FS_SEND_TO_LISTENER

function FS_SEND_STATUS_TO_LISTENER
{
  LISTENER_SOCKET=$1
  FS_COMPUTE_HOST_AND_PORT $LISTENER_SOCKET
  _KIND=STATUS
  shift 1
  
  FS_SEND_TO_LISTENER "$LISTENER_SOCKET" $_KIND "$@"


}
export -f FS_SEND_STATUS_TO_LISTENER

function FS_SEND_LOG_TO_LISTENER
{
  LISTENER_SOCKET=$1
  FS_COMPUTE_HOST_AND_PORT $LISTENER_SOCKET
  _KIND=LOG
  LEVEL=$2
  shift 2
  
  FS_SEND_TO_LISTENER "$LISTENER_SOCKET" $_KIND $LEVEL "$@"


}
export -f FS_SEND_LOG_TO_LISTENER






function FS_RESET_LOG_FILE
{
  LOG_FILE_NAME=$(basename $1)
  LOG_FILE_DIR=$(cd $(dirname $1) >/dev/null; pwd -L; cd - >/dev/null)
  LOG_FILE_OUT=$LOG_FILE_DIR/$LOG_FILE_NAME.log
  LOG_FILE_ERR=$LOG_FILE_DIR/$LOG_FILE_NAME.err
  LOG_FILE_XML=$LOG_FILE_DIR/$LOG_FILE_NAME.xml
  LOG_FILE_HTML=$LOG_FILE_DIR/$LOG_FILE_NAME.html
  LOG_FILE_DEP=$LOG_FILE_DIR/$LOG_FILE_NAME.dep
  LOG_FILE_BLST=$LOG_FILE_DIR/$LOG_FILE_NAME.blstatus
  LOG_FILE_FILES=$LOG_FILE_DIR/$LOG_FILE_NAME.files
  
  
  if [ -f $LOG_FILE_OUT ]; then
    mv  $LOG_FILE_OUT   $LOG_FILE_OUT.old 2>/dev/null
    mv  $LOG_FILE_XML   $LOG_FILE_XML.old 2>/dev/null
    mv  $LOG_FILE_ERR   $LOG_FILE_ERR.old 2>/dev/null
    mv  $LOG_FILE_HTML  $LOG_FILE_HTML.old 2>/dev/null
    mv  $LOG_FILE_DEP   $LOG_FILE_DEP.old 2>/dev/null
    mv  $LOG_FILE_BLST  $LOG_FILE_BLST.old 2>/dev/null
    rm -rf $LOG_FILE_FILES.old 2>/dev/null
    mv  $LOG_FILE_FILES $LOG_FILE_FILES.old 2>/dev/null
  fi
  mkdir -p $LOG_FILE_FILES
}
export -f FS_RESET_LOG_FILE


function FS_SET_LOG_FILE
{
  LOG_FILE_OUT=$1.log
  LOG_FILE_ERR=$1.err
  LOG_FILE_XML=$1.xml
  LOG_FILE_HTML=$1.html
  LOG_FILE_DEP=$1.dep
  LOG_FILE_BLST=$1.dep
  LOG_FILE_FILES=$1.files
  LOG_FILE_DIR=$(cd $(dirname $LOG_FILE_OUT); pwd -L; cd - >/dev/null)
}
export -f FS_SET_LOG_FILE

function FS_CHECK_EXIT_STATUS
{
  _STATUS=$1
  _MSG=$2
  _ABORT=${3:-1}
  _ALLOW=${4:-""}

  if [ $_STATUS -ne 0 ]; then
    MUST_EXIT=$(echo "$_ALLOW" | grep -w $_STATUS 2>/dev/null >/dev/null; echo $?)
    if [ $_ABORT -eq 1 ]; then
      if [ $MUST_EXIT -eq 1 ]; then
        #FS_TRACE FATAL "$_MSG (Exit Status: $_STATUS)" 0 $_STATUS
        #exit $_STATUS
	FS_ABORT_CURRENT_PHASE_AND_PRODUCT "$_MSG (Exit Status: $_STATUS)"  $_STATUS
       else
        FS_TRACE ERROR "$_MSG (Exit Status: $_STATUS)" 
      fi
    else
      if [ $MUST_EXIT -eq 1 ]; then
        FS_TRACE WARNING "$_MSG (Exit Status: $_STATUS)"
      else
        FS_TRACE WARNING "$_MSG (Exit Status: $_STATUS)"
      fi

    fi
  fi
}
export -f FS_CHECK_EXIT_STATUS



function FS_EXEC_PASSWORD_COMMAND
{
    #COMMAND="$(eval echo "$1")"
    COMMAND="$(echo $1)"
    PASSWORD=${2:-$PASSWORD}
    TIMEOUT=${3:-"-1"}
    #echo expect -f $EXPECT Local \
      #-password $PASSWORD \
      #-command "$COMMAND" \
      #-timeout "$TIMEOUT"
    expect -f $EXPECT Local \
      -password $PASSWORD \
      -command "$COMMAND" \
      -timeout "$TIMEOUT" \
      -log_user 0

}
export -f FS_EXEC_PASSWORD_COMMAND

function FS_COMPUTE_HOST_AND_PORT
{
    HOST_PORT=$1
    
    PORT=$(echo $HOST_PORT | awk -F':' '{print $2}')
    HOST=$(echo $HOST_PORT | awk -F':' '{print $1}')
    TARGET_HOST=$(echo $HOST_PORT | awk -F':' '{print $3}')
    TARGET_PORT=$(echo $HOST_PORT | awk -F':' '{print $4}')

    PORT=${PORT:-22}
    TARGET_HOST=${TARGET_HOST:-$HOST}
    TARGET_PORT=${TARGET_PORT:-22}
}
export -f FS_COMPUTE_HOST_AND_PORT

    
function FS_EXEC_REMOTE_COMMAND
{
    HOST="$1"
    USER="$2"
    COMMAND="$3"
    USER_LOG=${4:-0}
    PASSWORD=${5:-$PASSWORD}
    FS_COMPUTE_HOST_AND_PORT $HOST
    
    expect -f $EXPECT Exec \
	-host $HOST \
	-port $PORT \
	-tgt_host $TARGET_HOST \
	-user $USER \
	-password "$PASSWORD" \
	-command "$COMMAND" \
	-user_log "$USER_LOG"
    
}
export -f FS_EXEC_REMOTE_COMMAND

function FS_COMPUTE_DEST
{
    DEST=$1
    REMOTE_PATH=${DEST##*:}
    HOST_PORT=${DEST%:*}

    FS_COMPUTE_HOST_AND_PORT $HOST_PORT
    
}
export -f FS_COMPUTE_DEST


function FS_SCP_COMMAND
{
    ORIG="$1"
    DEST="$2"
    PASSWORD=${3:-$PASSWORD}

    FS_COMPUTE_DEST $DEST
    
    expect -f $EXPECT Scp \
	-orig "$ORIG" \
	-port $PORT \
	-dest $HOST:$REMOTE_PATH \
	-password "$PASSWORD"
}
export -f FS_SCP_COMMAND

function FS_EXPAND_FILE
{

    INPUT_FILE=$1
    OUTPUT_FILE=$2
    TMP_FILE=_exp_file.tmp

    cat <<END > $TMP_FILE
cat <<EOF > $OUTPUT_FILE
$(cat $INPUT_FILE)
EOF
END

   . $TMP_FILE
   rm $TMP_FILE
}
export -f FS_EXPAND_FILE

function RemoteTunnel
{
    SRCHOST=$1
    SRCPORT=$2
    TGTHOST=$3
    TGTPORT=$4

    USR=$5
    GATEWAY=$6

    STATUS=0
    if ! ps -ef | grep -- 'ssh -f -R' | grep "$SRCHOST:$SRCPORT:" | grep $USR@$GATEWAY  >/dev/null; then  

	FS_TRACE INFO "LAUNCHING Remote SSH Tunnel $SRCHOST:$SRCPORT:$TGTHOST:$TGTPORT via $USR@$GATEWAY"
	COMMAND="ssh -f -R $SRCHOST:$SRCPORT:$TGTHOST:$TGTPORT $USR@$GATEWAY -N"

	FS_TRACE DEBUG "$COMMAND (PASSWORD:$PASSWORD)"
	FS_EXEC_PASSWORD_COMMAND "$COMMAND" $PASSWORD

	STATUS=$?
    fi
    
    if [ $STATUS -eq 0 ]; then	
	echo -e "${LGREEN}ESTABLISHED${NONE} Remote SSH Tunnel $SRCHOST:$SRCPORT:$TGTHOST:$TGTPORT via $USR@$GATEWAY"
    fi
}
export -f RemoteTunnel

#Example
#LocalTunnel localhost 56789 itectools3 5900 nor itectools3 i3 vnc
function LocalTunnel
{
    SRCHOST=$1
    SRCPORT=$2
    TGTHOST=$3
    TGTPORT=$4

    USR=$5
    GATEWAY=$6
    ALIAS=$7
    KIND=$8
    PORT=${9:-22}
    TIMEOUT=${10:-1}

    STATUS=0
    if ! ps -ef | grep -- 'ssh -f -L' | grep "$SRCHOST:$SRCPORT:"  >/dev/null; then  

	echo "LAUNCHING Local SSH Tunnel $SRCHOST:$SRCPORT:$TGTHOST:$TGTPORT via $USR@$GATEWAY -p$PORT"
	COMMAND="ssh -f -L $SRCHOST:$SRCPORT:$TGTHOST:$TGTPORT $USR@$GATEWAY -p$PORT -N"

	FS_TRACE DEBUG "$COMMAND (PASSWORD:$PASSWORD)"
	FS_EXEC_PASSWORD_COMMAND "$COMMAND" $PASSWORD $TIMEOUT
	
	STATUS=$?
    fi
    
    if [ $STATUS -eq 0 ]; then
	if [ "$KIND" == "ssh" ]; then
	    alias $ALIAS="ssh -X nor@$SRCHOST -p $SRCPORT"
	    alias $ALIAS
	elif [ "$KIND" == "vnc" ]; then
	    alias ${ALIAS}-vnc="vncviewer $SRCHOST:$SRCPORT"
	    alias ${ALIAS}-vnc
	fi	
    fi
}
export -f LocalTunnel

function KillLocalTunnel
{
    SRCHOST=$1
    SRCPORT=$2
    TGTHOST=$3
    TGTPORT=$4

    USR=$5
    GATEWAY=$6
    ALIAS=$7
    KIND=${8:-ssh}

    STATUS=0

    kill -9 $(ps -ef | grep -v grep |  grep -- 'ssh -f -L' | grep "$SRCHOST:$SRCPORT:" | awk '{print $2}')  2>/dev/null
	
}
export -f KillLocalTunnel

function FS_CREATE_VIEW
{ 
  VIEW_NAME=$1
  if ! IS_AN_VALID_VIEW $VIEW_NAME; then
    if [ $GLOBAL_COTS_DIR/create_snapshot_view.sh ]; then
      echo $GLOBAL_COTS_DIR/create_snapshot_view.sh  $VIEW_NAME noload
    else
      FS_TRACE FATAL "Error creating view name: $VIEW_NAME. Script: $GLOBAL_COTS_DIR/create_snapshot_view.sh not found." 0 34
    fi
  else
    FS_TRACE FATAL "Error creating view name: $VIEW_NAME. It already exists." 0 33
  fi

}
export -f FS_CREATE_VIEW

function IS_AN_SNAPSHOT_VIEW
{
  VIEW_NAME=$1
  [[ -n $(/usr/atria/bin/cleartool lsview -l $VIEW_NAME 2>/dev/null | grep "View attributes: snapshot") ]]
}
export -f IS_AN_SNAPSHOT_VIEW

function IS_AN_VALID_VIEW
{
  VIEW_NAME=$1
  [[ -n $(/usr/atria/bin/cleartool lsview -l $VIEW_NAME 2>/dev/null | grep "View on host: $(hostname)") ]]
}
export -f IS_AN_VALID_VIEW


function FS_RUN_SCRIPT_AT_DYNAMIC
{

  SCRIPT=$1
  VIEW_NAME=$2
  export DISPLAY=:0.0
  export VIEW_CHANGE=TRUE
  /usr/atria/bin/cleartool setview \
    -login -exec "$SCRIPT" \
    $VIEW_NAME  
}
export -f FS_RUN_SCRIPT_AT_DYNAMIC


function FS_RUN_SCRIPT_AT_SNAPSHOT
{

  SCRIPT=$1
  VIEW_NAME=$2
  UPDATE=${3:-0}
 
  pSetSnapshotView $VIEW_NAME
  cd /$VIEW_NAME
  if [ $UPDATE -eq 1 ]; then
      /usr/atria/bin/cleartool update
  fi
  export DISPLAY=:0.0
  ( eval $SCRIPT ) 
}
export -f FS_RUN_SCRIPT_AT_SNAPSHOT

function FS_RUN_SCRIPT_AT_VIEW
{
  SCRIPT=$1
  VIEW_NAME=$2
  UPDATE=${3:-0}
  
  if IS_AN_SNAPSHOT_VIEW $VIEW_NAME; then
    
    FS_RUN_SCRIPT_AT_SNAPSHOT \
      "$SCRIPT" $VIEW_NAME $UPDATE
    
  else
    
    FS_RUN_SCRIPT_AT_DYNAMIC \
      "$SCRIPT" $VIEW_NAME
  fi
}
export -f FS_RUN_SCRIPT_AT_VIEW

#==============================================================================
# FS_EXISTS_VERSION_LABEL
#
function FS_EXISTS_LABEL
{
    LABEL=$1
    VOB=${2:-.}
    /usr/atria/bin/cleartool describe lbtype:$LABEL@$VOB >/dev/null 2>/dev/null
}
export -f FS_EXISTS_LABEL


#==============================================================================
# FS_CREATE_VERSION_LABEL
#
function FS_CREATE_LABEL
{
    LABEL=$1
    VOB=${2:-.}
    if ! FS_EXISTS_LABEL $LABEL $VOB; then
	if ! /usr/atria/bin/cleartool mklbtype -nc -global $LABEL@$VOB
	then
            FS_TRACE ERROR "Error creating label name: $LABEL"
	fi
    fi

}
export -f FS_CREATE_LABEL

#==============================================================================
# FS_IS_LOCKED_LABEL
#
function FS_IS_LOCKED_LABEL
{
    LABEL=$1
    VOB=${2:-.}
    /usr/atria/bin/cleartool lslock lbtype:$LABEL@$VOB |  grep lock >/dev/null
}
export -f FS_IS_LOCKED_LABEL

#==============================================================================
# FS_IS_LOCKED_VOB
#
function FS_IS_LOCKED_VOB
{
  VOB=$1
  /usr/atria/bin/cleartool lslock vob:$VOB |  grep lock >/dev/null
}
export -f FS_IS_LOCKED_VOB

#==============================================================================
# FS_LOCK_VERSION_LABEL
#
function FS_LOCK_LABEL
{
    LABEL=$1
    VOB=${2:-.}
    if ! FS_IS_LOCKED_LABEL $LABEL $VOB; then
	/usr/atria/bin/cleartool lock lbtype:$LABEL@$VOB
    fi
}
export -f FS_LOCK_LABEL

#==============================================================================
# FS_UNLOCK_VERSION_LABEL
#
function FS_UNLOCK_LABEL
{
    LABEL=$1
    VOB=${2:-.}
    if FS_IS_LOCKED_LABEL $LABEL $VOB; then
	/usr/atria/bin/cleartool unlock lbtype:$LABEL@$VOB
    fi
	
}
export -f FS_UNLOCK_LABEL

function FS_LABEL_VOB
{
    LABEL=$1
    VOB=$2
    REC=${3:-""}
    REP=${4:-""}
    FORCE=${5:-0}
    VERBOSE=${6:-0}

    STDOUT=">/dev/null"
    if [ $VERBOSE -eq 1 ]; then
      STDOUT=""
    fi

    if FS_IS_LOCKED_VOB $VOB; then
      FS_TRACE ERROR "VOB:$VOB is Locked. Skipping!!!"
      return 1
    fi

    VOB_PATH=$(echo $VOB | awk -v cview=$CURRENT_VIEW '{sub(/^\/[^\/]+\//,"/" cview "/"); print}')
    if [ ! -d $VOB_PATH ]; then
      FS_TRACE ERROR "Missing DIR:$VOB_PATH for VOB:$VOB"
      return 2
    fi

    cd $VOB_PATH

    if ! FS_IS_LOCKED_LABEL $LABEL $VOB; then
      FS_TRACE INFO "$LABEL@$VOB  unlocked. Labelling $LABEL@$VOB ($REC $REP) ..."
      eval /usr/atria/bin/cleartool mklabel $REC $REP $LABEL . $STDOUT 
    else
      if [ $FORCE -eq 1 ]; then
	FS_TRACE INFO "$LABEL@$VOB is locked. Unlocking and Labelling $LABEL@$VOB ($REC $REP) ..."
	FS_UNLOCK_LABEL $LABEL $VOB
	eval /usr/atria/bin/cleartool mklabel $REC $REP $LABEL . $STDOUT 
      else	
	FS_TRACE WARNING "$LABEL@$VOB is locked. Use FORCE=1 to proceed."
        return 3
      fi
    fi

    cd -
}
export -f FS_LABEL_VOB


function FS_LIST_LABELS
{

  /usr/atria/bin/cleartool lstype -kind lbtype

}
export -f FS_LIST_LABELS

function FS_REMOVE_LABEL
{
    LABEL=$1
    VOB=${2:-.}
    FORCE=${3:-0}
    if FS_EXISTS_LABEL $LABEL $VOB; then
	if ! FS_IS_LOCKED_LABEL $LABEL $VOB; then
	    FS_TRACE INFO "$LABEL@$VOB unlocked. Proceeding..."
	    /usr/atria/bin/cleartool rmtype -rmall -force lbtype:$LABEL@$VOB
	else
	    if [ $FORCE -eq 1 ]; then
		FS_TRACE INFO "$LABEL@$VOB is locked. Unlocking and proceeding..."
		FS_UNLOCK_LABEL $LABEL $VOB
		/usr/atria/bin/cleartool rmtype -rmall -force lbtype:$LABEL@$VOB
	    else
		FS_TRACE WARNING "$LABEL@$VOB is locked. Use FORCE=1 to proceed."
	    fi
	fi
    fi

}
export -f FS_REMOVE_LABEL

function FS_RENAME_LABEL
{
    SRC_LABEL=$1
    TGT_LABEL=$2
    VOB=${3:-.}

    if FS_EXISTS_LABEL $SRC_LABEL $VOB; then
	if ! FS_EXISTS_LABEL $TGT_LABEL $VOB; then
	    /usr/atria/bin/cleartool rename lbtype:$SRC_LABEL@$VOB $TGT_LABEL
	fi
    fi

}
export -f FS_REMOVE_LABEL


#FS_EXEC_PASSWORD_COMMAND "ssh install-server1 ls"
#FS_EXEC_REMOTE_COMMAND install-server1 nor ls
#FS_SCP_COMMAND version.py nor@install-server1:/tmp 
