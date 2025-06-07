8.3. Apêndice C: Script de execução dos testes no servidor
#!/bin/bash
################################################################################
# Script para rodar testes de Vazão x Perda com RTTs fixos em redes gigabit, #
# utilizando os protocolos de transporte TCP, HSTCP e STCP #
# #
# *** Projeto de Graduação VIII-B - Engenharia de Telecom - UERJ *** #
# #
# Autor: Wallace de Souza Espindola #
# #
# Criado em: Fevereiro/2007 #
# #
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

Avaliação Experimental de Protocolos de Transporte em Redes Gigabit

67
8.4. Apêndice D: Script de configuração usado nos micros
O script abaixo é o conteúdo do arquivo de configuração do kernel do Linux,
sysctl.conf, que é carregado automaticamente toda vez que o Linux é inicializado.
Todas as configurações aqui feitas são tratadas como configurações fixas do Linux,
já que ele sempre será inicializado da mesma forma, contendo estas mesmas
configurações adicionais de parâmetros do sistema.
# Kernel sysctl configuration file for Red Hat Linux
#
# For binary values, 0 is disabled, 1 is enabled. See sysctl(8) and
# sysctl.conf(5) for more details.
# Controls IP packet forwarding
net.ipv4.ip_forward = 0
# Controls source route verification
net.ipv4.conf.default.rp_filter = 1
# Do not accept source routing
net.ipv4.conf.default.accept_source_route = 0
# Controls the System Request debugging functionality of the kernel
kernel.sysrq = 0
# Controls whether core dumps will append the PID to the core filename.
# Useful for debugging multi-threaded applications.
kernel.core_uses_pid = 1
# Controls the use of TCP syncookies
net.ipv4.tcp_syncookies = 1
###########################################################################
# Abaixo estão as configurações feitas para otimizar o funcionamento #
# das máquinas Linux para a realização dos testes dos protocolos #
# #
# *** Projeto de Graduação VIII-B - Engenharia de Telecom - UERJ *** #
# #
# Autor: Wallace de Souza Espindola #
# #
# Criado em: Fevereiro/2007 #
# #
###########################################################################
# TCP congestion control algorithm
#==> Options are: reno (TCP Reno), highspeed (HSTCP), scalable (STCP), or others.
net.ipv4.tcp_congestion_control = reno
# Increase Linux TCP buffer limits (33554432=32Mb / 65536=64Kb)
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.core.rmem_default = 65536
net.core.wmem_default = 65536
# Increase Linux autotuning TCP buffer limits
# min, default, and max number of bytes to use
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432
net.ipv4.tcp_mem = 33554432 33554432 33554432
# Don't cache ssthresh from previous connection
net.ipv4.tcp_no_metrics_save = 1
# Recommended increasing this for 1000 BT or higher, for 10 Gb using 3000
net.core.netdev_max_backlog = 3000
# Flush all the tcp cache settings
net.ipv4.route.flush = 1