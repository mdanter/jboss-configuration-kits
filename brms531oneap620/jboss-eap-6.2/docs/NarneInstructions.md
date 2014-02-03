

JBoss BRMS 5.3.1 on JBoss EAP 6.2.0GA
=====================================


This document describes the configuration of JBoss BRMS 5.3.1 on top of EAP 6.2.0:
+ Configures Oracle as a datasource for the BRMS content repository, and JBPM operational tables
+ Supplies SQL scripts to generate the necessary tables 
+ Documents how to configure BRMS for authorization, and how to use LDAP for for authentication. 

## Installation Steps

+ Download the kit archive http://people.redhat.com/jowest/brms531oneap620/brms531oneap620.zip

+ Unzip archive `brms531oneap620.zip` to installation location

+ Execute Oracle DDL scripts for the BRMS repository and JBPM operational tables

 These scripts generate the brms and jbpm database users, tables, sequences, triggers, etc against two separate schemas named `brms` and `jbpm`. 

 The default credentials are set to the username equal to the password. The preconfigured jboss datasources match. It is expected that you will modify these credentials as necessary, and update the corresponding datasource configuration in `jboss-eap-6.2/standalone/configuration/standalone.xml` file.

 Day zero data is not set these DDLs. The first time the server starts it will generate the necessary data.
 ```
 jboss-eap-6.2/docs/sql/BRMSOracleDDL.sql
 jboss-eap-6.2/docs/sql/JBPMOracleDDL.sql
 ```

+ Update JBoss datasource connection details

 In `jboss-eap-6.2/standalone/configuration/standalone.xml` go to the datasources modules section and edit the brmsDS and jbpmDS connection string for you database host / SID, and credentials if you have modified them from the defaults in the DDL.  

+ Start the server `bin/standalone.[sh|bat] -b 0.0.0.0 -bmanagement 0.0.0.0`

+ Import your repository through Administration > Import Export

+ Login using the admin credentials: `admin` password `getredhat1!`

+ Import your repository through Administration > Import Export.

+ Enable authorization by editing `jboss-eap-6.2/standalone/deployments/jboss-brms.war/WEB-INF/components.xml` and setting the `enableRoleBasedAuthorization` propert to 'true'.

 *NOTE* If starting from scratch, you need at least one admin BRMS user prior to enabling authoriation otherwise you will get '401/403 errors, and not be able to log in to access the permissions administration. 

 ```
 <component name="org.jboss.seam.security.roleBasedPermissionResolver">
    <property name="enableRoleBasedAuthorization">true</property>
 </component>
 ```

+ Restart the server

 Verify logins, and authorization enforcement.

+ Configure LDAP

 BRMS requires access to itself through a username and password. This has bee configured in the following two files to use the credentials `admin/getredhat1!`. When configuring BRMS for LDAP ensure that there is a user with these credentials, or use JAAS login-module chaining for the `brms` realm. When the credentials are changed you must also edit the following two files otherwise the BPM designer will error out, and the BPM central console will not function.
 ```
 jboss-eap-6.2/standalone/deployments/designer.war/profiles/jbpm.xml
 jboss-eap-6.2/stadnalone/deployments/business-central-server.war/WEB-INF/classes/jbpm.console.properties
 ```

 *NOTE* Since these credentials are posted on the web, it is recommended that all passwords are changed for defaults before putting them into QA or Production environments.

 Refer to the JBoss EAP 6.2 administration guide for configuring LDAP: see section [Security Administration Reference](https://access.redhat.com/site/documentation/en-US/JBoss_Enterprise_Application_Platform/6.2/html-single/Administration_and_Configuration_Guide/index.html#chap-Security_Administration_Reference)

 Stop of the server to edit the standalone.xml file - alternatively edit the server configuration with the CLI or [EAP Administration Console http://localhost:9990/console/App.html](http://localhost:9990/console/App.html) while keeping the server alive. Edit the `<subsystem xmlns="urn:jboss:domain:security:1.2">` section. Keep the UsersRoles login-module to at least the `admin` user, which is used by Guvnor. Change the flag attribute to `optional` so that the file user/password can be used *OR* LDAP.

 Add the LDAP login modules to the security domain as shown in the clip below. Modify the login-module as necessary for your environment, refering to the reference documentation above for additional refernce. The clip below assumes that users have the prefix `uid` and users can be queried anonymously.

 ```xml
 <security-domain name="brms" cache-type="default">
    <authentication>
        <login-module code="UsersRoles" flag="optional">
            <module-option name="usersProperties" value="${jboss.server.config.dir}/brms-users.properties"/>
            <module-option name="rolesProperties" value="${jboss.server.config.dir}/brms-roles.properties"/>
        </login-module>
        <login-module code="org.jboss.security.auth.spi.LdapLoginModule" flag="optional">
            <module-option name="java.naming.factory.initial" value="com.sun.jndi.ldap.LdapCtxFactory"/>
            <module-option name="java.naming.provider.url" value="ldap://adama.shuawest.net:389"/>
            <module-option name="java.naming.security.authentication" value="none"/>
            <module-option name="principalDNPrefix" value="uid"/>
        </login-module>
    </authentication>
 </security-domain>
 ```

 Remove any logins from the `jboss-eap-6.2/standalone/configuration/brms-users.properties` file that are now coming from the LDAP server.

+ Restart and verify 

## Remaining Issues

+ Building your packages throw an error message stating regarding the pojo jars. A ticket should be opened to resolve this problem.

 It may be worth while to try uploading a new version of the Model JARs to the BRM and attempting to build the package again.

 ```
 Can not build the package. One or more of the classes that are needed were compiled with an unsupported Java version.,
 For example the pojo classes were compiled with Java 1.6 and Guvnor is running on Java 1.5.
 ```

## Reference Material

+ [Red Hat Customer Portal](http://access.redhat.com)
 
 With a subscription or current eval you can open support tickets, download packages, and search the knowledge base. 

+ [Red Hat Documentation](http://docs.redhat.com)
 
 Documentation is accessible without a login.

  + Refer to the EAP 6.2 documentation for configuring LDAP and Datasources
  + Refer to the JBoss Enterprise BRMS documentation for configuring BRMS

+ [Middleware Administration Training Curriculum](https://www.redhat.com/training/paths/jboss-middleware-1.html) & [Middleware Development Training Curriculum](https://www.redhat.com/training/paths/jboss-middleware-2.html)
  There are training courses for JBoss EAP administration, BRMS development, which may be of interest.


## Kit Preconfiguration Log

### Changed JPA configuration to use Oracle dialect

Updated the persistence.xml files to use the `org.hibernate.dialect.Oracle10gDialect` for Oracle 11g. 

### Added Oracle Datasources

Two Oracle datasources were configured to point to a brms database and a jbpm database.

If JBPM is not being used then the datasource can be removed along with the all of the JBPM war files in `jboss-eap-6.2/standalone/deployments/`: business-central-server.war, business-central.war, and jbpm-human-task.war.

NOTE: These configuration were only made to `standalone.xml`.  If other profiles are used this configuration must be replicated.

+ Added the Oracle driver `ojdbc6.jar` and the module.xml to `jboss-eap-6.2/modules/system/layers/base/oracle/main`.

```
<driver name="oracle" module="oracle">
    <driver-class>oracle.jdbc.driver.OracleDriver</driver-class>
    <xa-datasource-class>oracle.jdbc.xa.client.OracleXADataSource</xa-datasource-class>
</driver>
```

+ Added the `java:jboss/datasources/brmsDS` datasource

```
<datasource jndi-name="java:jboss/datasources/brmsDS" pool-name="brmsDS" enabled="true" use-java-context="true" spy="true">
	<connection-url>jdbc:oracle:thin:@baltar.shuawest.net:1521:XE</connection-url>
        <driver>oracle</driver>
        <security>
        	<user-name>brms</user-name>
        	<password>brms</password>
        </security>
        <validation>
		<valid-connection-checker class-name="org.jboss.jca.adapters.jdbc.extensions.oracle.OracleValidConnectionChecker"></valid-connection-checker>
		<stale-connection-checker class-name="org.jboss.jca.adapters.jdbc.extensions.oracle.OracleStaleConnectionChecker"></stale-connection-checker>
		<exception-sorter class-name="org.jboss.jca.adapters.jdbc.extensions.oracle.OracleExceptionSorter"></exception-sorter>
        </validation>
</datasource>
```

+ Added the `java:jboss/datasources/jbpmDS` datasource

```
<xa-datasource jndi-name="java:jboss/datasources/jbpmDS" pool-name="XAOracleDS" spy="true">
	<driver>oracle</driver>
	<xa-datasource-property name="URL">jdbc:oracle:thin:@baltar.shuawest.net:1521:XE</xa-datasource-property>
	<security>
		<user-name>jbpm</user-name>
		<password>jbpm</password>
	</security>
	<xa-pool>
		<is-same-rm-override>false</is-same-rm-override>
		<no-tx-separate-pools />
	</xa-pool>
	<validation>
		<valid-connection-checker class-name="org.jboss.jca.adapters.jdbc.extensions.oracle.OracleValidConnectionChecker"></valid-connection-checker>
		<stale-connection-checker class-name="org.jboss.jca.adapters.jdbc.extensions.oracle.OracleStaleConnectionChecker"></stale-connection-checker>
		<exception-sorter class-name="org.jboss.jca.adapters.jdbc.extensions.oracle.OracleExceptionSorter"></exception-sorter>
	</validation>
</xa-datasource>
```

### Configured JDBC Spy logger 

To verify no DDLs are created on startup, a JDBC log category was created with trace level logging.

NOTE: These configuration were only made to `standalone.xml`.  If other profiles are used this configuration must be replicated.

+ Added a file logger for JDBC activity

```
<periodic-rotating-file-handler name="JDBCLOG" autoflush="true">
    <level name="TRACE"/>
    <formatter>
        <pattern-formatter pattern="%d{HH:mm:ss,SSS} %-5p [%c] (%t) %s%E%n"/>
    </formatter>
    <file relative-to="jboss.server.log.dir" path="jdbc.log"/>
    <suffix value=".yyyy-MM-dd"/>
    <append value="true"/>
</periodic-rotating-file-handler>
```

+ Added spy category

```
<logger category="jboss.jdbc.spy">
    <level name="TRACE"/>
    <handlers>
        <handler name="JDBCLOG"/>
    </handler>
</logger>
```

### Set the BRMS JCR jackrabbit repository base directory

By default the jackrabbit repository will look for a repository.xml, or generate one, in the current working directory that you started BRMS from. If BRMS is not consistently started from the same directory the repository can appear be wiped out. The each fix for this is to set the `org.apache.jackrabbit.repository.home` java property. The preferrable location to set it to the jboss profile's directory. If there are multiple profiles on a single server each can have it's own configuration and repository. For the default profile this is `jboss-eap-6.2/standalone/` or the $JBOSS_BASE_DIR environment variable. 

+ Edited `jboss-eap-6.2/bin/standalone.sh` inserting the following just before the environment variables are printed.

```
# Set the Jackrabbit repository path
JAVA_OPTS="$JAVA_OPTS -Dorg.apache.jackrabbit.repository.conf=$JBOSS_BASE_DIR/repository.xml -Dorg.apache.jackrabbit.repository.home=$JBOSS_BASE_DIR"
```

+ Edited `jboss-eap-6.2/bin/standalone.bat` inserting the following just before the environment variables are printed.

```
rem Set the Jackrabbit repository path
set "JAVA_OPTS=%JAVA_OPTS% -Dorg.apache.jackrabbit.repository.conf=%JBOSS_BASE_DIR%\repository.xml -Dorg.apache.jackrabbit.repository.home=%JBOSS_BASE_DIR%"
```

### Created a Oracle Jackrabbit Repository Configuration 

Created a Oracle Jackrabbit Repository Configuration for an Oracle JNDI provided Datasource by:
+ Log into BRMS and going to Administation > Repository Configuration.
+ Select RDBMS type: Oracle 10g
+ Check 'Use JNDI'
+ Continue
+ Specify JDNI address `java:jboss/datasources/brmsDS`
+ Generate configuration
+ Copy the results into file `jboss-eap-6.2/standalone/repository.xml[.oracle]`.

### Generated Oracle 11g DDLs

Started BRMS after configuring it to use Oracle datasources. Generated DDLs using [Oracle SQL Developer](http://www.oracle.com/technetwork/developer-tools/sql-developer/downloads/index.html). 







