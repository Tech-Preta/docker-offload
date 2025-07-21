# heavy_task.py
import time
import math
import os

def run_heavy_computation(iterations):
    start_time = time.time()
    result = 0.0
    sin_i, cos_i = 0.0, 1.0  # sin(0) = 0, cos(0) = 1
    sin_1, cos_1 = math.sin(1), math.cos(1)  # Precompute sin(1) and cos(1)
    for i in range(iterations):
        result += sin_i * cos_i / (math.sqrt(i + 1))
        # Update sin(i+1) and cos(i+1) using recurrence relations
        sin_i, cos_i = sin_i * cos_1 + cos_i * sin_1, cos_i * cos_1 - sin_i * sin_1
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
