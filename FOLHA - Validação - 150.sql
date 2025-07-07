/*
 -- VALIDAÇÃO 150
 * Pensionistas sem cessação
 */

select f.i_entidades, 
          f.i_funcionarios,
          b.i_entidades_inst,
          b.i_instituidor,
          f.tipo_pens
        from bethadba.funcionarios f 
        join bethadba.beneficiarios b on f.i_entidades = b.i_entidades and f.i_funcionarios = b.i_funcionarios 
        where f.i_entidades in (1,2,3,4)
        and f.tipo_func = 'B' 
        and f.tipo_pens = 1
        and exists (select 1 from bethadba.rescisoes r 
                join bethadba.motivos_apos ma on r.i_motivos_apos = ma.i_motivos_apos 
                    join bethadba.tipos_afast ta on ma.i_tipos_afast = ta.i_tipos_afast
                    where r.i_entidades = b.i_entidades_inst 
                    and r.i_funcionarios = b.i_instituidor
                    and r.i_motivos_apos is not null and r.dt_canc_resc is null
                    and ta.classif = 9)
        and not exists (select 1
                             from bethadba.rescisoes resc 
                             join bethadba.motivos_resc mot on (resc.i_motivos_resc = mot.i_motivos_resc)
                        where resc.i_entidades = b.i_entidades_inst 
                        and resc.i_funcionarios = b.i_instituidor 
                        and mot.dispensados = 4                                
                        and resc.dt_canc_resc is null)
       order by 1,2 asc

/*
 -- CORREÇÃO
 */

update bethadba.rescisoes
set i_motivos_resc = /* INSERIR MOTIVO DE MORTE */
where i_funcionarios = /* INSERIR MATRICULA DO INSTITUIDOR */ and i_entidades = 

