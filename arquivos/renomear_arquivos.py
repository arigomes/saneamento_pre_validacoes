import os
import re

# Caminho da pasta atual
pasta = os.getcwd()

for nome_arquivo in os.listdir(pasta):
    # Verifica se o arquivo começa com "Validação"
    if nome_arquivo.startswith("Validação"):
        # Expressão regular para capturar o número após "Validação"
        match = re.match(r"Validação\s*(\d+)(.*)", nome_arquivo)
        if match:
            numero = match.group(1)
            resto = match.group(2)
            novo_nome = f"FOLHA - Validação - {numero}{resto}"
            # Renomeia o arquivo
            os.rename(
                os.path.join(pasta, nome_arquivo),
                os.path.join(pasta, novo_nome)
            )
            print(f'Renomeado: {nome_arquivo} -> {novo_nome}')