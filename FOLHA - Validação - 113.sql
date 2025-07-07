/*
 -- VALIDAÇÃO 113
 * Verifica os afastamentos concomitantes com ferias do funcionario
 */

select 
                a.i_funcionarios,
                a.dt_inicial, b.dt_afastamento, b.dt_ultimo_dia  from bethadba.faltas a 
join bethadba.afastamentos b on a.i_funcionarios = b.i_funcionarios 
                where a.dt_inicial  between b.dt_afastamento  and b.dt_ultimo_dia
                and a.i_entidades = b.i_entidades 
          
/*
 -- CORREÇÃO
 */
                
begin                
update bethadba.faltas a
join bethadba.afastamentos b on (a.i_funcionarios = b.i_funcionarios and a.i_entidades = b.i_entidades)
set b.dt_afastamento  = dateadd(dd, 1, a.dt_inicial)
where a.dt_inicial  between b.dt_afastamento  and b.dt_ultimo_dia
and i_faltas = 1

update bethadba.faltas a 
join bethadba.afastamentos b on (a.i_funcionarios = b.i_funcionarios and a.i_entidades = b.i_entidades)
set b.dt_afastamento  = dateadd(dd, 1, a.dt_inicial)
where a.dt_inicial  between b.dt_afastamento  and b.dt_ultimo_dia
and i_faltas = 1

update bethadba.faltas a 
join bethadba.afastamentos b on (a.i_funcionarios = b.i_funcionarios and a.i_entidades = b.i_entidades)
set b.dt_afastamento  = dateadd(mm, 1, a.dt_inicial)
where a.dt_inicial  between b.dt_afastamento  and b.dt_ultimo_dia
and i_faltas = 1
end;
           