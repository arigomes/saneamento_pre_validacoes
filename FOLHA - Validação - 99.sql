/*
 * VALIDAÇÃO 99
 * Configuração do organograma sem niveis
 */

select i_config_organ,
nivel_unid
from bethadba.config_organ co 
where nivel_unid is null;

/*
 * CORREÇÃO
 */


update bethadba.config_organ
    set nivel_unid = 1
    where nivel_unid is null;
