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
 
update bethadba.pessoas_fisicas pf1
   set rg = null
 where rg is not null
   and pf1.i_pessoas <> (select min(pf2.i_pessoas)
                           from bethadba.pessoas_fisicas pf2
                          where pf2.rg = pf1.rg);