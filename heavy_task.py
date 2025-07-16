# heavy_task.py
import time
import math
import os

def run_heavy_computation(iterations):
    start_time = time.time()
    result = 0.0
    for i in range(iterations):
        result += math.sin(i) * math.cos(i) / (math.sqrt(i + 1))
    end_time = time.time()
    return end_time - start_time, result

if __name__ == "__main__":
    # Ajuste o número de iterações para simular uma carga maior ou menor
    # Quanto maior, mais tempo vai levar e a diferença será mais perceptível
    # Em uma máquina média, 100_000_000 já deve ser um bom ponto de partida.
    num_iterations = int(os.environ.get("ITERATIONS", "100000000"))

    print(f"Iniciando tarefa computacional pesada com {num_iterations:,} iterações...")
    duration, final_result = run_heavy_computation(num_iterations)
    print(f"Tarefa concluída em {duration:.4f} segundos.")
    print(f"Resultado final (apenas para evitar otimização do compilador): {final_result}")
    print(f"Executado em: {'Nuvem (Docker Offload)' if os.environ.get('DOCKER_OFFLOAD_ACTIVE') else 'Local'}")
