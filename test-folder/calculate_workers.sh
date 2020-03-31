#!/bin/bash

# CONST 1GB

CONST_1GB="1024*1024*1024"

# VARIABLE WORKERS

CMD_W=0

# VARIABLE MAX MEMORY PERCENT

CMD_M=100

# VARIABLE IS HELP

CMD_H=0

# VARIABLE IS VERBOSE

CMD_V=0

# FUNCTIONS

arithmetic() {
  echo "scale=0; $1" | bc
}

calculateWorkers(){
 # if [ $CMD_W -gt 0 ]; then echo $CMD_W
  #elif [ $(calculateMaxMemory) -le $(arithmetic "$CONST_1GB") ]; then echo 1 # 1GB
  #elif [ $(calculateMaxMemory) -le $(arithmetic "2*$CONST_1GB") ]; then echo 2 # 2GB
  #elif [ $(calculateMaxMemory) -le $(arithmetic "3*$CONST_1GB") ]; then echo 3 # 3GB
  #else
    echo $(arithmetic "$(calculateNumCores)*2+1")
  #fi
}

calculateAvailableWorkers(){
   echo $(arithmetic "$(calculateMaxMemory)/2684354560")
}


calculateMemTotal () {
  echo $(arithmetic "$(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }')*1024")
}


calculateNumCores(){
 # echo $(nproc)
  echo $(( $(lscpu | awk '/^Socket/{ print $2 }') * $(lscpu | awk '/^Core/{ print $4 }') ))
}

calculateNumConcurrentUser(){
  echo $(arithmetic "$(calculateWorkers)*6")
}


calculateMaxMemory() {
  echo $(arithmetic "$(calculateMemTotal)*$CMD_M/100")
}



calculateLimitMemoryHard() {
  echo $(arithmetic "$(calculateMaxMemory)/$(calculateWorkers)")
  #write it in Byte in odoo-server.conf file
  # echo $(arithmetic "$(calculateAvailableWorkers)*2684354560")
  # echo "# NumWorker * 2560MB default Value Per worker = The RAM Should be > " $(arithmetic "$(calculateWorkers)*2560") "MB"
}

calculateLimitMemorySoft() {
  echo $(arithmetic "$(calculateLimitMemoryHard)*80/100")
  #write it in Byte in odoo-server.conf file
  # echo "# NumWorker * 2048MB default Value Per worker = The RAM Should be > " $(arithmetic "$(calculateWorkers)*2048") "MB"
echo "# Recommended RAM Size = NumWorker * ( Hard 2560MiB ) = " $(arithmetic "$(calculateWorkers)*2684") "MB"

}

# COMMANDS

v() {
  echo
  echo "System Information"
  echo "------------------"
  echo "Cores (CORES):  $(calculateNumCores)"
  echo "Total Memory (TOTAL_M): $(calculateMemTotal) bytes"
  echo "Max Allowed Memory (ALLOW_M): $(calculateMaxMemory) bytes"
  echo "Max Allowed Memory Percent, default 80%: $CMD_M%"
  echo
  echo
  echo "Functions to calculate configutarion"
  echo "------------------------------------"
  echo "workers = if not used -w then"
  echo "               if ALLOW_M < 1GB then 1"
  echo "               else ALLOW_M < 2GB then 2"
  echo "               else ALLOW_M < 3GB then 3"
  echo "               else 1+CORES*2"
  echo "          else -w"
  echo "limit_memory_hard = ALLOW_M / workers"
  echo "limit_memory_soft = limit_memory_hard * 80%"
  echo "limit_request = DEFAULT 8196"
  echo "limit_time_cpu = DEFAULT 120"
  echo "limit_time_real = DEFAULT 180"
  echo "max_cron_threads = DEFAULT 2"
  echo
  echo
  echo "Add to the odoo-server.conf"
  echo "---------------------------"
}

h() {
  echo "This file enables us to optimally configure multithreading settings Odoo"
  echo "   -h    Help"
  echo "   -m    Max memory percent to use"
  echo "   -v    Verbose"
  echo "   -w    Set static workers number"
}

c() {
  echo ""
  echo ""
  echo "---------- This Script Configer for Odoo 11 ----------------"
  echo ""
  echo ""
  echo "# -------- Workers ----------------"
  echo workers =  $(arithmetic "$(calculateWorkers)-1")  "; Number of Concurrent User =  $(calculateNumConcurrentUser)"
  echo "; When You Need The Workers Use The Default Hard-Memory(2684MB) & Soft-Memory(2147MB)"
  echo "workers = $(calculateAvailableWorkers)" "; Number of Concurrent User =  " $(arithmetic "$(calculateAvailableWorkers)*6")
  echo ""
  echo "# -------- Hard Memeory -----------"
  echo "limit_memory_hard = $(calculateLimitMemoryHard)"
  echo "" 
  echo "# -------- Soft Memeory -----------"
  echo "limit_memory_soft = $(calculateLimitMemorySoft)"
  echo""
  echo "limit_request = 8192"
  echo "limit_time_cpu = 600"
  echo "limit_time_real = 1200"
  echo "max_cron_threads = 1"
  echo ""
}

# PROCESS PARAMETERS


# PROCESS PARAMETERS

for ((i=1;i<=$#;i++))
do
  case "${!i}" in
    '-w') ((i++))
    CMD_W=${!i}
    ;;
    '-m') ((i++))
    if [ ${!i} -gt 0 ] && [ ${!i} -lt 80 ]; then CMD_M=${!i}
    fi
    ;;
    '-v')
    CMD_V=1
    ;;
    '-h')
    CMD_H=1
    ;;
    *)
    # NOTHING
    ;;
  esac
done

# EXEC ACTION

if [ $CMD_H -eq 1 ]; then h
elif [ $CMD_V -eq 1 ]; then v
else c
fi

exit 0
                                                            
