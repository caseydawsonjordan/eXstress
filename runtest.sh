#! /bin/sh

USAGE="Usage: `basename $0` [-hutidD] test-plan"

on_die()
{
	# print message
	#
	echo "Aborting..."
	tsung stop
	# Need to exit the script explicitly when done.
	# Otherwise the script would live on, until system
	# realy goes down, and KILL signals are send.
	#
	exit 0
}



NUM_USERS=""; 		# Total number of users to simulate
TEST_TIME=""; 		# Time in seconds
DELAY="";		   		# Number of seconds between users ariving
INTERVAL="";		    # Interval in between each request in seconds
DUMP_TRAFFIC="false"
EXIST_SERVER="localhost";
EXIST_PORT="8080";

# Parse command line options.
while getopts hu:t:i:d:D OPT; do
    case "$OPT" in
        h)
            echo -n "$USAGE\n"
           	echo -n "	[Options] - Options modify the default test plan behavior\n";
           	echo -n "\n\n";
           	echo -n "	-n	max_users (Force max number of simulated users)\n";
           	echo -n "	-t	test_time (Force max test run time)\n";
           	echo -n "	-d	request_delay (Force delay between requests)\n";
           	echo -n "	-i	users_interval (Force interval between user arrival in seconds)\n";
           	echo -n "	-D (Dump all traffic to tsung.dump)\n";
           	#echo -n "	-G (Automatically generate report after completion and launch in firefox)\n";
            exit 0
            ;;
        u)
            NUM_USERS=$OPTARG
            ;;
          
        t)
            TEST_TIME=$OPTARG
            ;;
        i)
            INTERVAL=$OPTARG
            ;;
        d)
           
            	DELAY=$OPTARG
            ;;
          D)
           
            	DUMP_TRAFFIC="true"
            ;;
        \?)
            # getopts issues an error message
            echo $USAGE >&2
            exit 1
            ;;
    esac
done

# Remove the switches we parsed above.
shift `expr $OPTIND - 1`

#echo -n "\n";
#echo -n "NUM_USERS:$NUM_USERS\n";
#echo -n "TEST_TIME:$TEST_TIME\n";
#echo -n "DELAY:$DELAY\n";
#echo -n "INTERVAL:$INTERVAL\n";
#echo -n "TEST-PLAN:$1\n\n";

TEST_PLAN=$1;
TEST_PLAN_FILENAME=$(basename $TEST_PLAN)
TEST_DIR=$(dirname $TEST_PLAN)
GEN_TEST_PLAN_NAME="generated-test-plan.xml"
GEN_TEST_PLAN=$( readlink -f "$( dirname "$TEST_DIR/$GEN_TEST_PLAN_NAME" )" )/$( basename "$TEST_DIR/$GEN_TEST_PLAN_NAME" )
echo $GEN_TEST_PLAN;

# Generate the test plan
java  -jar ./lib/saxon/saxon9he.jar -o:"$GEN_TEST_PLAN" $1 lib/test-generator.xsl max_users="$NUM_USERS" test_time="$TEST_TIME" request_delay="$DELAY" interval="$INTERVAL"  dump_traffic="$DUMP_TRAFFIC"

#Use datetime to find real log location for tsung, MUST BE IN FORMAT YYYYMMDD-HHMM
CUR_DATETIME=$(date '+%Y%m%d-%H%M')
LOG_DIR_REL="./logs/$TEST_PLAN_FILENAME";
LOG_DIR=$( readlink -f $( dirname $LOG_DIR_REL ))
REL_DTD_LOCATION="./lib/tsung-1.0.dtd";

DTD_LOCATION=$( readlink -f "$( dirname "$REL_DTD_LOCATION" )" )/$( basename "$REL_DTD_LOCATION" );

sed -i "1i<!DOCTYPE tsung SYSTEM \"$DTD_LOCATION\">" $GEN_TEST_PLAN;

if [ ! -d $LOG_DIR ] 
then 	
	mkdir $LOG_DIR;	
fi 

TSUNG_LOG_ACTUALLY="$LOG_DIR/$CUR_DATETIME";

log_exist_status()
{
	echo $(wget -T 100 -t 1 localhost:8080/exist/status?c=locking -O $STATUS_LOG -o /dev/stdout )
}

monitor_exist()
{
	result=""
	sleep 5;
	STATUS_LOG="$TSUNG_LOG_ACTUALLY/exist_status.xml";
	#echo -e "\nLogging eXist status to: $STATUS_LOG\n";
	
	while [ "$(tsung status | grep 'not started')" = "" ];
	do
	result=$(log_exist_status)
	
	
	if [ "$(echo $result | grep '200 OK' )" = "" ] 
	then
	
		echo "WARNING: Could not retireve eXist JMX status. System may be unresponsive.";
	fi
	
	sleep 2
	done
}

trap 'on_die' TERM

monitor_exist &

CUR_DIR=$(pwd);

cd $TEST_DIR;

tsung -f $GEN_TEST_PLAN -l $LOG_DIR -w 0 start &

wait

log_exist_status

cd $CUR_DIR;

rm $GEN_TEST_PLAN;
