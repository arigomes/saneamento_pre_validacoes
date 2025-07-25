/*
 -- VALIDA��O 171
 * afastament sem rescis�o ou data divergente da rescis�o com o afastamento.
 */

select a.i_entidades,
                 a.i_funcionarios,
                 a.dt_afastamento,
                 dt_rescisao = (select first r.dt_rescisao from bethadba.rescisoes r
                                 where r.dt_canc_resc is null
                                 and r.i_entidades = a.i_entidades
                                 and r.i_funcionarios = a.i_funcionarios
                                 and r.dt_rescisao = a.dt_afastamento )
            from bethadba.afastamentos a
            join bethadba.tipos_afast ta on a.i_tipos_afast = ta.i_tipos_afast
            where ta.classif = 8
            and a.dt_ultimo_dia is null
            and a.i_entidades in (1,2,3,4)
            and dt_rescisao is null
            order by i_funcionarios  asc
          
 /*
 -- CORRE��O
 */       

begin 
    
    declare w_i_funcionario integer;
    declare w_dt_afastamento timestamp;
    declare w_i_entidades integer;
    
llLoop: for ll as cur_01 dynamic scroll cursor for

    select a.i_entidades,
                 a.i_funcionarios,
                 a.dt_afastamento,
                 dt_rescisao = (select first r.dt_rescisao from bethadba.rescisoes r
                                 where r.dt_canc_resc is null
                                 and r.i_entidades = a.i_entidades
                                 and r.i_funcionarios = a.i_funcionarios
                                 and r.dt_rescisao = a.dt_afastamento )
            from bethadba.afastamentos a
            join bethadba.tipos_afast ta on a.i_tipos_afast = ta.i_tipos_afast
            where ta.classif = 8
            and a.dt_ultimo_dia is null
            and a.i_entidades in (1,2,3,4)
            and dt_rescisao is null
            order by i_funcionarios  asc
            
    do 
    
    set w_i_funcionario = i_funcionarios;
    set w_dt_afastamento = dt_afastamento;
    set w_i_entidades = i_entidades;
  
    update bethadba.rescisoes 
    set dt_rescisao = w_dt_afastamento
    where i_funcionarios = w_i_funcionario
    and i_entidades = w_i_entidades;
  
    //DEPOIS DESCOMENTAR as LINHAS A BAIXO E RODA-LAS

//insert into bethadba.rescisoes (i_entidades,i_funcionarios,i_rescisoes,i_motivos_resc,dt_rescisao,aviso_ind,vlr_saldo_fgts,fgts_mesant,compl_mensal,complementar,trab_dia_resc,proc_adm,deb_adm_pub,tipo_decisao,mensal,repor_vaga,aviso_desc,dt_chave_esocial)
//values (w_i_entidades, w_i_funcionario, 1, 15, w_dt_afastamento, 'N',0,'S','N','N','N','N','N','A','N','N','N',w_dt_afastamento);

end for;
end;