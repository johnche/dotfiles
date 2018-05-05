umask 022
setxkbmap -option caps:escape

# npm global
set -gx NPM_CONFIG_PREFIX '~/.npm-global'
set -gx PATH $PATH '~/.npm-global/bin'

# Below installed for Big Data
alias hadoop '~/Programs/hadoop-3.0.0/bin/hadoop'
alias pyspark '~/Programs/spark-2.2.1-bin-hadoop2.7/bin/pyspark'
alias spark-shell '~/Programs/spark-2.2.1-bin-hadoop2.7/bin/spark-shell'
alias spark-submit '~/Programs/spark-2.2.1-bin-hadoop2.7/bin/spark-submit'

# Dependency for Hadoop fs
set -gx JAVA_HOME '/usr/lib/jvm/openjdk-1.8.0_182'
set -gx PATH $PATH '~/Programs/hadoop-3.0.0/bin'

# Dependency for spark
#set -gx HADOOP_HOME '~/Programs/hadoop-3.0.0'
set -gx HADOOP_HOME '~/Programs/spark-2.2.1-bin-hadoop2.7'
set -gx PATH $PATH '~/Programs/spark-2.2.1-bin-hadoop2.7/bin'
set -gx PATH $PATH '~/Programs/spark-2.2.1-bin-hadoop2.7/bin'
#set -gx PYSPARK_DRIVER_PYTHON 'ipython'

# Pycharm alias
alias pycharm '~/Programs/pycharm-2018.1.1/bin/pycharm.sh'

# Firefox broken sound, temp fix
set -gx MOZ_DISABLE_CONTENT_SANDBOX 1
