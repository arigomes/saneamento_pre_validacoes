import os
import re

# Caminho da pasta atual
pasta = os.getcwd()

for nome_arquivo in os.listdir(pasta):
    if nome_arquivo.endswith('.sql'):
        caminho_arquivo = os.path.join(pasta, nome_arquivo)
        with open(caminho_arquivo, 'r', encoding='latin1') as f:
            conteudo = f.read()
        # Substituições
        conteudo = re.sub(r'VALIDA��O', 'VALIDAÇÃO', conteudo)
        conteudo = re.sub(r'CORRE��O', 'CORREÇÃO', conteudo)
        with open(caminho_arquivo, 'w', encoding='latin1') as f:
            f.write(conteudo)
        print(f'Atualizado: {nome_arquivo}')