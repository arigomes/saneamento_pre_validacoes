-- VALIDAÇÃO 115
-- Verifica os funcionarios sem historico de funcionarios

select distinct i_funcionarios 
  from bethadba.funcionarios
 where i_funcionarios not in (select i_funcionarios
                                from bethadba.hist_funcionarios);


-- CORREÇÃO
-- Insere o histórico de funcionários para os funcionários que não possuem histórico, utilizando os dados atuais dos funcionários

insert into bethadba.hist_funcionarios(i_entidades,i_funcionarios,dt_alteracoes,i_config_organ,i_organogramas,i_grupos,i_vinculos,i_pessoas,i_bancos,i_agencias,i_pessoas_contas,i_horarios,
func_princ,i_agentes_nocivos,optante_fgts,prev_federal,prev_estadual,fundo_ass,fundo_prev,ocorrencia_sefip,forma_pagto,multiplic,tipo_contrato,fundo_financ,remunerado_cargo_efetivo,
i_turmas,num_quadro_cp,num_cp,provisorio,bate_cartao,i_pessoas_estagio,dt_final_estagio,nivel_curso_estagio,num_apolice_estagio,estagio_obrigatorio_estagio,i_agente_integracao_estagio,
i_supervisor_estagio,controle_jornada,grau_exposicao,tipo_admissao,tipo_trabalhador,i_sindicatos,seguro_vida_estagio,categoria,desc_salario_variavel,duracao_ben,dt_vencto,tipo_beneficio,
i_responsaveis,tipo_ingresso,aposentado,recebe_abono)
select a.i_entidades,
       a.i_funcionarios,
       a.dt_admissao as dt_alteracoes,
       1 as i_config_organ,
       '0101' as i_organogramas,
       1 as i_grupos,
       5 as i_vinculos,
       a.i_pessoas,
       null as i_bancos,
       null as i_agencias,
       null as i_pessoas_contas,
       null as i_horarios,
       null as func_princ,
       null as i_agentes_nocivos,
       'N' as optante_fgts,
       'S' as prev_federal,
       'N' as prev_estadual,
       'N' as fundo_ass,
       'N' as fundo_prev,
       0 as ocorrencia_sefip,
       'R' as forma_pagto,
       1 as multiplic,
       null as tipo_contrato,
       'N' as fundo_financ,
       'N' as remunerado_cargo_efetivo,
       null as i_turmas,
       null as num_quadro_cp,
       null as num_cp,
       null as provisorio,
       null as bate_cartao,
       null as i_pessoas_estagio,
       null as dt_final_estagio,
       null as nivel_curso_estagio,
       null as num_apolice_estagio,
       null as estagio_obrigatorio_estagio,
       null as i_agente_integracao_estagio,
       null as i_supervisor_estagio,
       null as controle_jornada,
       null as grau_exposicao,
       null as tipo_admissao,
       null as tipo_trabalhador,
       null as i_sindicatos,
       null as seguro_vida_estagio,
       'M' as categoria,
       null as desc_salario_variavel,
       null as duracao_ben,
       null as dt_vencto,
       null as tipo_beneficio,
       null as i_responsaveis,
       null as tipo_ingresso,
       null as aposentado,
       null as recebe_abono
  from bethadba.funcionarios a
 where i_funcionarios in (select z.i_funcionarios
                            from bethadba.funcionarios z
                           where i_funcionarios not in (select i_funcionarios
                                                          from bethadba.hist_funcionarios));