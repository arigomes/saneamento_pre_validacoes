/*
 -- VALIDAÇÃO 92
 * Funcionarios sem local de trabalho principal
 */

select 
               principal = if isnull(locais_mov.principal,'N') = 'S' then 'true' else 'false' endif,
               i_funcionarios func,
               count(principal) as total
          from bethadba.locais_mov
          where i_funcionarios = i_funcionarios 
          and i_entidades = i_entidades
          and principal = 'false'
          and i_funcionarios not in(
                                    select 
                                       lm.i_funcionarios      
                                  from bethadba.locais_mov lm
                                  where lm.i_funcionarios = locais_mov.i_funcionarios 
                                  and lm.i_entidades = locais_mov.i_entidades
                                  and lm.principal = 'S'                          
                                    )
          group by principal, i_funcionarios
          having total > 1
          order by locais_mov.i_funcionarios

/*
 -- CORREÇÃO
 */

update bethadba.locais_mov lm
set lm.principal = 'S'
where lm.i_funcionarios in (104,171,1268,1306,1329,1431,1436,1452,1453,1457,1552,1553,1557,1558,1676,1698,1699,1700,1701,1706) 
and lm.i_locais_trab  = (
    select max(i_locais_trab)
    from bethadba.locais_mov sub
    where sub.i_funcionarios = lm.i_funcionarios
    and i_entidades = 1
)
and i_entidades = 1;



select * from bethadba.locais_mov 
where i_funcionarios = 171

