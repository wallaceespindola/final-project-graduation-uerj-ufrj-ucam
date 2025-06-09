!/bin/bash

################################################################################
# Script para rodar testes de Vazão x Perda com RTTs fixos em redes gigabit,   #
# utilizando os protocolos de transporte TCP, HSTCP e STCP                     #
#                                                                              #
# *** Projeto de Graduação VIII-B - Engenharia de Telecom - UERJ ***           #
#                                                                              #
# Autor: Wallace de Souza Espindola                                            #
# Colaboração em linguagem Shell Script: Antônio João N. Dantas                #
#                                                                              #
# Criado em: Fevereiro/2007                                                    #
#                                                                              #
################################################################################

# Projeto: Avaliação Experimental de Protocolos de Transporte em Redes Gigabit
# 8.2. Apêndice B: Script de execução dos testes no cliente

start() {

  #####################################################################
  # Configurações Iniciais                                            #
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
  # Populando matriz de perdas
  loss[1]="0.0001"
  loss[2]="0.0002"
  loss[3]="0.0005"
  loss[4]="0.0010"
  loss[5]="0.0020"
  loss[6]="0.0050"
  loss[7]="0.0100"
}

teste() {

  #####################################################################
  # Execução dos Testes                                               #
  #####################################################################

  for d in `seq 6` do
  for l in `seq 7` do

  # Seta o atraso e o rtt necessarios para o teste - nesse loop usa "change"
  tc qdisc change dev eth0 root netem delay ${delay[$d]}ms loss ${loss[$l]}%
  for f in `seq 10` do
  # Comandos Iperf para execucao dos testes
  # (-w window size /-t duration (s)/-i interval (s)/-l lenth of buffer)
  case "$tipo" in
  TCP)
  flowfile="TCP.vazao.rtt_${delay[$d]}.loss_${loss[$l]}.test$f.txt"
  consolfile="TCP.consolidado.rtt_${delay[$d]}ms.loss_${loss[$l]}.txt"
  lossxflowfile="tcplossxflow.rtt_${delay[$d]}ms.txt"
  iperf -c 10.24.60.71 -w 4M -t 60 -i 5 -l 64k > $flowfile
  cat $flowfile | tail -n1 >> $consolfile
  # Salva estatisticas do netem
  echo "" >> netem_tcp.txt
  echo "*************** $flowfile ***************" >> netem_tcp.txt
  echo "" >> netem_tcp.txt
  tc -s qdisc ls dev eth0 >> netem_tcp.txt
  ;;
  HSTCP)
  flowfile="HSTCP.vazao.rtt_${delay[$d]}.loss_${loss[$l]}.test$f.txt"
  consolfile="HSTCP.consolidado.rtt_${delay[$d]}ms.loss_${loss[$l]}.txt"
  lossxflowfile="hstcplossxflow.rtt_${delay[$d]}ms.txt"
  iperf -c 10.24.60.71 -w 4M -t 60 -i 5 -l 64k > $flowfile
  cat $flowfile | tail -n1 >> $consolfile
  # Salva estatisticas do netem
  echo "" >> netem_hstcp.txt
  echo "*************** $flowfile ***************" >> netem_hstcp.txt
  echo "" >> netem_hstcp.txt
  tc -s qdisc ls dev eth0 >> netem_hstcp.txt
  ;;
  STCP)
  flowfile="STCP.vazao.rtt_${delay[$d]}.loss_${loss[$l]}.test$f.txt"
  consolfile="STCP.consolidado.rtt_${delay[$d]}ms.loss_${loss[$l]}.txt"
  lossxflowfile="stcplossxflow.rtt_${delay[$d]}ms.txt"
  iperf -c 10.24.60.71 -w 4M -t 60 -i 5 -l 64k > $flowfile
  cat $flowfile | tail -n1 >> $consolfile
  echo "" >> netem_stcp.txt
  echo "*************** $flowfile ***************" >> netem_stcp.txt
  echo "" >> netem_stcp.txt
  tc -s qdisc ls dev eth0 >> netem_stcp.txt
  ;;
  *)
  ;;
  esac;
  done;
  # Apos rodar o for interno 10 vezes executa lossxflow no for de 7
  lossxflow
  done;
  done;
}

lossxflow() {

  #####################################################################
  # Gera os arquivos de perda x vazão por tipo de protocolo           #
  #####################################################################

  cat $consolfile |
  while read line;
  do
  flow=`echo $line | awk '{print $7}'`
  loss=`ls $consolfile | awk -F"_" '{print $3}' | cut -f 1,2 -d '.'`
  printf "$loss\t$flow\n" >>/root/Desktop/wallace/Testes/consolidados/$lossxflowfile
  done;
}

testeTCP() {

  #####################################################################################
  # TESTES DO PROTOCOLO TCP                                                           #
  #####################################################################################

  echo ""
  echo "***************************************************************"
  echo "************** INICIANDO TESTES DO PROTOCOLO TCP **************"
  echo "***************************************************************"
  echo ""
  tipo="TCP"
  # Vai para o diretorio dos testes
  cd /root/Desktop/wallace/Testes/Tests_TCP
  # Remove arquivos antigos para evitar erros em próximas execuções
  rm -rf *.txt
  # Verifica o sysctl.conf e modifica o sysctl para usar o TCP, logando em arquivo
  echo "**************** Aplica configs do sysctl.conf ****************" > sysctl_TCP.txt
  sysctl -p >> sysctl_TCP.txt
  echo "***************** Pega dados de TCP do sysctl *****************" >> sysctl_TCP.txt
  sysctl -w net.ipv4.tcp_congestion_control=reno
  sysctl -a | grep tcp >> sysctl_TCP.txt
  echo "*************** Pega dados de memoria do sysctl ***************" >> sysctl_TCP.txt
  sysctl -a | grep mem >> sysctl_TCP.txt
  echo "************* Pega dados de route.flush do sysctl *************" >> sysctl_TCP.txt
  sysctl -a | grep flush >> sysctl_TCP.txt
  teste
  echo ""
  echo "***************************************************************"
  echo "************** TESTES DO PROTOCOLO TCP COMPLETOS **************"
  echo "***************************************************************"
  echo ""
}

testeHSTCP() {

  #####################################################################################
  # TESTES DO PROTOCOLO HSTCP                                                         #
  #####################################################################################

  echo ""
  echo "***************************************************************"
  echo "************* INICIANDO TESTES DO PROTOCOLO HSTCP *************"
  echo "***************************************************************"
  echo ""
  tipo="HSTCP"
  # Vai para o diretorio dos testes
  cd /root/Desktop/wallace/Testes/Tests_HSTCP
  # Remove arquivos antigos para evitar erros em próximas execuções
  rm -rf *.txt
  # Verifica o sysctl.conf e modifica o sysctl para usar o HSTCP, logando em arquivo
  echo "**************** Aplica configs do sysctl.conf ****************" > sysctl_HSTCP.txt
  sysctl -p >> sysctl_HSTCP.txt
  echo "***************** Pega dados de TCP do sysctl *****************" >> sysctl_HSTCP.txt
  sysctl -w net.ipv4.tcp_congestion_control=highspeed
  sysctl -a | grep tcp >> sysctl_HSTCP.txt
  echo "*************** Pega dados de memoria do sysctl ***************" >> sysctl_HSTCP.txt
  sysctl -a | grep mem >> sysctl_HSTCP.txt
  echo "************* Pega dados de route.flush do sysctl *************" >> sysctl_HSTCP.txt
  sysctl -a | grep flush >> sysctl_HSTCP.txt
  teste
  echo ""
  echo "***************************************************************"
  echo "************* TESTES DO PROTOCOLO HSTCP COMPLETOS *************"
  echo "***************************************************************"
  echo ""
}

testeSTCP() {

  #####################################################################################
  # TESTES DO PROTOCOLO STCP                                                          #
  #####################################################################################

  echo ""
  echo "***************************************************************"
  echo "************* INICIANDO TESTES DO PROTOCOLO STCP **************"
  echo "***************************************************************"
  echo ""
  tipo="STCP"
  # Vai para o diretorio dos testes
  cd /root/Desktop/wallace/Testes/Tests_STCP
  # Remove arquivos antigos para evitar erros em próximas execuções
  rm -rf *.txt
  # Verifica o sysctl.conf e modifica o sysctl para usar o STCP, logando em arquivo
  echo "**************** Aplica configs do sysctl.conf ****************" > sysctl_STCP.txt
  sysctl -p >> sysctl_STCP.txt
  echo "***************** Pega dados de TCP do sysctl *****************" >> sysctl_STCP.txt
  sysctl -w net.ipv4.tcp_congestion_control=scalable
  sysctl -a | grep tcp >> sysctl_STCP.txt
  echo "*************** Pega dados de memoria do sysctl ***************" >> sysctl_STCP.txt
  sysctl -a | grep mem >> sysctl_STCP.txt
  echo "************* Pega dados de route.flush do sysctl *************" >> sysctl_STCP.txt
  sysctl -a | grep flush >> sysctl_STCP.txt
  teste
  echo ""
  echo "***************************************************************"
  echo "************* TESTES DO PROTOCOLO STCP COMPLETOS **************"
  echo "***************************************************************"
  echo ""
}

# MAIN
start;
testeTCP;
testeHSTCP;
testeSTCP;