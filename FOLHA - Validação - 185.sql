-- VALIDAÇÃO 185
-- Descrição de tipos de cargos duplicadas

select a.i_tipos_cargos,
       a.descricao
  from bethadba.tipos_cargos as a
 where exists(select first 1
 				from bethadba.tipos_cargos as b
               where b.descricao = a.descricao
                 and b.i_tipos_cargos <> a.i_tipos_cargos);


-- CORREÇÃO

update bethadba.tipos_cargos
   set descricao = i_tipos_cargos || descricao
 where i_tipos_cargos = 9;