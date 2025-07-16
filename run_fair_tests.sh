#!/bin/bash

# Script para testes justos de Docker Offload vs Local
# Garante condições equivalentes eliminando cache e usando mesmo build

set -e

echo "=== TESTE JUSTO: Docker Local vs Docker Offload ==="
echo "Data: $(date)"
echo "Eliminando cache para resultados justos..."
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para limpeza completa
cleanup_all() {
    echo -e "${YELLOW}🧹 Limpando todo o ambiente...${NC}"
    
    # Para e remove containers
    docker-compose down --remove-orphans 2>/dev/null || true
    
    # Remove todas as imagens relacionadas ao projeto
    docker rmi "$(docker images --filter "reference=docker-offload-tests*" -q)" 2>/dev/null || true
    
    # Limpa cache do build
    docker builder prune -f
    
    # Limpa sistema Docker completo
    docker system prune -f
    
    echo -e "${GREEN}✅ Limpeza concluída${NC}"
    echo ""
}

# Função para verificar status do Docker Offload
check_offload_status() {
    echo -e "${BLUE}🔍 Verificando status do Docker Offload...${NC}"
    
    if docker context ls | grep -q "cloud"; then
        echo -e "${GREEN}✅ Contexto cloud disponível${NC}"
    else
        echo -e "${RED}❌ Contexto cloud não encontrado${NC}"
        echo "Verifique se o Docker Build Cloud está configurado"
        exit 1
    fi
    echo ""
}

# Função para desabilitar Docker Offload
disable_offload() {
    echo -e "${YELLOW}📱 Desabilitando Docker Offload (modo local)...${NC}"
    docker context use default
    
    # Verifica se foi desabilitado
    if docker context show | grep -q "default"; then
        echo -e "${GREEN}✅ Docker configurado para execução local${NC}"
    else
        echo -e "${RED}❌ Falha ao configurar modo local${NC}"
        exit 1
    fi
    echo ""
}

# Função para habilitar Docker Offload
enable_offload() {
    echo -e "${YELLOW}☁️ Habilitando Docker Offload (modo cloud)...${NC}"
    
    # Assume que o contexto cloud é o primeiro encontrado
    CLOUD_CONTEXT=$(docker context ls --format "table {{.Name}}" | grep -v "NAME\|default" | head -1)
    
    if [ -n "$CLOUD_CONTEXT" ]; then
        docker context use "$CLOUD_CONTEXT"
        echo -e "${GREEN}✅ Docker configurado para execução cloud: $CLOUD_CONTEXT${NC}"
    else
        echo -e "${RED}❌ Contexto cloud não encontrado${NC}"
        exit 1
    fi
    echo ""
}

# Função para executar teste
run_test() {
    local test_name="$1"
    local description="$2"
    
    echo -e "${BLUE}🚀 Executando: $test_name${NC}"
    echo -e "${BLUE}📋 Descrição: $description${NC}"
    
    # Mede tempo total (build + execução)
    echo "Iniciando em 3 segundos..."
    sleep 3
    
    start_time=$(date +%s.%N)
    
    # Executa docker-compose com rebuild forçado
    echo -e "${YELLOW}⚙️ Executando docker-compose up --build --force-recreate...${NC}"
    docker-compose up --build --force-recreate --no-deps
    
    end_time=$(date +%s.%N)
    
    # Calcula tempo total
    total_time=$(echo "$end_time - $start_time" | bc -l)
    
    echo -e "${GREEN}✅ $test_name concluído${NC}"
    echo -e "${GREEN}⏱️ Tempo total: ${total_time}s${NC}"
    echo ""
    
    # Salva resultado
    echo "$test_name;$total_time" >> test_results.csv
    
    # Limpeza pós-teste
    echo -e "${YELLOW}🧹 Limpando após teste...${NC}"
    docker-compose down --remove-orphans
    docker rmi $(docker images --filter "reference=docker-offload-tests*" -q) 2>/dev/null || true
    docker builder prune -f
    echo ""
}

# Função principal
main() {
    echo -e "${BLUE}=== INICIANDO TESTES JUSTOS ===${NC}"
    echo ""
    
    # Verifica se bc está disponível para cálculos
    if ! command -v bc &> /dev/null; then
        echo -e "${RED}❌ bc não encontrado.${NC}"
        read -p "Deseja instalar o pacote 'bc'? [s/N]: " user_input
        if [[ "$user_input" =~ ^[sS](im)?$ ]]; then
            echo -e "${YELLOW}Instalando 'bc'...${NC}"
            sudo apt-get update && sudo apt-get install -y bc
        else
            echo -e "${RED}Instalação de 'bc' cancelada. O script não pode continuar.${NC}"
            exit 1
        fi
    fi
    
    # Verifica dependências
    check_offload_status
    
    # Inicializa arquivo de resultados
    echo "Teste;Tempo_Total_Segundos" > test_results.csv
    
    echo -e "${YELLOW}===========================================${NC}"
    echo -e "${YELLOW}TESTE 1: DOCKER LOCAL (SEM OFFLOAD)${NC}"
    echo -e "${YELLOW}===========================================${NC}"
    
    # Limpeza inicial
    cleanup_all
    
    # Desabilita offload para teste local
    disable_offload
    
    # Executa teste local
    run_test "Docker_Local" "Execução local sem cache, build completo"
    
    echo -e "${YELLOW}===========================================${NC}"
    echo -e "${YELLOW}TESTE 2: DOCKER OFFLOAD (CLOUD)${NC}"
    echo -e "${YELLOW}===========================================${NC}"
    
    # Limpeza entre testes
    cleanup_all
    
    # Habilita offload para teste cloud
    enable_offload
    
    # Executa teste cloud
    run_test "Docker_Offload" "Execução cloud sem cache, build completo"
    
    # Restaura contexto padrão
    disable_offload
    
    echo -e "${GREEN}=== TESTES CONCLUÍDOS ===${NC}"
    echo ""
    
    # Gera relatório
    generate_report
}

# Função para gerar relatório final
generate_report() {
    echo -e "${BLUE}📊 Gerando relatório dos resultados...${NC}"
    
    if [ -f "test_results.csv" ]; then
        echo ""
        echo -e "${YELLOW}=== RESULTADOS FINAIS ===${NC}"
        echo ""
        
        # Lê resultados
        local_time=$(grep "Docker_Local" test_results.csv | cut -d';' -f2)
        offload_time=$(grep "Docker_Offload" test_results.csv | cut -d';' -f2)
        
        echo -e "${BLUE}Docker Local (sem cache):${NC} ${local_time}s"
        echo -e "${BLUE}Docker Offload (sem cache):${NC} ${offload_time}s"
        echo ""
        
        # Calcula diferença percentual
        if [ -n "$local_time" ] && [ -n "$offload_time" ]; then
            diff=$(echo "scale=2; (($local_time - $offload_time) / $local_time) * 100" | bc -l)
            abs_diff=$(echo "scale=2; sqrt($diff * $diff)" | bc -l)
    
            if (( $(echo "$offload_time < $local_time" | bc -l) )); then
                echo -e "${GREEN}🎉 Docker Offload foi ${abs_diff}% mais rápido!${NC}"
            else
                echo -e "${RED}Docker Local foi ${abs_diff}% mais rápido!${NC}"
            fi
        fi
        
        echo ""
        echo -e "${YELLOW}📁 Resultados salvos em: test_results.csv${NC}"
        echo -e "${YELLOW}📋 Para análise detalhada, consulte: resultados_performance.md${NC}"
    else
        echo -e "${RED}❌ Arquivo de resultados não encontrado${NC}"
    fi
}

# Executa função principal
main "$@"
