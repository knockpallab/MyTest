echo "$1"
echo $SOFTWARE_HOME
export SOFTWARE_HOME_REMOTE=$SOFTWARE_HOME
export CONF_B1_CUSTOM=$CPHOME/conf_b1.properties
export APACHE_HOME=$SOFTWARE_HOME/apache
export TOMCAT_HOME=$SOFTWARE_HOME/tomcat
export JAVA_HOME=$SOFTWARE_HOME/jdk64_linux
export RUBY_LINUX_HOME=$SOFTWARE_HOME/ruby_linux
export MKS_HOME=$SOFTWARE_HOME/mks
export ANT_HOME=$SOFTWARE_HOME/ant
export VVM_HOME=$SOFTWARE_HOME/visualvm
export APACHE_HOME_REMOTE=$SOFTWARE_HOME_REMOTE/apache
export TOMCAT_HOME_REMOTE=$SOFTWARE_HOME_REMOTE/tomcat
export JAVA_HOME_REMOTE=$SOFTWARE_HOME_REMOTE/jdk
export RUBY_HOME_REMOTE=$SOFTWARE_HOME_REMOTE/ruby
export MKS_HOME_REMOTE=$SOFTWARE_HOME_REMOTE/mks
export ANT_HOME_REMOTE=$SOFTWARE_HOME_REMOTE/ant
export VVM_HOME_REMOTE=$SOFTWARE_HOME_REMOTE/visualvm
export PATH=$JAVA_HOME/bin:$PATH
echo CPHOME=$CPHOME
echo CPHOME_LOCAL=$CPHOME_LOCAL
echo SOFTWARE_HOME_REMOTE=$SOFTWARE_HOME_REMOTE
echo SOFTWARE_HOME=$SOFTWARE_HOME
mkdir -p /var/log/containers
ruby -v
#ruby $SOFTWARE_HOME/tools/make-services.rb -site=64 -sizes=$SOFTWARE_HOME/tools/overrides.dat $SOFTWARE_HOME/tools/services.all > $SOFTWARE_HOME/tools/services.dat
cd /opt/data/home/bin
ruby run_service.rb "$1" | tee /var/log/containers/log.txt
