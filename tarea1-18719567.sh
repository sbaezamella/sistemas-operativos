#!/bin/bash

# Tarea 1 Sistemas Operativos - Bash y awk
# Sebastián Andrés Baeza Mella
# 18.719.567-5

usage() { printf "%s" "\
Uso del script: bash tarea1-18719567.sh ó ./tarea1-18719567.sh [OPTION]...
Script correspondiente a la tarea 1 de Sistemas Operativos, la cual entrega
información del ordenador: hardware, procesos, puertos, memoria, disco, etc.

Sin OPTION el script entregará el nombre del modelo del pc, version del kernel,
memoria y tiempo que ha estado encendido el ordenador.

  -ps               procesos actuales (UID,PID,PPID,estado,comando)
  -psBlocked        procesos con archivos bloqueados (PID,nombre,tipo de bloqueo)
  -m                cantidad total RAM y cantidad disponible RAM (GB)
  -tcp              conexiones TCP (direccion origen,direccion destino,estado)
  -tcpStatus        mismas conexiones pero esta vez agrupada por estado

Ayuda:
  -help             desplega este texto y termina

Ejemplos:

  ./tarea1-18719567.sh -ps
  bash tarea1-18719567.sh -tcp
  bash tarea1-18719567.sh
"
exit 1
}

error() { printf "%s" "\
Error: Argumento inválido
Uso: bash tarea1-18719567.sh ó ./tarea1-18719567.sh [OPTION]...
Intente './tarea1-18719567.sh -help' para mas informacion
"
exit 1
}

case $1 in

  '')
    model_name="$(cat /proc/cpuinfo | grep "model name" | head -1 | awk '{print $4,$5,$6,$7,$9}')"
    kernel_version="$(cat /proc/version | awk '{print $1,$2,$3}')"
    memory="$(cat /proc/meminfo | grep MemTotal | awk '{print $2,$3}')"
    uptime="$(cat /proc/uptime | awk '{printf "%.4f",$1/86400}')"
    echo -e "ModelName: $model_name\nKernelVersion: $kernel_version\nMemory (kB): $memory\nUptime (Dias): $uptime dia(s)"
  ;;

  '-ps')
    printf "%-14s %-10s %-10s %-14s %-10s\n" "UID" "PID" "PPID" "Status" "CMD"
    cd /proc
    numeros='^[0-9]+$'
    for carpeta in *; do
      if [[ -d $carpeta ]] && [[ $carpeta =~ $numeros ]]; then
        cd $carpeta
        uid="$(cat status | grep Uid | awk '{print $2}')"
        username="$(cat /etc/passwd | grep -w $uid | awk -F: '{print $1}')"
        ppid="$(cat status | grep PPid | awk '{print $2}')"
        status="$(cat status | grep State | awk '{print $2}')"
        cmd="$(cat comm)"
        pid=$carpeta
        cd ..
        case $status in
          'R') status='Running' ;;
          'S') status='Sleeping' ;;
          'D') status='Disk sleep' ;;
          'Z') status='Zombie' ;;
          'I') status='Idle' ;;
          'T') status='Stopped' ;;
          't') status='Tracing stop' ;;
          'W') status='Paging' ;;
          'x | X') status='Dead' ;;
          'K') status='Wakekill' ;;
          'W') status='Waking' ;;
          'P') status='Parked' ;;
        esac
        printf "%-14s %-10d %-10d %-14s %-10s\n" "$username" "$pid" "$ppid" "$status" "$cmd"
      fi
    done
  ;;

  '-psBlocked')
    printf "%-10s %-17s %-10s\n" "PID" "NOMBRE PROCESO" "TIPO"
    cat /proc/locks | while read line; do
    pid=$(echo $line | awk '{print $5}')
    nombre=$(cat /proc/$pid/comm)
    tipo=$(echo $line | awk '{print $2}')
    printf "%-10s %-17s %-10s\n" "$pid" "$nombre" "$tipo"
    done
  ;;

  '-m')
    printf "%-10s %-10s\n" "Total" "Available"
    total="$(cat /proc/meminfo | grep "MemTotal" | awk '{printf "%.1f",$2/1048576}')"
    available="$(cat /proc/meminfo | grep "MemAvailable" | awk '{printf "%.1f",$2/1048576}')"
    printf "%4s %12s\n" "$total" "$available"
  ;;

  '-tcp')
    printf "%-20s %-20s %-20s\n" "Source:Port" "Destination:Port" "Status"
    #for h in $(awk 'NR>1{print $2,$3}')
  ;;

  '-help') usage ;;

  *) error ;;

esac







