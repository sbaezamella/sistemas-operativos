#!/bin/bash

# Tarea 1 Sistemas Operativos - Bash y awk
# Sebastián Andrés Baeza Mella
# 18.719.567-5

# Función que imprime información para el caso -help
usage() { printf "%s\n" "\
Uso del script: ./tarea1-18719567.sh -option

Script correspondiente a la tarea 1 de Sistemas Operativos, la cual entrega
información del ordenador tal como hardware, procesos, puertos, memoria, disco, etc.

Sin OPTION el script entregará el nombre del modelo del pc, version del kernel,
memoria y tiempo que ha estado encendido el ordenador/servidor.

  -ps               Procesos que se estan ejecutando en el momento (UID,PID,PPID,estado,comando)
  -psBlocked        Procesos con archivos bloqueados (PID,nombre,tipo de bloqueo)
  -m                Cantidad total de RAM y cantidad disponible de RAM (GB)
  -tcp              Conexiones TCP (ip:puerto origen,ip:puerto destino,estado)
  -tcpStatus        Conexiones TCP agrupadas por estado

Ayuda:
  -help             Imprime este texto y finaliza

Ejemplos:

  ./tarea1-18719567.sh -ps
  ./tarea1-18719567.sh -tcp
  ./tarea1-18719567.sh"

exit 1
}

# Función que imprime información para los demas casos no incluidos en los requerimientos de la tarea
error() { printf "%s\n" "\
Error: Opcion inválida
Uso: ./tarea1-18719567.sh [option]
Intente './tarea1-18719567.sh -help' para mas información"

exit 1
}

case $1 in

  '')

    model_name=$(cat /proc/cpuinfo | grep "model name" | head -1 | awk '{print $4,$5,$6,$7,$9}')
    kernel_version=$(cat /proc/version | awk '{print $1,$2,$3}')
    memory=$(cat /proc/meminfo | grep MemTotal | awk '{print $2,$3}')
    uptime=$(cat /proc/uptime | awk '{printf "%.4f",$1/86400}')
    printf "%s\n" "ModelName: $model_name" "KernelVersion: $kernel_version" "Memory (kB): $memory" "Uptime (Dias): $uptime dia(s)"

  ;;

  '-ps')

    printf "%-18s %-10s %-10s %-14s %-10s\n" "UID" "PID" "PPID" "Status" "CMD"
    cd /proc
    numeros="^[0-9]+$"

    for carpeta in *; do

      if [[ -d $carpeta ]] && [[ $carpeta =~ $numeros ]]; then

        cd $carpeta
        uid=$(cat status | grep Uid | awk '{print $2}')
        username=$(cat /etc/passwd | grep -w $uid | awk -F: '{print $1}')
        #username=$(awk -F: -v id '$3==id {print $1}' /etc/passwd)
        ppid=$(cat status | grep PPid | awk '{print $2}')
        status=$(cat status | grep State | awk '{print $2}')
        cmd=$(cat comm)
        pid=$carpeta
        cd ..

        case $status in
          'R') status=Running ;;
          'S') status=Sleeping ;;
          'D') status=Disk sleep ;;
          'Z') status=Zombie ;;
          'I') status=Idle ;;
          'T') status='Traced or stopped' ;;
          'W') status=Paging ;;
        esac

        printf "%-18s %-10d %-10d %-14s %-10s\n" "$username" "$pid" "$ppid" "$status" "$cmd"
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
    total=$(cat /proc/meminfo | grep "MemTotal" | awk '{printf "%.1f",$2/1048576}')
    available=$(cat /proc/meminfo | grep "MemAvailable" | awk '{printf "%.1f",$2/1048576}')
    printf "%4s %12s\n" "$total" "$available"
  ;;

  '-tcp')

    # printf "%-20s %-20s %-20s\n" "Source:Port" "Destination:Port" "Status"
    awk 'BEGIN {printf "%-20s %-20s %-20s\n","Source:Port","Destination:Port","Status"}
    { NR>1 }
    { print $2 }' /proc/net/tcp
    cat /proc/net/tcp | while read line; do

    direccion_local=$(echo $line | awk '{print $2}' | awk -F: '{print $1}')
    puerto_local=$(echo $line | awk '{print $2}' | awk -F: '{print $2}')
    direccion_remota=$(echo $line | awk '{print $3}' | awk -F: '{print $1}')
    puerto_remoto=$(echo $line | awk '{print $3}' | awk -F: '{print $2}')

    printf "%-20s %-20s %-20s\n" "$direccion_local:$puerto_local" "$direccion_remota:$puerto_remoto" ""

    done
  ;;

  '-tcpStatus')

  ;;

  '-help') usage ;;

  *) error ;;

esac







