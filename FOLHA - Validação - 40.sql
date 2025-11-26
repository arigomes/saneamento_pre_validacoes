-- VALIDAÇÃO 40
-- Verifica os RG's repetidos

select list(i_pessoas) as pess,
       rg,
       count(rg) as quantidade
  from bethadba.pessoas_fisicas
 group by rg 
having quantidade > 1;


-- CORREÇÃO
-- Atualiza os RG's repetidos para nulo, evitando duplicidade
 
update bethadba.pessoas_fisicas
   set rg = null
 where rg is not null
   and i_pessoas <> (select min(pf2.i_pessoas)
                           from bethadba.pessoas_fisicas pf2
                          where pf2.rg = pessoas_fisicas.rg);

-- Ajusta os historicos para valores repetidos em diferentes pessoas
select list(distinct i_pessoas) as pess,
		count(distinct i_pessoas) as pessoas,
       rg,
       count(rg) as quantidade
  from bethadba.hist_pessoas_fis
 group by rg
having pessoas > 1;


update bethadba.hist_pessoas_fis
   set rg = null
 where rg is not null
   and i_pessoas <> (select min(pf2.i_pessoas)
                           from bethadba.hist_pessoas_fis pf2
                          where pf2.rg = hist_pessoas_fis.rg);