import os
import re

# Lista das palavras-chave SQL a serem convertidas para minúsculas
sql_keywords = [
    'SELECT', 'FROM', 'WHERE', 'UPDATE', 'SET', 'AND', 'OR', 'NOT', 'NULL',
    'INSERT', 'INTO', 'VALUES', 'DELETE', 'JOIN', 'LEFT', 'RIGHT', 'INNER',
    'OUTER', 'ON', 'AS', 'ORDER', 'BY', 'GROUP', 'HAVING', 'DISTINCT', 'CREATE',
    'TABLE', 'ALTER', 'DROP', 'PRIMARY', 'KEY', 'FOREIGN', 'REFERENCES', 'IN',
    'IS', 'EXISTS', 'BETWEEN', 'LIKE', 'UNION', 'ALL', 'CASE', 'WHEN', 'THEN',
    'ELSE', 'END', 'LIMIT', 'OFFSET', 'TOP', 'LENGTH', 'COUNT', 'AVG',
    'SUM', 'MIN', 'MAX', 'CAST', 'CONVERT', 'TRIM', 'SUBSTRING',
    'COALESCE', 'IF', 'ELSEIF', 'BEGIN', 'END', 'TRANSACTION', 'COMMIT',
    'ROLLBACK', 'SAVEPOINT', 'GRANT', 'REVOKE', 'INDEX', 'VIEW', 'PROCEDURE',
    'FUNCTION', 'TRIGGER', 'SCHEMA', 'DATABASE', 'USE', 'ALTER', 'RENAME',
    'EXPLAIN', 'ANALYZE', 'WITH', 'CTE', 'TEMPORARY', 'TEMP', 'UNIQUE',
    'CHECK', 'DEFAULT', 'AUTO_INCREMENT', 'SERIAL', 'BIGINT', 'INT', 'INTEGER',
    'SMALLINT', 'TINYINT', 'FLOAT', 'DOUBLE', 'DECIMAL', 'NUMERIC',
    'CHAR', 'VARCHAR', 'TEXT', 'BLOB', 'DATE', 'TIME', 'DATETIME', 'TIMESTAMP',
    'YEAR', 'BOOLEAN', 'BIT', 'JSON', 'XML', 'ARRAY', 'ENUM', 'SET',
    'PARTITION', 'CLUSTERED', 'NONCLUSTERED', 'WITHIN', 'ROLLUP', 'CUBE',
    'PARTITION BY', 'ORDER BY', 'FETCH FIRST', 'FETCH NEXT', 'ROW_NUMBER',
    'RANK', 'DENSE_RANK', 'NTILE', 'OVER', 'WINDOW', 'PIVOT', 'UNPIVOT',
    'MERGE', 'UPSERT', 'EXISTS', 'ANY', 'SOME', 'ALL', 'VALUES', 'FETCH',
    'OFFSET', 'FOR', 'NOLOCK', 'READONLY', 'WITH (NOLOCK)', 'WITH (READUNCOMMITTED)',
    'WITH (READCOMMITTED)', 'WITH (REPEATABLE READ)', 'WITH (SERIALIZABLE)',
    'WITH (SNAPSHOT)', 'WITH (ROWLOCK)', 'WITH (PAGELOCK)', 'WITH (TABLOCK)',
    'WITH (TABLOCKX)', 'WITH (HOLDLOCK)', 'WITH (UPDLOCK)', 'WITH (XLOCK)',
    'WITH (READPAST)', 'WITH (READCOMMITTEDLOCK)', 'WITH (REPEATABLE READLOCK)'
]

# Regex para encontrar as palavras-chave, ignorando o case
pattern = re.compile(r'\b(' + '|'.join(sql_keywords) + r')\b', re.IGNORECASE)

# Caminho da pasta atual
pasta = os.getcwd()

for nome_arquivo in os.listdir(pasta):
    if nome_arquivo.endswith('.sql'):
        caminho_arquivo = os.path.join(pasta, nome_arquivo)
        with open(caminho_arquivo, 'r', encoding='latin1') as f:
            conteudo = f.read()
        # Substitui as palavras-chave por minúsculas
        novo_conteudo = pattern.sub(lambda m: m.group(0).lower(), conteudo)
        with open(caminho_arquivo, 'w', encoding='latin1') as f:
            f.write(novo_conteudo)
        print(f'Atualizado: {nome_arquivo}')