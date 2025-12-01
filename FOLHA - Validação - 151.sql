-- VALIDAÇÃO 151
-- Pensionistas sem dependente

select f.i_funcionarios,
       b.i_instituidor,
       f.i_pessoas,
       pessoaInstituidor = (select f2.i_pessoas
                               from bethadba.funcionarios as f2 
                              where f2.i_entidades = b.i_entidades_inst
                                and f2.i_funcionarios = b.i_instituidor)
  from bethadba.funcionarios as f
  join bethadba.beneficiarios as b
    on f.i_entidades = b.i_entidades
   and f.i_funcionarios = b.i_funcionarios
 where f.tipo_func = 'B' 
   and f.tipo_pens in (1, 2)
   and not exists (select 1
                     from bethadba.dependentes as d
                    where d.i_pessoas = pessoaInstituidor
                      and d.i_dependentes = f.i_pessoas);


-- CORREÇÃO
-- Inserir a pessoa do pensionistas como dependente do instituidor

insert into bethadba.dependentes (i_pessoas,i_dependentes,grau,dt_ini_depende,mot_ini_depende)
select pessoaInstituidor = (select f2.i_pessoas
                               from bethadba.funcionarios as f2 
                              where f2.i_entidades = b.i_entidades_inst
                                and f2.i_funcionarios = b.i_instituidor),
        f.i_pessoas,
        10 as grau,      
       	f.dt_admissao,
       	0
  from bethadba.funcionarios as f
  join bethadba.beneficiarios as b
    on f.i_entidades = b.i_entidades
   and f.i_funcionarios = b.i_funcionarios
 where f.tipo_func = 'B' 
   and f.tipo_pens in (1, 2)
   and not exists (select 1
                     from bethadba.dependentes as d
                    where d.i_pessoas = pessoaInstituidor
                      and d.i_dependentes = f.i_pessoas);