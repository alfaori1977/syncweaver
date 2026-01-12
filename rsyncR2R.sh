SOURCE_USER=nor
SOURCE_HOST=natsserver2
SOURCE_PATH=ess/xmlFilterAndDump

TARGET_USER=alfaori
TARGET_HOST=NASI
TARGET_PATH=/volume2/data/test

FREE_PORT=54123

echo ssh -l $SOURCE_USER  -R localhost:$FREE_PORT:$TARGET_HOST:22 \
    $SOURCE_USER@$SOURCE_HOST "rsync -e 'ssh -p $FREE_PORT' -av $SOURCE_PATH \
      $TARGET_USER@localhost:$TARGET_PATH"
