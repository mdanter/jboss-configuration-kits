#!/bin/sh

# Installs BRMS 5.3.1 on top of Tomcat 6 and 7 (JBoss EWS 2.0)
# Manual Directions:  
#     https://access.redhat.com/site/documentation/en-US/JBoss_Enterprise_BRMS_Platform/5/html-single/BRMS_Getting_Started_Guide/index.html#Installing_the_Deployable_Package1
#     https://access.redhat.com/site/solutions/218013
#     https://access.redhat.com/site/solutions/284443
#     https://community.jboss.org/people/bpmn2user/blog/2011/01/21/test

# Assumes the following two packages are downloaded next to the script
# 1) brms-p-5.3.1.GA-deployable.zip
# 2) brms-p-5.3.1.GA-standalone.zip
# 3) jboss-ews-application-servers-2.0.1-1-RHEL6-x86_64.zip
# 4) btm-dist-2.1.4.zip

# Wishlist:
# 1) Find critical patches for BRMS 5.3.1 and apply (if any are critical)
# 2) Generate DDL and Zero-Day Data for Database using hibernate libraries
# 3) Prompt for configuration settings instead of using variables
# 4) Deploy on community Tomcat 6 and 7
# 5) Get drivers for and test agaist all major databases
# 6) Configure JMS for BPM engine instead of using Mina
# 7) Configure JAAS for LDAP based auth

#Error1
#java.lang.IllegalArgumentException: No PolicyContextHandler for key=javax.security.auth.Subject.container
#	at javax.security.jacc.PolicyContext.getContext(PolicyContext.java:107)
#	at org.jbpm.integration.console.TaskManagement.getCallerRoles(TaskManagement.java:185)
#	at org.jbpm.integration.console.TaskManagement.getUnassignedTasks(TaskManagement.java:159)
#	at org.jboss.bpm.console.server.TaskListFacade.getTasksForIdRefParticipation(TaskListFacade.java:113)


# Configuration Settings
DBHOST=localhost
DBNAME=brms
DBUSER=brmsuser
DBPASS=jboss
ADMINUSR=jowest
ADMINPWD=jboss

# Build settings

BUILDDIR=./brmsontomcat
TC6=$BUILDDIR/tomcat6
TC7=$BUILDDIR/tomcat7
SRCDIR=.
STAGEDIR=./staging

# Utility Functions

reportstep() {
  echo 
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo "         $1" 
  echo 
}

runsed() {
	sed -i "$1" "$2"	# Linux
	#sed -i '' "$1" "$2"	# OSX
}

cloneFilePermissions() {
	chmod --reference="$1" "$2"		     # Linux
	#chmod `stat -f %A $filename` $filename.tmp  # OSX	
}

setProperty() {
	pname=$1
	pvalue=$2
	filename=$3
	echo "setProperty pname='$pname', pvalue='$pvalue', filename='$filename'"
	runsed "s|\(.*$pname=\).*\($\)|\1$pvalue\2|g" $filename
}

addLineAfter() {
	pattern=$1
	output=$2
	filename=$3
	echo "addLineAfter pattern='$pattern', output='$output', filename='$filename'"
	awk -v "inject=$output" "/$pattern/{print;print inject;next}1" $filename > $filename.tmp
	cloneFilePermissions $filename $filename.tmp
	mv -f $filename.tmp $filename
}

setElement() {
	elemname=$1
	value=$2
	filename=$3
	echo "setElement elemname='$elemname', value='$value', filename='$filename'"	
	runsed "s|\(<$elemname>\).*\(</$elemname>\)|\1$value\2|g" $filename
}

replaceToken() {
	token=$1
	value=$2
	filename=$3
	echo "replaceToken token='$token', value='$value', filename='$filename'"
	runsed "s|$token|$value|g" $filename
}

setAttribute() {
	pattern=$1
	field=$2
	value=$3
	filename=$4
	echo "setAttribute pattern='$pattern', field='$field', value='$value', filename='$filename'"
	runsed "s|\($pattern.*$field=\"\)[^\"]*\(\"\)|\1$value\2|g" $filename
}


# BRMS Install Functions

clearBuild() {
  reportstep "Cleaning previous installation files"
  rm -rf $BUILDDIR
  
  reportstep "Preparing installation directories"
  mkdir -vp $BUILDDIR
  mkdir -vp $STAGEDIR
}

cleanup() {
  reportstep "Cleaning up unpacked archive directories"
  rm -rf $STAGEDIR
}

unarchivetomcat() {
  reportstep "Installing EWS / Tomcat"
  unzip -q $SRCDIR/jboss-ews-application-servers* -d $STAGEDIR
  cp -rp $STAGEDIR/jboss-ews-2.0/tomcat6 $BUILDDIR/
  cp -rp $STAGEDIR/jboss-ews-2.0/tomcat7 $BUILDDIR/
  cp -rp $STAGEDIR/jboss-ews-2.0/extras $BUILDDIR/
}

unarchivebrms() {
  reportstep "Unpacking BRMS 5.3.1"
  unzip -q $SRCDIR/brms-p*deployable.zip -d $STAGEDIR
  unzip -q $STAGEDIR/jboss-brms-manager.zip -d $STAGEDIR/jboss-brms-manager
  unzip -q $STAGEDIR/jboss-jbpm-console.zip -d $STAGEDIR/jboss-jbpm-console
  unzip -q $STAGEDIR/jboss-jbpm-engine.zip -d $STAGEDIR/jboss-jbpm-engine
  
  unzip -q $SRCDIR/brms-p*-standalone.zip -d $STAGEDIR
}

unarchivetxmgr() {
  reportstep "Unpacking Bitronix Transaction Manager"
  unzip -q $SRCDIR/btm*.zip -d $STAGEDIR
}

installBrmsOn() {
  reportstep "Installing BRMS 5.3.1 files onto Tomcat: $1"
  cp -rp $STAGEDIR/jboss-brms-manager/jboss-brms.war $1/webapps/jboss-brms
  cp -rp $STAGEDIR/jboss-jbpm-console/business-central-server.war $1/webapps/business-central-server
  cp -rp $STAGEDIR/jboss-jbpm-console/business-central.war $1/webapps/business-central
  cp -rp $STAGEDIR/jboss-jbpm-console/designer.war $1/webapps/designer
  cp -rp $STAGEDIR/jboss-jbpm-console/jbpm-human-task.war $1/webapps/jbpm-human-task 
  
  cp -vp $STAGEDIR/jboss-jbpm-engine/lib/netty.jar $1/lib/ 
  cp -vp $STAGEDIR/jboss-jbpm-engine/lib/antlr*.jar $1/lib/ 
  cp -vp $STAGEDIR/jboss-jbpm-engine/lib/commons-collections*.jar $1/lib/ 
  cp -vp $STAGEDIR/jboss-jbpm-engine/lib/dom4j*.jar $1/lib/
  cp -vp $STAGEDIR/jboss-jbpm-engine/lib/javassist*.jar $1/lib/ 
  cp -vp $STAGEDIR/jboss-jbpm-engine/lib/jta*.jar $1/lib/ 
  cp -vp $STAGEDIR/jboss-jbpm-engine/lib/hibernate*.jar $1/lib/ 
  cp -vp $STAGEDIR/jboss-jbpm-engine/lib/log4j*.jar $1/lib/ 
  cp -vp $STAGEDIR/jboss-jbpm-engine/lib/slf4j*.jar $1/lib/ 
  
  # Workaround for persistence signer info exceptions
  rm -v $1/lib/annotations-api.jar
  cp -vp $STAGEDIR/jboss-jbpm-console/business-central-server.war/WEB-INF/lib/jsr250-api-1.0.jar $1/lib/
  cp -vp $STAGEDIR/brms-standalone-5.3.1/jboss-as/lib/jboss-javaee.jar $1/lib/
}

installTxMgrOn() {
  reportstep "Installing transaction manager onto Tomcat: $1"
  cp -vp $STAGEDIR/btm-dist-2.1.4/btm-2.1.4.jar $1/lib/
  cp -vp $STAGEDIR/btm-dist-2.1.4/integration/btm-tomcat55-lifecycle-2.1.4.jar $1/lib/
  cp -vp $SRCDIR/log4j.properties $1/lib/
  #addLineAfter "limitations under the License" "log4j.rootLogger=debug,A1" $1/conf/logging.properties
}

configureSecurityOn() {
  reportstep "Configuring security on Tomcat: $1"
  cp -pf $STAGEDIR/brms-standalone-5.3.1/jboss-as/lib/jbosssx.jar $1/lib/
  cp -pf $STAGEDIR/brms-standalone-5.3.1/jboss-as/client/jboss-logging-spi.jar $1/lib/
  cp -pf $SRCDIR/jaas.config $1/conf/
  cp -pf $SRCDIR/tomcat-users.xml $1/conf/
  cp -pf $SRCDIR/users.properties $1/lib/
  cp -pf $SRCDIR/roles.properties $1/lib/  
  cp -p $1/bin/catalina.sh $1/bin/catalina.sh.orig
  OPTS='JAVA_OPTS="$JAVA_OPTS -Djava.security.auth.login.config=$CATALINA_BASE/conf/jaas.config"'
  addLineAfter "Execute The Requested Command" "$OPTS" $1/bin/catalina.sh
  
  # Enable human tasks
  mkdir -p $1/webapps/jbpm-human-task/WEB-INF/classes/org/jbpm/task/service
  cp -vp $SRCDIR/jbpm.usergroup.callback.properties $1/webapps/jbpm-human-task/WEB-INF/classes/org/jbpm/task/service/
}

configureTaskService() {
  reportstep "Configuring task service endpoint with Mina protocol on Tomcat: $1"
  
  # JBPM Server (task client)
  cp -p $SRCDIR/jbpm.console.properties $1/webapps/business-central-server/WEB-INF/classes/

  # Task Server  
  cp -p $SRCDIR/taskweb.xml $1/webapps/jbpm-human-task/WEB-INF/web.xml 
}

configureAdminCreds() {
  reportstep "Setting administrator credentials on $1, user: $2, pass: *****"
  setProperty "guvnor.usr" "$2" $1/webapps/business-central-server/WEB-INF/classes/jbpm.console.properties
  setProperty "guvnor.pwd" "$3" $1/webapps/business-central-server/WEB-INF/classes/jbpm.console.properties
  
  setAttribute "externalloadurl" "usr" "$2" $1/webapps/designer/profiles/jbpm.xml
  setAttribute "externalloadurl" "pwd" "$3" $1/webapps/designer/profiles/jbpm.xml
  
  addLineAfter "admin" "$2=JBossAdmin,httpInvoker,user,admin" $1/lib/roles.properties
  addLineAfter "admin" "$2=$3" $1/lib/users.properties
  addLineAfter "user username" "<user username=\"$2\" password=\"$3\" roles=\"manager-gui,manager-script,manager-jmx,user\"/>" $1/conf/tomcat-users.xml
}

configureDatabase() {
  reportstep "Configuring database on Tomcat: $1, db: $2"
  TEMPLATEDIR=$STAGEDIR/jboss-brms-manager/jboss-brms.war/WEB-INF/classes/repoconfig
  case "$2" in
  "mysql")
  	configureDatasources $1 \
  		$SRCDIR/mysql-connector-java-5.1.26-bin.jar \
  		org.hibernate.dialect.MySQLDialect \
  		com.mysql.jdbc.jdbc2.optional.MysqlXADataSource \
  		$DBUSER $DBPASS "jdbc:mysql://${DBHOST}:3306/${DBNAME}" \
  		$TEMPLATEDIR/mysql-repository-jndi.xml;
    ;;
  "pgsql")
  	configureDatasources $1 \
  		$SRCDIR/TOGET \
  		org.hibernate.dialect.PostgreSQLDialect \
  		org.postgresql.Driver \
  		$DBUSER $DBPASS "jdbc:postgresql://${DBHOST}:5432/${DBNAME}" \
  		$TEMPLATEDIR/postgressql-repository-jndi.xml;
    ;;
  "oracle")
  	configureDatasources $1 \
  		$SRCDIR/TOGET \
  		org.hibernate.dialect.Oracle10gDialect \
  		oracle.jdbc.OracleDriver \
  		$DBUSER $DBPASS "jdbc:oracle:thin:@${DBHOST}:1521:${DBNAME}" \
  		$TEMPLATEDIR/oracle11-repository-jndi.xml;
    ;;
  #"db2")
  	#configureDatasources $1 \
  	#	$SRCDIR/TOGET \
  	#	org.hibernate.dialect.DB2Dialect \
  	#	com.ibm.db2.jcc.DB2Driver \
  	#	$DBUSER $DBPASS "jdbc:db2://${DBHOST}:5000/${DBNAME}" \
  	# DB2 template doesn't exist, must use generic one 	
    #;; 
  *)
    echo "Database type $2 must added to script or be configured manually"
    ;;
  esac
}

configureDatasources() {
  # $1  tomcat path
  # $2  jdbc driver path
  # $3  dialect class (eg: org.hibernate.dialect.MySQLDialect)
  # $4  jdbc datasource class (eg: com.mysql.jdbc.jdbc2.optional.MysqlXADataSource)
  # $5  DB username
  # $6  DB password
  # $7  DB url
  # $8  BRMS repository template
  echo "Tomcat Path: $1, JDBCDriver: $2, Dialect: $3, Driver: $4, DBUser: $5, DBPass: ***, DBUrl: $7, RepoTemplate: $8"

  # Install JDBC driver, Bitronix, and supplemental configurations
  cp $2 $1/lib/									# JDBC Driver
  cp $SRCDIR/setenv.sh $1/bin/					# Bitronix bootstrap
  cp $SRCDIR/btm-config.properties $1/conf/		# Bitronix TX configuration
  cp $SRCDIR/resources.properties $1/conf/		# Database connections

  # Add BTM handler to server.xml
  addLineAfter "GlobalResourcesLifecycleListener" '<Listener className="bitronix.tm.integration.tomcat55.BTMLifecycleListener" />' $1/conf/server.xml
  
  # Add datasources to context.xml
  addLineAfter "WatchedResource" '<Resource name="jdbc/jbpmTasksDS" auth="Container" type="javax.sql.DataSource" factory="bitronix.tm.resource.ResourceObjectFactory" uniqueName="jdbc/jbpmTasksDS"/>' $1/conf/context.xml
  addLineAfter "WatchedResource" '<Resource name="jdbc/jbpmDS" auth="Container" type="javax.sql.DataSource" factory="bitronix.tm.resource.ResourceObjectFactory" uniqueName="jdbc/jbpmDS"/>' $1/conf/context.xml
  addLineAfter "WatchedResource" '<Resource name="jdbc/brmsDS" auth="Container" type="javax.sql.DataSource" factory="bitronix.tm.resource.ResourceObjectFactory" uniqueName="jdbc/brmsDS"/>' $1/conf/context.xml
  addLineAfter "WatchedResource" '<Transaction factory="bitronix.tm.BitronixUserTransactionObjectFactory" />' $1/conf/context.xml
  
  # Configure all three datasources at once
  # Share a single database schema
  setProperty ".className" "$4" $1/conf/resources.properties  
  setProperty ".driverProperties.user" "$5" $1/conf/resources.properties  
  setProperty ".driverProperties.password" "$6" $1/conf/resources.properties  
  setProperty ".driverProperties.URL" "$7" $1/conf/resources.properties  
  
  # Business Central Server Persistence
  setElement "jta-data-source" "java:/comp/env/jdbc/jbpmDS" $1/webapps/business-central-server/WEB-INF/classes/META-INF/persistence.xml
  setAttribute "hibernate.dialect" "value" "$3" $1/webapps/business-central-server/WEB-INF/classes/META-INF/persistence.xml
  setAttribute "hibernate.transaction.manager_lookup_class" "value" "org.hibernate.transaction.BTMTransactionManagerLookup" $1/webapps/business-central-server/WEB-INF/classes/META-INF/persistence.xml
  
  # Task Server Persistence
  setElement "non-jta-data-source" "java:/comp/env/jdbc/jbpmTasksDS" $1/webapps/jbpm-human-task/WEB-INF/classes/META-INF/persistence.xml
  setAttribute "hibernate.dialect" "value" "$3" $1/webapps/jbpm-human-task/WEB-INF/classes/META-INF/persistence.xml
  setAttribute "hibernate.transaction.manager_lookup_class" "value" "org.hibernate.transaction.BTMTransactionManagerLookup" $1/webapps/jbpm-human-task/WEB-INF/classes/META-INF/persistence.xml
  
  # Install BRMS repository template
  cp $8 $1/repository.xml
  replaceToken "</#noparse>" "" $1/repository.xml
  replaceToken "<#noparse>" "" $1/repository.xml
  setAttribute "url" "value" "java:comp/env/jdbc/brmsDS" $1/repository.xml
}

installOn() {
  installBrmsOn $1
  installTxMgrOn $1
  configureSecurityOn $1
  configureTaskService $1
  configureAdminCreds $1 brmsadmin secret
  configureDatabase $1 mysql
}

cleanup
clearBuild

unarchivetomcat
unarchivebrms
unarchivetxmgr
installOn $BUILDDIR/tomcat6
installOn $BUILDDIR/tomcat7
#cleanup

