-- VALIDAÇÃO 137
-- Verifica os funcionarios que não contém rescisão

select fpa.i_entidades,
       fpa.i_funcionarios
  from bethadba.funcionarios_prop_adic fpa
 where fpa.i_caracteristicas = 20369
   and fpa.valor_caracter = '2'
   and fpa.i_funcionarios not in (select i_funcionarios
                                    from bethadba.beneficiarios)
 order by fpa.i_funcionarios;


-- CORREÇÃO
-- Altera o valor do campo valor_caracter para '0' para os funcionários que não são beneficiários e que possuem o valor '2' na característica 20369

update bethadba.funcionarios_prop_adic
   set valor_caracter = '0'
 where i_caracteristicas = 20369
   and valor_caracter = '2'
   and i_funcionarios not in (select i_funcionarios
                                from bethadba.beneficiarios);