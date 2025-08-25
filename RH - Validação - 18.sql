-- VALIDAÇÃO 18
-- Verifica se há registro na tabela planos_saude_tabelas_faixas - A tabela planos_saude_tabelas_faixas está vazia. É necessário ter os dados preenchidos

select case 
        when exists (select 1
                       from bethadba.planos_saude) 
        then (select count(*)
                from bethadba.planos_saude_tabelas_faixas)
       end as total_registros;


-- CORREÇÃO
-- Inserir os dados na tabela planos_saude_tabelas_faixas

INSERT INTO bethadba.planos_saude_tabelas_faixas (i_pessoas,i_entidades,i_planos_saude,i_tabelas,i_sequencial,idade_ini,idade_fin,vlr_plano)
VALUES (1, 1, 1, 1, 1, 0, 17, 100.00);