-- VALIDAÇÃO 174
-- Quantidades de digitos menores a configuração

select o.i_config_organ,
       o.i_organogramas,
       o.descricao,
       nivel_maximo = (select max(no2.i_niveis_organ)
                         from bethadba.niveis_organ as no2
                        where no2.i_config_organ = o.i_config_organ), 
       total_digitos = (select no2.tot_digitos
                          from bethadba.niveis_organ as no2
                         where no2.i_config_organ = o.i_config_organ
                           and no2.i_niveis_organ = nivel_maximo),
       total_digito_org = length(o.i_organogramas)                        
  from bethadba.organogramas as o
 where total_digito_org < total_digitos
    or total_digito_org > total_digitos;


-- CORREÇÃO

