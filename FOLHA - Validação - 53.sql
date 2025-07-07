-- VALIDAçãO 53
-- Verifica a data inicial de benefÍcio do dependente se é maior que a do titular

select fps.i_entidades,
       fps.i_funcionarios,
       fps.i_pessoas,
       fps.i_sequenciais,
       vigencia_inicial as vigencia_inicial_dependente,
       vigencia_inicial_titular = (select max(vigencia_inicial)
                                     from bethadba.func_planos_saude
                                    where i_sequenciais = 1
                                      and i_funcionarios = fps.i_funcionarios)
  from bethadba.func_planos_saude as fps 
 where fps.i_sequenciais != 1
   and  fps.vigencia_inicial < vigencia_inicial_titular
   and fps.i_pessoas = i_pessoas;


-- CORREÇÃO
-- Atualiza a data de vigência inicial do plano de saúde do dependente para a mesma data do titular
-- Isso garante que a data de vigência inicial do dependente não seja anterior à do titular

update bethadba.func_planos_saude as fp
   set fp.vigencia_inicial = plano_saude.vigencia_inicial_titular
  from (select fps.i_entidades,
               fps.i_funcionarios,
               fps.i_pessoas,
               fps.i_sequenciais,
               vigencia_inicial as vigencia_inicial_dependente,
               vigencia_inicial_titular = (select vigencia_inicial
                                             from bethadba.func_planos_saude
                                            where i_sequenciais = 1
                                              and i_funcionarios = fps.i_funcionarios)
          from bethadba.func_planos_saude as fps 
         where fps.i_sequenciais != 1
           and fps.vigencia_inicial < vigencia_inicial_titular) as plano_saude
 where fp.i_entidades = plano_saude.i_entidades
   and fp.i_funcionarios = plano_saude.i_funcionarios
   and fp.i_pessoas = plano_saude.i_pessoas
   and fp.i_sequenciais = plano_saude.i_sequenciais;