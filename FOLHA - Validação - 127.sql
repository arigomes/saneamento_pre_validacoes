/*
 -- VALIDAÇÃO 127
 * Configuração Rais sem controle de ponto
 */

select rc.campo from bethadba.rais_campos rc
where exists (select 1 from bethadba.rais_eventos re where re.campo = rc.campo)
and rc.cnpj is null

/*
 -- CORREÇÃO
 */

update bethadba.bethadba.rais_campos
set CNPJ = 0
where CNPJ is null 
   
