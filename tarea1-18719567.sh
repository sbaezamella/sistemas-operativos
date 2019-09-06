#!/bin/bash

# Sebastián Andrés Baeza Mella
# 18.719.567-5


case $1 in
  '')

    MODEL_NAME="$(cat /proc/cpuinfo | grep "model name" | head -1 | awk '{print $4,$5,$6,$7,$9}')"
    KERNEL_VERSION="$(cat /proc/version | awk '{print $1,$2,$3}')"
    MEMORY="$(cat /proc/meminfo | grep MemTotal | awk '{print $2,$3}')"
    UPTIME="$(cat /proc/uptime | awk '{printf "%.4f",$1/86400}')"

    echo -e "ModelName: $MODEL_NAME\nKernelVersion: $KERNEL_VERSION\nMemory (kB): $MEMORY\nUptime (Dias): $UPTIME dia(s)"
    ;;

  '-ps')

    printf "\t%-14s %-10s %-10s %-14s %-10s\n" "UID" "PID" "PPID" "Status" "CMD"
    for pid in $(ls -l /proc | grep ^d | awk '$9 ~ /^[0-9]+$/ {print $9}'); do
      dir="/proc/$pid"
      if [ -d "$dir" ]; then
        uid="$(cat /proc/$pid/status | grep Uid | awk '{print $2}')"
        user="$(cat /etc/passwd | grep -w $uid | awk -F: '{print $1}')"
        ppid="$(cat /proc/$pid/status | grep PPid | awk '{print $2}')"
        status="$(cat /proc/$pid/status | grep State | awk '{print $2}')"
        cmd="$(cat /proc/$pid/comm)"

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

        printf "\t%-14s %-10d %-10d %-14s %-10s\n" "$user" "$pid" "$ppid" "$status" "$cmd"
      fi
    done
    # echo "counter: $i"
  ;;

  '-help')

    echo "Uso del script: bash tarea1-18719567.sh ó ./tarea1-18719567.sh [OPTION]...
    Script correspondiente a la tarea 1 de Sistemas Operativos, el cual entrega
    informacion un ordenador: hardware, procesos, puertos, memoria, disco, etc.

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
      bash tarea1-18719567.sh"
  ;;

  *)
    echo "Uso: bash tarea1-18719567.sh ó ./tarea1-18719567.sh [OPTION]...
Intente './tarea1-18719567.sh -help' para mas informacion"
  ;;

esac







