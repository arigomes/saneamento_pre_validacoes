import os

# Caminho da pasta onde estão os arquivos .sql
pasta = r'c:\Scripts\saneamento_pre_validacoes'
pastaSalvar = r'c:\Scripts\saneamento_pre_validacoes\arquivos'

# Prefixos desejados
prefixos = ["FOLHA - Validação"]

# Nome do arquivo de saída
arquivo_saida = os.path.join(pastaSalvar, "unificado_validacoes_folha.sql")

# Lista todos os arquivos .sql que começam com os prefixos desejados
arquivos = [f for f in os.listdir(pasta)
            if f.endswith('.sql') and any(f.startswith(pref) for pref in prefixos)]

# Ordena os arquivos por nome (opcional)
arquivos.sort()

with open(arquivo_saida, 'w', encoding='utf-8') as fout:
    for arquivo in arquivos:
        prefixo = next((pref for pref in prefixos if arquivo.startswith(pref)), None)
        if prefixo:
            fout.write(f"-- {prefixo}: {arquivo}\n\n")
        with open(os.path.join(pasta, arquivo), encoding='utf-8') as fin:
            fout.write(fin.read())
            fout.write('\n\n-- FIM DO ARQUIVO {}\n\n'.format(arquivo))

print(f"Arquivo unificado gerado em: {arquivo_saida}")