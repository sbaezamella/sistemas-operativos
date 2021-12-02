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
  -frag             Espacio separado por el tamaño de los fragmentos en Mb

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

# Funcion que convierte y luego parsea la ip de entrada de la forma 0100007F:0277
# Los argumentos se trabajan de manera similar a cuando se pasan argumentos por linea de comandos a un script
# Dentro de la funcion son accesibles con $1, $2, $3, ..., etc.
# Pide dos argumentos, la dirección y el puerto, esto es:
# convert_then_parse_ip 01000007F 0277
convert_then_parse_ip() {
  local string_ip="" # String a retornar
  for i in {6..0..2} # Valores de i disminuyes [6, 4, 0, 2]
  do
    string_ip+=$(echo $((16#${1:$i:2}))) # $1 corresponde al primer argumento de la funcion
                                          # Cada iteracion selecciona 2 caracteres hacia la derecha. Ej: 0100007F:6:2 -> 7F
                                          # Luego se convierte de hex a decimal con 'echo $(( 16#7F ))' -> 127 y se van concatenando
    if [ $i -gt 1 ]; then # Sólo cuando i sea mayor a 1 se concatena un '.' quedando 127.0.0.1
      string_ip+='.'
    fi
  done
  string_ip+=':'$(echo $((16#$2))) # Se convierte de hex a dec el puerto y se concatena con un ':' antes
                                   # 'echo (( 16#0277 ))' -> 631
                                   # Resultado string_ip=127.0.0.1:631
  echo "$string_ip"
}

# Función para imprimir todas las direcciones ip con protocolo de transmision de control (TCP/IP)
tcp_function() {

  tail --lines=+2 $1 | while read line; do

    # Se extraen informacion primordial desde /proc/net/tcp
    local dir_local=$(echo $line | awk '{ print $2 }' | awk -F: '{ print $1 }')
    local puerto_local=$(echo $line | awk '{ print $2 }' | awk -F: '{ print $2 }')
    local dir_remota=$(echo $line | awk '{ print $3 }' | awk -F: '{ print $1 }')
    local puerto_remoto=$(echo $line | awk '{ print $3 }' | awk -F: '{ print $2 }')
    local state=$(echo $line | awk '{ print $4 }')

    case $(echo "ibase=16; $state" | bc) in # Se asigna el state segun su hex
      '1') state=TCP_ESTABLISHED ;;
      '2') state=TCP_SYN_SENT ;;
      '3') state=TCP_SYN_RECV ;;
      '4') state=TCP_FIN_WAIT1 ;;
      '5') state=TCP_FIN_WAIT2 ;;
      '6') state=TCP_TIME_WAIT ;;
      '7') state=TCP_CLOSE ;;
      '8') state=TCP_CLOSE_WAIT ;;
      '9') state=TCP_LAST_ACK ;;
      '10') state=TCP_LISTEN ;;
      '11') state=TCP_CLOSING ;;
      '12') state=TCP_NEW_SYN_RECV ;;
    esac

    local num_ip_local=$(convert_then_parse_ip $dir_local $puerto_local)
    local num_ip_remota=$(convert_then_parse_ip $dir_remota $puero_remoto)

    printf '%-25s %-25s %-s\n' "$num_ip_local" "$num_ip_remota" "$state"

  done
}

# Se utiliza un bloque de instrucción case para las posibles entradas o argumentas del script
# Se testea con '', '-ps', '-psBlocked', '-m', '-tcp', 'tcpStatus', '-help', *
# Éste último es para cubrir los demas casos, arroja un texto amigable de error con sugerencias de como usar el script
case $1 in

  '')

    # Se utiliza awk para realizar la acción detallada cuando el patrón (expresión regular)
    # reconoce una secuencia de carácteres dentro del archivo otorgado
    # Ejemplo: awk '/pattern/ { do something }' file.txt
    model_name=$(awk '/model name/ { print $4, $5, $6, $7, $9; exit; }' /proc/cpuinfo) # Se utiliza exit para obtener solo la primera coincidencia
    kernel_version=$(awk '{ print $1, $2, $3 }' /proc/version) # Equivalente a $(cat /proc/version | awk '{print $1,$2,$3}')
    memory=$(awk '/MemTotal/ { print $2, $3 }' /proc/meminfo)
    uptime=$(awk '{ printf "%.4f", $1/86400 }' /proc/uptime) # Formatea $1, el cual es float, hasta 4 decimales
    printf "%s\n" \
    "ModelName: $model_name" \
    "KernelVersion: $kernel_version" \
    "Memory (kB): $memory" \
    "Uptime (Dias): $uptime dia(s)"

  ;;

  '-ps')

    printf "%-18s %-10s %-10s %-14s %-s\n" "UID" "PID" "PPID" "Status" "CMD"
    cd /proc
    numeros="^[0-9]+$"

    for carpeta in *; do

      if [[ -d $carpeta ]] && [[ $carpeta =~ $numeros ]]; then

        cd $carpeta
        uid=$(awk '/Uid/ { print $2 }' status)

        # Separar lineas por ":" del archivo /etc/passwd. Asignar $uid a la variable interna de awk id
        # para checkear que el tercer campo es igual al uid. Debido a casos extremos donde el uid exista
        # en una linea y como gid en otra.
        username=$(awk -F: --assign id=$uid '$3==id { print $1 }' /etc/passwd)

        ppid=$(awk '/PPid/ { print $2 }' status)
        status=$(awk '/State/ { print $2 }' status)
        cmd=$(cat comm)
        pid=$carpeta
        cd ..

        case $status in
          'R') status=Running ;;
          'S') status=Sleeping ;;
          'D') status=Disk sleep ;;
          'Z') status=Zombie ;;
          'I') status=Idle ;;
          'T') status=Stopped ;;
        esac

        printf "%-18s %-10d %-10d %-14s %-s\n" "$username" "$pid" "$ppid" "$status" "$cmd"
      fi
    done
  ;;

  '-psBlocked')

    printf "%-10s %-17s %-s\n" "PID" "NOMBRE PROCESO" "TIPO"

    awk '!a[$5]++ { print $2, $5 }' /proc/locks | while read line; do

    tipo=$(echo $line | awk '{ print $1 }')
    pid=$(echo $line | awk '{ print $2 }')
    nombre=$(cat /proc/$pid/comm)
    printf "%-10d %-17s %-s\n" "$pid" "$nombre" "$tipo"

    done
  ;;

  '-m')

    # Del archivo /proc/meminfo se busca por regex "MemTotal" y se guarda en variable total
    # Luego se busca por regex "MemAvailable" y se imprime
    awk '/MemTotal/ { total=$2 }
         /MemAvailable/ { printf "%-10s %-s\n", "Total", "Available"
                          printf "%4.1f %12.1f\n", total/1048576, $2/1048576 }' /proc/meminfo
  ;;

  '-tcp')

    printf "%-25s %-25s %-s\n" "Source:Port" "Destination:Port" "Status"
    tcp_function /proc/net/tcp

  ;;

  '-tcpStatus')

    printf "%-25s %-25s %-s\n" "Source:Port" "Destination:Port" "Status"
    tcp_function /proc/net/tcp | sort -b -k 3,3

  ;;

  '-frag')

    printf "%-10s\t %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %s\n" "Tamaño" "4KB" "8KB" "16Kb" "32KB" "64KB" "128KB" "256KB" "512KB" "1MB" "2MB" "4MB"

    declare -a chunk=()

    while read line
    do
      read -ra fields <<< "$line"
      for i in {4..14}
      do
        pos=$(bc <<< $i-4)
        if [ -z ${chunk[$pos]} ]; then
          chunk[$pos]=$(bc <<< "${fields[$i]}")
        else
          chunk[$pos]=$(bc <<< "${fields[$i]} + ${chunk[$pos]}")
        fi
      done
    done <  <(cat /proc/buddyinfo)

    for i in {0..10}
    do
      if [ $i -lt 8 ]; then
        chunk[$i]=$(bc -l <<< "scale=2;${chunk[$i]}*4*2^$i/1024")
      else
        chunk[$i]=$(bc <<< "${chunk[$i]}*4*2^$i/1024")
      fi
    done

    printf "%10s\t %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %s\n" "Espacio Libre" "${chunk[0]}Mb" "${chunk[1]}Mb" "${chunk[2]}Mb" "${chunk[3]}Mb" "${chunk[4]}Mb" "${chunk[5]}Mb" "${chunk[6]}Mb" "${chunk[7]}Mb" "${chunk[8]}Mb" "${chunk[9]}Mb" "${chunk[10]}Mb"

  ;;

  '-help') usage ;;

  *) error ;;

esac
