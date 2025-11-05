-- VALIDAÇÃO 19
-- Verifica se idade_ini e idade_fin estão vazios - Faltam dados nas colunas idade_ini e idade_fin na tabela planos_saude_tabelas_faixas. É necessário ter os dados preenchidos

select *
  from bethadba.planos_saude_tabelas_faixas
 where idade_ini is null
    or idade_fin is null;


-- CORREÇÃO
-- Atualizar os registros na tabela planos_saude_tabelas_faixas para preencher idade_ini e idade_fin com valores padrão, se necessário.

update bethadba.planos_saude_tabelas_faixas
   set idade_ini = 0, idade_fin = 100
 where idade_ini is null
    or idade_fin is null;