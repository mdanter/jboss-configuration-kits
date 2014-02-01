#!/bin/sh

setProperty() {
	pname=$1
	pvalue=$2
	filename=$3
	sed -i '' "s|\(.*$pname=\).*\($\)|\1$pvalue\2|g" $filename
}

setElement() {
	elemname=$1
	value=$2
	filename=$3
	sed -i '' "s|\(<$elemname>\).*\(</$elemname>\)|\1$value\2|g" $filename
}

replaceToken() {
	token=$1
	value=$2
	filename=$3
	sed -i '' "s|$token|$value|g" $filename
}

setAttribute() {
	pattern=$1
	field=$2
	value=$3
	filename=$4
	sed -i '' "s|\($pattern.*$field=\"\)[^\"]*\(\"\)|\1$value\2|g" $filename
}

addLineAfter() {
	#echo "pattern: '$1', output: '$2', filename: '$3'"
	pattern=$1
	output=$2
	filename=$3
	awk -v "inject=$output" "/$pattern/{print;print inject;next}1" $filename > $filename.tmp
	cloneFilePermissions $filename $filename.tmp
	mv -f $filename.tmp $filename
}

cloneFilePermissions() {
	chmod --reference="$1" "$2.tmp"
	#chmod `stat -f %A $filename` $filename.tmp  # OSX	
}


cp -p ./catalina.sh.orig ./catalina.sh
OPTS='JAVA_OPTS="$JAVA_OPTS -Djava.security.auth.login.config=$CATALINA_BASE/conf/jaas.config"'
addLineAfter "Execute The Requested Command" "$OPTS" ./catalina.sh
cat ./catalina.sh

exit

cp jbpm.xml.orig jbpm.xml
OPTS='JAVA_OPTS="$JAVA_OPTS -Djava.security.auth.login.config=$CATALINA_BASE/conf/jaas.config"'
addLineAfter "ORYX.Plugins.Theme" "$OPTS" ./jbpm.xml 
cat jbpm.xml  

exit

cp resources.properties.orig resources.properties
setProperty resource.ds1.driverProperties.user TEST ./resources.properties
cat resources.properties

cp persistence.xml.orig persistence.xml
setElement "non-jta-data-source" "java:/brmsDS" ./persistence.xml 
cat persistence.xml

replaceToken "jboss" "REPLACEDTOKEN" ./resources.properties
cat resources.properties
  
setAttribute "externalloadurl" "usr" "BLAHUSER" ./jbpm.xml
setAttribute "" "pwd" "MYPASSWORD" ./jbpm.xml
cat jbpm.xml


