-- VALIDAÇÃO 19
-- Verifica se idade_ini e idade_fin estão vazios - Faltam dados nas colunas idade_ini e idade_fin na tabela planos_saude_tabelas_faixas. É necessário ter os dados preenchidos

select case 
        when count(*) > 0
        then (select count(*)
                from bethadba.planos_saude_tabelas_faixas) 
        else 1
       end total_registros
  from bethadba.planos_saude;


-- CORREÇÃO

