-- VALIDAÇÃO 64
-- Campo observação nas características à maior que 150 caracteres 

select i_caracteristicas, 
       nome 
  from bethadba.caracteristicas 
 where length(observacao) > 150;


-- CORREÇÃO
-- Atualiza o campo observação das características para nulo quando maior que 150 caracteres

update bethadba.caracteristicas
   set observacao = null
 where length(observacao) > 150;