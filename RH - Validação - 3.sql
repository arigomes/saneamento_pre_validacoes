-- VALIDAÇÃO 3
-- Licença prêmio no cadastro de matrícula - Não pode ser incluída uma configuração com data anterior à data de admissão da matrícula

select licencas_premio_per.i_entidades,
       licencas_premio_per.i_funcionarios,
       funcionarios.dt_admissao,
       licencas_premio_per.dt_inicial,
       licencas_premio_per.dt_final
  from bethadba.licencas_premio
 inner join bethadba.licencas_premio_per
    on licencas_premio.i_entidades = licencas_premio_per.i_entidades
   and licencas_premio.i_licencas_premio = licencas_premio_per.i_licencas_premio
   and licencas_premio.i_funcionarios  = licencas_premio_per.i_funcionarios
 inner join bethadba.funcionarios 
    on licencas_premio.i_entidades = funcionarios.i_entidades
   and licencas_premio.i_funcionarios  = funcionarios.i_funcionarios
 where funcionarios.dt_admissao > licencas_premio_per.dt_inicial;


-- CORREÇÃO

