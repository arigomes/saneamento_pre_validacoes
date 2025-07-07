/*
 -- VALIDAÇÃO 163
 * Processo trabalhista nao contém pagamento de encargo
 */

select pj.i_entidades,
                pj.i_funcionarios,
                pj.i_processos_judiciais
          from bethadba.processos_judiciais pj
          where pj.i_funcionarios not in (select i_funcionarios from bethadba.processos_judic_pagamentos_encargos)

/*
 -- CORREÇÃO
 */

/* REALIZAR update PARA INSERIR UM VALOR NO vlr_prev_oficial */
update bethadba.processos_judic_compet
set vlr_prev_oficial = 1

/* insert PARA O RELACIONAMENTO */
insert into bethadba.processos_judic_pagamentos_det (i_entidades, i_funcionarios, i_processos_judiciais, i_competencias, i_tipos_proc, data_referencia)
select pj.i_entidades,
                pj.i_funcionarios,
                pj.i_processos_judiciais,
                pj.dt_final,
                11,
                pj.dt_final
          from bethadba.processos_judiciais pj
          where pj.i_funcionarios not in (select i_funcionarios from bethadba.processos_judic_pagamentos_encargos)
                  
/* insert PARA TODOS PÓS as RELAÇÕES */
insert into bethadba.processos_judic_pagamentos_encargos (i_entidades, i_funcionarios, i_processos_judiciais, i_competencias, i_tipos_proc, data_referencia, i_receitas ,aliquota,valor_inss)
select 1,
                pj.i_funcionarios,
                pj.i_processos_judiciais,
                pj.dt_final,
                11,
                pj.dt_final,
                113851,
                null,
                null
          from bethadba.processos_judiciais pj
          where pj.i_funcionarios not in (select i_funcionarios from bethadba.processos_judic_pagamentos_encargos)
          
          