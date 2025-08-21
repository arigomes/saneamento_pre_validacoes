-- VALIDAÇÃO 20
-- Verifica se há ausências concomitantes

select a1.i_funcionarios,
	   a1.dt_ausencia,
	   a1.dt_ultimo_dia,
	   a2.dt_ausencia as dt_ausencia_concomitante,
	   a2.dt_ultimo_dia as dt_ultimo_dia_concomitante
  from bethadba.ausencias a1
  join bethadba.ausencias a2
    on a1.i_funcionarios = a2.i_funcionarios
   and a1.i_entidades = a2.i_entidades
 where (a1.dt_ausencia between dt_ausencia_concomitante and dt_ultimo_dia_concomitante or a1.dt_ultimo_dia between dt_ausencia_concomitante and dt_ultimo_dia_concomitante)
   and (a1.dt_ausencia <> dt_ausencia_concomitante or a1.dt_ultimo_dia <> dt_ultimo_dia_concomitante)
 order by a1.i_funcionarios, a1.dt_ausencia;


-- CORREÇÃO
-- Ajustar as datas de ausência para evitar sobreposição

update bethadba.ausencias a1
   set a1.dt_ultimo_dia = coalesce(dateadd(day, -1, a2.dt_ausencia), a1.dt_ultimo_dia)
  from bethadba.ausencias a2
 where (a1.dt_ausencia between a2.dt_ausencia and a2.dt_ultimo_dia or a1.dt_ultimo_dia between a2.dt_ausencia and a2.dt_ultimo_dia)
   and (a1.dt_ausencia <> a2.dt_ausencia or a1.dt_ultimo_dia <> a2.dt_ultimo_dia)
   and a1.i_funcionarios = a2.i_funcionarios
   and a1.i_entidades = a2.i_entidades;