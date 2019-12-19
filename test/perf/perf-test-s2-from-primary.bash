#!/usr/bin/env bash

cd "$(dirname "$0")"
PLUGIN_PATH=/usr/lib64/nagios/plugins
NYTPROF_OPT='perl -d:NYTProf'
RESULTS_DIR='nytprof'
START_SCRIPT_TIME=`date +%s`

# PARAMETERS
LOOP_NB=10
WAL_GENERATED_PER_LOOP=20
SECONDS_TO_WAIT_AFTER_LOOP=3
echo "LOOP_NB = $LOOP_NB"
echo "WAL_GENERATED_PER_LOOP = $WAL_GENERATED_PER_LOOP"
echo "SECONDS_TO_WAIT_AFTER_LOOP = $SECONDS_TO_WAIT_AFTER_LOOP"

if [ ! -d $RESULTS_DIR ]; then
    mkdir $RESULTS_DIR
else
	rm -rf $RESULTS_DIR
	mkdir $RESULTS_DIR
fi

echo "Initiate backup full"
sudo -iu postgres ssh backup-srv "pgbackrest --stanza=my_stanza backup --type=full --repo1-retention-full=1"

LOOPS=($(seq 1 1 $LOOP_NB))
FIRST_VALUE=${LOOPS[0]}
LAST_VALUE=${LOOPS[-1]}
for i in "${LOOPS[@]}"
do

	echo "Run ... $i / $LOOP_NB"
	echo -n "\__ generate $WAL_GENERATED_PER_LOOP wal archives"
	START_TIME=`date +%s`
	sudo -u postgres psql -f wal_gen.sql --set=my_loop_nb=$WAL_GENERATED_PER_LOOP > /dev/null 2>&1
	echo " ... took "$((`date +%s` - $START_TIME))"s"

	echo -n "\__ --service=retention --retention-full"
	export NYTPROF=file=$RESULTS_DIR/nytprof.out.1
	START_TIME=`date +%s`
	$NYTPROF_OPT $PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-full=1 >/dev/null 2>&1
	echo " ... took "$((`date +%s` - $START_TIME))"s"
	if [ -e $RESULTS_DIR/nytprof.out.1 ] && ([ $i -eq $FIRST_VALUE ] || [ $i -eq $LAST_VALUE ]); then
		nytprofhtml --file $RESULTS_DIR/nytprof.out.1 --delete --out $RESULTS_DIR/nytprofhtml.$i.1 >/dev/null 2>&1
	fi

	echo -n "\__ --service=archives --repo-path"
	export NYTPROF=file=$RESULTS_DIR/nytprof.out.2
	START_TIME=`date +%s`
	$NYTPROF_OPT $PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=archives --repo-path=/var/lib/pgbackrest/archive --repo-host="backup-srv" --repo-host-user=postgres >/dev/null 2>&1
	echo " ... took "$((`date +%s` - $START_TIME))"s"
	if [ -e $RESULTS_DIR/nytprof.out.2 ] && ([ $i -eq $FIRST_VALUE ] || [ $i -eq $LAST_VALUE ]); then
		nytprofhtml --file $RESULTS_DIR/nytprof.out.2 --delete --out $RESULTS_DIR/nytprofhtml.$i.2 >/dev/null 2>&1
	fi

	rm -rf $RESULTS_DIR/nytprof.out.*
	echo "\__ wait $SECONDS_TO_WAIT_AFTER_LOOP seconds"
	sudo -iu postgres psql -c "SELECT pg_sleep($SECONDS_TO_WAIT_AFTER_LOOP);" > /dev/null 2>&1

done

echo "----------------------------------------------------"
echo "END - took "$((`date +%s` - $START_SCRIPT_TIME))"s"