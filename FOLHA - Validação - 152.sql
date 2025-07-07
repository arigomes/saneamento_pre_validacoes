/*
 -- VALIDAÇÃO 152
 * Instituidor sem afastamento
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
        and f.tipo_pens in (1,2)
        and exists (select 1 from bethadba.rescisoes r 
            join bethadba.motivos_apos ma on r.i_motivos_apos = ma.i_motivos_apos 
                join bethadba.tipos_afast ta on ma.i_tipos_afast = ta.i_tipos_afast
                        where r.i_entidades = b.i_entidades_inst and r.i_funcionarios = b.i_instituidor
                        and r.i_motivos_apos is not null and r.dt_canc_resc is null
                        and ta.classif = 9)
        and  not exists (select 1
                             from bethadba.afastamentos a
                             join bethadba.tipos_afast ta2 on a.i_tipos_afast = ta2.i_tipos_afast
                             where a.i_entidades = b.i_entidades_inst and a.i_funcionarios = b.i_instituidor
                             and ta2.classif = 9)
        order by 1,2 asc
/*
 -- CORREÇÃO
 */

 update bethadba.afastamentos
        set i_tipos_afast = 8
        where i_funcionarios in (select b.i_instituidor
        from bethadba.funcionarios f 
        join bethadba.beneficiarios b on f.i_entidades = b.i_entidades and f.i_funcionarios = b.i_funcionarios 
        where f.i_entidades in (1,2,3,4)
        and f.tipo_func = 'B' 
        and f.tipo_pens in (1,2)
        and exists (select 1 from bethadba.rescisoes r 
            join bethadba.motivos_apos ma on r.i_motivos_apos = ma.i_motivos_apos 
                join bethadba.tipos_afast ta on ma.i_tipos_afast = ta.i_tipos_afast
                        where r.i_entidades = b.i_entidades_inst and r.i_funcionarios = b.i_instituidor
                        and r.i_motivos_apos is not null and r.dt_canc_resc is null
                        and ta.classif = 9)
        and  not exists (select 1
                             from bethadba.afastamentos a
                             join bethadba.tipos_afast ta2 on a.i_tipos_afast = ta2.i_tipos_afast
                             where a.i_entidades = b.i_entidades_inst and a.i_funcionarios = b.i_instituidor
                             and ta2.classif = 9))
        and i_tipos_afast = 7
