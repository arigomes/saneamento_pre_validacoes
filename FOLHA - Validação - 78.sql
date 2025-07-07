-- VALIDAÇÃO 78
-- Tipo de afastamento deve possuir movimentação de pessoal quando possuir um ato

select afastamentos.i_entidades entidade,
       afastamentos.i_funcionarios func, 
       afastamentos.dt_afastamento dt_afast, 
       afastamentos.i_tipos_afast tp_afast
  from bethadba.afastamentos, bethadba.tipos_afast
 where afastamentos.i_tipos_afast = tipos_afast.i_tipos_afast
   and afastamentos.i_atos is not null
   and tipos_afast.i_tipos_movpes is null
   and tipos_afast.i_tipos_afast <> 7
 order by afastamentos.i_entidades,
          afastamentos.i_funcionarios, 
          afastamentos.dt_afastamento;


-- CORREÇÃO
-- Atualiza os tipos de afastamento para que possuam movimentação de pessoal

update bethadba.tipos_afast 
   set i_tipos_movpes = 60
 where i_tipos_afast in (13, 30, 33, 9, 12, 25);

update bethadba.tipos_afast 
   set i_tipos_movpes = 34
 where i_tipos_afast = 32;

update bethadba.tipos_afast 
   set i_tipos_movpes = 67
 where i_tipos_afast = 24;

update bethadba.tipos_afast 
   set i_tipos_movpes = 36
 where i_tipos_afast = 15;