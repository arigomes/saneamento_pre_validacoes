/*
 -- VALIDAÇÃO 131
 * Data de alteração do histórico não pode ser menor que a data de nascimento
 */

select i_pessoas from bethadba.hist_pessoas_fis where dt_nascimento > dt_alteracoes
          
/*
 -- CORREÇÃO
 */
                
update bethadba.hist_pessoas_fis
set dt_alteracoes = DATEADD(year, 18, dt_nascimento)
where dt_nascimento > dt_alteracoes;
