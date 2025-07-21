# Dockerfile para testes justos de performance
FROM python:3.9-slim-buster

# Desabilita cache de pip para builds determinísticos
ENV PIP_NO_CACHE_DIR=1

# Define diretório de trabalho
WORKDIR /app

# Copia script de teste
COPY heavy_task.py .

# Define número de iterações padrão
ENV ITERATIONS="100000000"

# Adiciona label para identificação em limpezas
LABEL project="docker-offload-tests"

# Comando de execução
CMD ["python", "heavy_task.py"]
