import os

# Caminho da pasta atual
pasta = os.getcwd()

for nome_arquivo in os.listdir(pasta):
    if nome_arquivo.endswith('.txt'):
        novo_nome = nome_arquivo[:-4] + '.sql'
        os.rename(
            os.path.join(pasta, nome_arquivo),
            os.path.join(pasta, novo_nome)
        )
        print(f'Renomeado: {nome_arquivo} -> {novo_nome}')