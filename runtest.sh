#!/bin/bash

print_usage(){
	USAGE="Usage: `basename $0` [options] <test-config>.xml"

	echo -e "$USAGE\n"
            
             	echo -e " -----[Options]-----";
           	echo -e "";
           	echo -e "	-o	<file>             Write generated test-plan to file and don't start tests.";
          	echo -e "	-j	<jmx-url>          The url to monitor for eXists jmx status. Default is $JMXURL";
          	echo -e ""
}

set -e;

get_real_script_path()
{
	case $0 in
    /*)
        SCRIPT="$0"
        ;;
    *)
        PWD=`pwd`
        SCRIPT="$PWD/$0"
        ;;
	esac

	# Change spaces to ":" so the tokens can be parsed.
	SCRIPT=`echo $SCRIPT | sed -e 's; ;:;g'`
	# Get the real path to this script, resolving any symbolic links
	TOKENS=`echo $SCRIPT | sed -e 's;/; ;g'`
	REALPATH=
	for C in $TOKENS; do
	    REALPATH="$REALPATH/$C"
	    while [ -h "$REALPATH" ] ; do
	        LS="`ls -ld "$REALPATH"`"
	        LINK="`expr "$LS" : '.*-> \(.*\)$'`"
	        if expr "$LINK" : '/.*' > /dev/null; then
	            REALPATH="$LINK"
	        else
	            REALPATH="`dirname "$REALPATH"`""/$LINK"
	        fi
	    done
	done
	# Change ":" chars back to spaces.
	REALPATH=`echo $REALPATH | sed -e 's;:; ;g'`
	
	echo $REALPATH
}

SCRIPT_PATH=$(get_real_script_path $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)


test_cleanup()
{
	rm $GEN_TEST_PLAN;
	cd $CUR_DIR;
}

DEBUG="true";

JMXURL="localhost:8080/exist/status?c=locking";
# Parse command line options.
while getopts ho:m: OPT; do
    case "$OPT" in
        h)
            print_usage
            exit 0
           ;;
        m)
            TEST_MODIFIER=$OPTARG
            ;;
            
	     j)
	        JMXURL=$OPTARG
	        ;;
        o)
        	WRITE_TEST_PLAN=$OPTARG;
        ;;
       
        \?)
            # getopts issues an error message
            
            echo "" >&2
            
            print_usage
            exit 1
            ;;
    esac
done



# Remove the switches we parsed above.
shift `expr $OPTIND - 1`


TEST_PLAN=$1;

if [ "$TEST_PLAN" = "" ] 
then
	echo -e "\nError: you must specify a test plan\n";
	print_usage
	exit 1;
fi

CUR_DATETIME=$(date '+%Y%m%d-%H%M')

# Generate the test plan
GEN_TEST_PLAN=$(java  -jar ./lib/saxon/saxon9he.jar $TEST_PLAN lib/test-generator.xsl date-time="$CUR_DATETIME")


TEST_DIR=$(dirname $GEN_TEST_PLAN)


#Use datetime to find real log location for tsung, MUST BE IN FORMAT YYYYMMDD-HHMM

LOG_DIR="$SCRIPT_DIR/logs/";

mkdir -p $LOG_DIR;

DTD_LOCATION="$SCRIPT_DIR/lib/tsung-1.0.dtd";

sed -i "1i<!DOCTYPE tsung SYSTEM \"$DTD_LOCATION\">" $GEN_TEST_PLAN;

log_exist_status()
{
	S_LOG=$1;
	echo $(wget -T 100 -t 1 "$JMXURL" -O $S_LOG -o /dev/stdout )
}

TSUNG_LOG_ACTUALLY="$LOG_DIR/$CUR_DATETIME";
STATUS_LOG="$TSUNG_LOG_ACTUALLY/exist_status.xml";

monitor_exist()
{
	result=""
	sleep 5;
	
	#echo -e "\nLogging eXist status to: $STATUS_LOG\n";
	
	while [ "$(tsung status | grep 'not started')" = "" ];
	do
	result=$(log_exist_status $STATUS_LOG)
	
	
	if [ "$(echo $result | grep '200 OK' )" = "" ] 
	then
	
		echo -e "WARNING: Could not retireve eXist JMX status at: $JMXURL.\nSystem may be unresponsive.";
	fi
	
	sleep 2
	done
}

TEST_PLAN_DATA=$(cat $GEN_TEST_PLAN)

if [ "$WRITE_TEST_PLAN" != "" ] 
then
	echo -e "\nWriting test plan to $WRITE_TEST_PLAN. Not running any tests\n\n";
	echo $TEST_PLAN_DATA > $WRITE_TEST_PLAN;
	exit
fi



monitor_exist &

CUR_DIR=$(pwd);


cd $TEST_DIR;

tsung -f "$GEN_TEST_PLAN" -l "$LOG_DIR" -w 0 start 


on_exit()
{
	
	test_cleanup
	tsung stop > /dev/null
	log_exist_status $STATUS_LOG > /dev/null
	# Need to exit the script explicitly when done.
	# Otherwise the script would live on, until system
	# realy goes down, and KILL signals are send.
	#
	exit 0
}

trap 'on_exit' INT TERM EXIT
