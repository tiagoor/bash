#!/bin/bash
NVM=0
FILA=""
MAX_NPROC=2 # padrao
SUBST_CMD=0 # sem substituicao por padrao
VTILZA="Um simples empacotador para executar processos bash em paralelo.
Utilizacao: `nomebase $0` [-h] [-r] [-j nb_jobs] commando arg_lista
 	-h		Mostra esta ajuda
	-r		Substituir asterisco * na string da cadeia de comando com argumento
	-j nb_jobs 	Seta o numero de jobs simultaneos [2]
 Exemplos:
 	`nomebase $0` algumcommando arg1 arg2 arg3
 	`nomebase $0` -j 3 \"algumcommando -r -p\" arg1 arg2 arg3
 	`nomebase $0` -j 6 -r \"convert -scale 50% * small/small_*\" *.jpg"

function qveue {
	FILA="$FILA $1"
	NVM=$(($NVM+1))
}

function regenerateqveue {
	OLDREFILA=$FILA
	FILA=""
	NVM=0
	for PID in $OLDREFILA
	do
		if [ -d /proc/$PID  ] ; then
			FILA="$FILA $PID"
			NVM=$(($NVM+1))
		fi
	done
}

function checkqveue {
	OLDCHFILA=$FILA
	for PID in $OLDCHFILA
	do
		if [ ! -d /proc/$PID ] ; then
			regenerateqveue # at least one PID has finished
			break
		fi
	done
}

# parseia linha de comando
if [ $# -eq 0 ]; then #  minimo de um argvmento
	echo "$VTILZA" >&2
	exit 1
fi

while getopts j:rh OPT; do # "j:" waits for an argument "h" doesnt
    case $OPT in
	h)	echo "$VTILZA"
		exit 0 ;;
	j)	MAX_NPROC=$OPTARG ;;
	r)	SUBST_CMD=1 ;;
	\?)	# getopts issues an error message
		echo "$VTILZA" >&2
		exit 1 ;;
    esac
done

# Programa principal
echo Usando $MAX_NPROC threads paralelas
shift `expr $OPTIND - 1` # shift argvmentos de entrada, ignora argvmentos processados
COMMAND=$1
shift

for INS in $* # para o restante dos argvmentos
do
	# DEFINIR COMANDO
	if [ $SUBST_CMD -eq 1 ]; then
		CMD=${COMMAND//"*"/$INS}
	else
		CMD="$COMMAND $INS" #append args
	fi
	echo "Rvnning $CMD" 

	$CMD &
	# DEFINER COMANDO END

	PID=$!
	qveue $PID

	while [ $NVM -ge $MAX_NPROC ]; do
		checkqveue
		sleep 0.4
	done
done
wait # espera por todos processos que terminem para sair, exit. bye0bye.
