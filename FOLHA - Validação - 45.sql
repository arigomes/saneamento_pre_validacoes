-- VALIDAÇÃO 45
-- Verifica os funcionários sem previdência

select hf.i_entidades ,
       hf.i_funcionarios                
  from bethadba.hist_funcionarios hf
 inner join bethadba.funcionarios f
    on f.i_funcionarios = hf.i_funcionarios
   and f.i_entidades = hf.i_entidades
 inner join bethadba.rescisoes r
    on r.i_funcionarios = hf.i_funcionarios
   and r.i_entidades = hf.i_entidades
 inner join bethadba.vinculos v
    on v.i_vinculos = hf.i_vinculos
 where hf.prev_federal = 'N'
   and hf.prev_estadual = 'N'
   and hf.fundo_ass = 'N'
   and hf.fundo_prev = 'N'
   and hf.fundo_financ = 'N'
   and f.tipo_func = 'F'
   and r.i_motivos_resc not in (8)
   and v.categoria_esocial <> '901'
 group by hf.i_funcionarios, hf.i_entidades
 order by hf.i_entidades, hf.i_funcionarios;


-- CORREÇÃO
-- Altera a previdência federal para 'Sim' quando o histórico da matrícula não possuí nenhuma previdência marcada

update bethadba.hist_funcionarios hf
   set hf.prev_federal = 'S'
  from bethadba.funcionarios f,
       bethadba.rescisoes r,
       bethadba.vinculos v
 where f.i_funcionarios = hf.i_funcionarios
   and f.i_entidades = hf.i_entidades
   and r.i_funcionarios = hf.i_funcionarios
   and r.i_entidades = hf.i_entidades
   and v.i_vinculos = hf.i_vinculos
   and coalesce(hf.prev_federal, 'N') = 'N'
   and coalesce(hf.prev_estadual, 'N') = 'N'
   and coalesce(hf.fundo_ass, 'N') = 'N'
   and coalesce(hf.fundo_prev, 'N') = 'N'
   and coalesce(hf.fundo_financ, 'N') = 'N'
   and f.tipo_func = 'F'
   and r.i_motivos_resc not in (8)
   and v.categoria_esocial <> '901';
