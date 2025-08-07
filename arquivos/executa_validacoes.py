import os
import pyodbc

# Configuração da conexão para Sybase (ajuste conforme necessário)
conn = pyodbc.connect(r"FILEDSN=c:\Scripts\saneamento_pre_validacoes\conexao.dsn")

cursor = conn.cursor()

pasta = r'c:\Scripts\saneamento_pre_validacoes'
arquivos_sql = [f for f in os.listdir(pasta) if f.endswith('.sql')]

for arquivo in arquivos_sql:
    with open(os.path.join(pasta, arquivo), encoding='utf-8') as f:
        conteudo = f.read()

    # Separar o SELECT e o script de correção (assumindo padrão do seu exemplo)
    partes = conteudo.split('-- CORREÇÃO')
    if len(partes) < 2:
        continue  # pula arquivos sem padrão esperado

    # Pega o primeiro SELECT antes do primeiro ';'
    select_sql = ''
    for linha in partes[0].splitlines():
        if linha.strip().lower().startswith('select'):
            select_sql = linha
            break
    if not select_sql:
        continue

    correcao_sql = partes[1].strip()

    try:
        cursor.execute(select_sql)
        resultado = cursor.fetchall()
        if resultado:
            # Salva o script de correção em um arquivo
            nome_saida = f'correcao_{arquivo}'
            with open(os.path.join(pasta, nome_saida), 'w', encoding='utf-8') as fout:
                fout.write(correcao_sql)
            print(f"Correção salva para {arquivo}")
    except Exception as e:
        print(f"Erro ao processar {arquivo}: {e}")

cursor.close()
conn.close()