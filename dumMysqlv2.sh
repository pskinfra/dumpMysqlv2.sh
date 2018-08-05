#!/bin/bash

# Script de backup de shemas do mysql.
#
# - Configuracao
# Para configurar o script, e necessario alterar os valores das seguintes constantes:
#     USER - Usuario para acesso ao MySQL;
#     PASSWORD - Senha do usuario para acesso ao MySQL;
#     OUTPUT - Diretorio que recebera os arquivos de backup;
#     LOG - Diretorio de log do script
#     ARQUIVO_LOG - Nome do arquivo de log
#     Filtrando os schemas - Para filtrar schemas que nao devem passar pelo procedimento de backup basta acrescentar,
#       sem as aspas, o seguinte comando "&& [[ "$db" != "<NOME_SCHEMA>" ]]", subistituindo a TAG <NOME_SCHEMA> pelo
#       nome do schema e dicionar no final do IF
#
# - Plano de execucao do script:
# Passo 1: Remover todos os arquivos com estecao .sql e .gz do diretorio configurado na constante "OUTPUT";
# Passo 2: Listar todos os schemas do servidor;
# Passo 3: Iterar a lista de schemas recuperada;
# Passo 4: Verificar se o nome do schema nao e um dos nomes contidos no IF;
# Passo 5: Gerar o dump do schema;
# Passo 6: Compactar o o arquivo de dump;
# Passo 7: Voltar para o passo 3 ate que nao tenha mais schemas para fazer backup;
#
# Criado em: 05/11/2015
# Criado por: Guilherme Viana Freire
# Ajustado em: 22/06/2017 
# Por: Tiago Silva -  tleite@bsd.com.br

USER="USER"
PASSWORD="PASS"
OUTPUT="/var/mysql_dump_tmp"
LOG="/var/log/mysql_backup"
ARQUIVO_LOG="$LOG/log_backup_`date +%Y%m%d`.log"
OUTPUT_REMOTO="/var/BKP-MYSQL"


mkdir -p $LOG
mkdir -p $OUTPUT
mkdir -p $OUTPUT_REMOTO

if [ ! -e "$ARQUIVO_LOG" ] ; then
    touch "$ARQUIVO_LOG"
fi

echo "[$(date +%d/%m/%Y-%H:%M:%S)] Iniciando o backup do MySQL" >> $ARQUIVO_LOG

echo "[$(date +%d/%m/%Y-%H:%M:%S)] Removendo os arquivos anteriores" >> $ARQUIVO_LOG

rm -f $OUTPUT/*.xz
rm -f $OUTPUT/*.sql

echo "[$(date +%d/%m/%Y-%H:%M:%S)] Listando todos os schemas do servidor" >> $ARQUIVO_LOG
databases=`mysql --user=$USER --password=$PASSWORD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`

for db in $databases; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != "test" ]] && [[ "$db" != "performance_schema" ]] ; then
        echo "[$(date +%d/%m/%Y-%H:%M:%S)] Executando o DUMP do schema: $db" >> $ARQUIVO_LOG
        mysqldump --user=$USER --password=$PASSWORD --routines --databases $db > $OUTPUT/`date +%Y%m%d`_$db.sql
        echo "[$(date +%d/%m/%Y-%H:%M:%S)] Compactando o DUMP do schema: $db" >> $ARQUIVO_LOG
        xz -z $OUTPUT/`date +%Y%m%d`_$db.sql >> $ARQUIVO_LOG
        echo "[$(date +%d/%m/%Y-%H:%M:%S)] DUMP do schema: $db criado com sucesso" >> $ARQUIVO_LOG
	cp $OUTPUT/`date +%Y%m%d`_$db.sql.xz $OUTPUT_REMOTO/`date +%Y%m%d`_$db.sql.xz
	echo "[$(date +%d/%m/%Y-%H:%M:%S)] Arquivo movido para diretorio remoto" >> $ARQUIVO_LOG
    fi
done
echo "[$(date +%d/%m/%Y-%H:%M:%S)] Backup do MySQL termidado" >> $ARQUIVO_LOG

echo "[$(date +%d/%m/%Y-%H:%M:%S)] ===============================" >> $ARQUIVO_LOG
