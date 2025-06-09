#!/bin/bash

################################################################################
#  Script para rodar testes de Vazão x Perda com RTTs fixos em redes gigabit,  #
#          utilizando os protocolos de transporte TCP, HSTCP e STCP            #
#                                                                              #
#    *** Projeto de Graduação VIII-B - Engenharia de Telecom - UERJ ***        #
#                                                                              #
# Autor: Wallace de Souza Espindola                                            #
#                                                                              #
# Criado em: Fevereiro/2007                                                    #
#                                                                              #
################################################################################

start() {

    echo ""
    echo "***************************************************************"
    echo "************ INICIANDO TESTES COM O SERVIDOR IPERF ************"
    echo "***************************************************************"
    echo ""
    
    # Vai para o diretorio dos testes
    cd /root/Desktop/wallace/Testes
    
    # Remove antigos arquivos para evitar erros em novas execuções
    rm -rf *.txt
    
    # Modifica valor de txqueuelen e loga a configuracao em arquivo
    ifconfig eth0 txqueuelen 2000
    ifconfig eth0 > ifconfig.txt
    
    # Coloca a Placa de Rede em 1000Mbps Full Duplex com Flow Control Off e loga em arquivo
    ethtool -s eth0 speed 1000 duplex full autoneg off
    ethtool -A eth0 autoneg off rx off tx off
    ethtool eth0 > ethtool.txt
    echo "**********************************************************" >> ethtool.txt
    ethtool -a eth0 >> ethtool.txt
    
    # Verifica o log do driver e1000 da Placa de Rede Intel e loga em arquivo
    dmesg | grep e1000 > dmesg.txt

    # Verifica o sysctl e usa as novas configuracoes do sysctl.conf, logando em arquivo
    echo "************ Aplica configs do sysctl.conf ************" > sysctl_server.txt
    sysctl -p >> sysctl_server.txt
    echo "************** Pega dados de TCP do sysctl **************" >> sysctl_server.txt
    sysctl -a | grep tcp >> sysctl_server.txt
    echo "************ Pega dados de memoria do sysctl ************" >> sysctl_server.txt
    sysctl -a | grep mem >> sysctl_server.txt
    echo "********** Pega dados de route.flush do sysctl **********" >> sysctl_server.txt
    sysctl -a | grep flush >> sysctl_server.txt
    
    # Comando que roda o servidor Iperf nos testes
    # Redireciona o output para um arquivo texto
    # (-s run server / -w window size /-l length of buffer)
    iperf -s -w 4M -l 64k > ifperf_server_tests.txt

    echo ""
    echo "***************************************************************"
    echo "************ TESTES COM O SERVIDOR IPERF CONCLUIDOS ***********"
    echo "***************************************************************"
    echo ""

}

# MAIN
start;
