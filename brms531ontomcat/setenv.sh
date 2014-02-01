#!/bin/sh

JAVA_OPTS="-Xms512m -Xmx1303m -XX:MaxPermSize=256m"

CATALINA_OPTS="-Dbtm.root=$CATALINA_HOME -Dbitronix.tm.configuration=$CATALINA_HOME/conf/btm-config.properties"
CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=8999 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
