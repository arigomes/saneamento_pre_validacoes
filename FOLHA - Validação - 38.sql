-- VALIDAÇÃO 38
-- Verifica descrição de configuração de organograma se é maior que 30 caracteres

select i_config_organ,
       descricao,
       length(descricao) as tamanho 
  from bethadba.config_organ
 where tamanho > 30;


-- CORREÇÃO

update bethadba.config_organ 
   set descricao = replace(descricao, 'Entidade', 'Ent')
 where length(descricao) > 30;