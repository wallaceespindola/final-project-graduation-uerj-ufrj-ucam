#!/bin/bash

################################################################################
#  Script para rodar testes de Vazão x Perda com RTTs fixos em redes gigabit,  #
#          utilizando os protocolos de transporte TCP, HSTCP e STCP            #
#                                                                              #
#    *** Projeto de Graduação VIII-B - Engenharia de Telecom - UERJ ***        #
#                                                                              #
# Autor: Wallace de Souza Espindola                                            #
# Colaboração em linguagem Shell Script: Antônio João N. Dantas                #
#                                                                              #
# Criado em: Fevereiro/2007                                                    #
#                                                                              #
################################################################################

start() {

    #####################################################################
    #                     Configurações Iniciais                        #
    #####################################################################

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
    
    # Levanta os modulos dos protocolos extras e loga a config em arquivo
    modprobe tcp_highspeed
    modprobe tcp_scalable
    lsmod | sort > lsmod.txt
    
    # Inicia o Netem (network emulator) -- o primeiro tem que ser "add"
    tc qdisc add dev eth0 root netem delay 0ms loss 0%
    
    # Populando matriz de atrasos
    delay[1]="0"
    delay[2]="15"
    delay[3]="30"
    delay[4]="45"
    delay[5]="60"
    delay[6]="75"
    
start;
testeTCP;
testeHSTCP;
testeSTCP;
