-- VALIDAÇÃO 18
-- Verifica se há registro na tabela planos_saude_tabelas_faixas - A tabela planos_saude_tabelas_faixas está vazia. É necessário ter os dados preenchidos

select case 
        when exists (select 1
                       from bethadba.planos_saude) 
        then (select count(*)
                from bethadba.planos_saude_tabelas_faixas) 
        else 1 
       end as total_registros;


-- CORREÇÃO

