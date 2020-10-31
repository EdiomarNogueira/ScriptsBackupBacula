#!/bin/sh

DATABASE=${2}    #nome do bd
SERVICO=${3}     #nome do serviço ao qual se tem o bd
USER=${4}        #usuário com autenticação no banco

#ManageOldDump - Processo de remoção do dump mais antigo contido na pasta old e preparação e 
#remanejamento do até então, arquivo dump mais recente para a pasta old. 
ManageOldDump () {
    cd /opt/bacula/backups/${BANCO}/${SERVICO}
    ARQUIVO_DUMP=$(ls | grep ${PREFIXO}_${SERVICO} 2>/dev/null)

    cd ../old
    OLD_BANCO=$(ls | grep old_${PREFIXO}_${SERVICO}* 2>/dev/null) 
    Status=$?
    if [ $Status -ne 0 ]; then
        echo "Arquivo old do "${SERVICO}" não existente."
    else
        rm -r ${OLD_BANCO}
    fi
    cd ../${SERVICO}
    mv  ${ARQUIVO_DUMP} ../old/old_${ARQUIVO_DUMP} 2>/dev/null

    Status=$?
        if [ $Status -ne 0 ]; then
                echo 'Erro ao gerar old_'$ARQUIVO_DUMP' - status $Status'
            else
                echo 'old_'$ARQUIVO_DUMP' gerado com sucesso!'
            fi
    StartDump
}

StartDump () {
    cd /opt/bacula/backups/${BANCO}/${SERVICO}
    if [ $BANCO = "mongodb" ]; then
        sudo mongodump --db ${DATABASE} --out /opt/bacula/backups/${BANCO}/${SERVICO}/${PREFIXO}_${SERVICO}_dump.${WHEN}

    elif [ $BANCO = "postgres" ]; then
        sudo pg_dump -U ${USER} ${DATABASE} > ${PREFIXO}_${SERVICO}_dump.${WHEN}.bak

    elif [ $BANCO = "mariadb" ]; then
        sudo mysqldump -u ${USER} -p ${DATABASE} > ${PREFIXO}_${SERVICO}_dump.${WHEN}.sql
    fi
    Status=$?
    if [ $Status -ne 0 ]; then
            echo "Erro na execução do backup do banco " ${DATABASE}" - status $Status"
        else
            echo "Novo dump do banco "${DATABASE}" executado com sucesso!"
        fi
}

WHEN=`date +%Y-%m-%d`
#Verificação de erros nos parâmetros passados para o script
case $1 in
    mongodb) BANCO="mongodb"; PREFIXO="mongodb"; ManageOldDump;;
    postgres) BANCO="postgres"; PREFIXO="pg"; ManageOldDump;;
    mariadb) BANCO="mariadb"; PREFIXO="mariadb"; ManageOldDump;;
    *) echo 'Banco inválido, revise os parâmetros passados.'
       echo 'Bancos esperados: [mongodb | postgres | mariadb]'
exit 1;;
esac
