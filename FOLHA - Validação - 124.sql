/*
 -- VALIDAÇÃO 124
 * Configuração Rais sem controle de ponto
 */

select i_entidades, i_parametros_rel from bethadba.parametros_rel
           where i_entidades in (1,2,3,4) and i_parametros_rel = 2 and mes_base is null

/*
 -- CORREÇÃO
 */

