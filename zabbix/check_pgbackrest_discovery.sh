A=`echo '- pgbackrest_stanza { "data" : ['`
B=`pgbackrest info | grep -i stanza: | awk '{print "{ \"{#STANZA}\":\"" $2 "\"},"}'`
C=`echo "}]}"`
echo $A$B$C
