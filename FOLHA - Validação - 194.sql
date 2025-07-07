-- VALIDAÇÃO 194
-- Configuração sem responsável

select pr.i_entidades,
       pr.i_parametros_rel,
       tipoInscricao = tipo_insc,
       nome = isnull(nome_resp,''),
       pessoaJuridicaAx = isnull((select first i_pessoas
                                    from bethadba.pessoas
                                   where SIMILAR(nome,nome_resp) >= 80),0),
       pessoaFisicaAx = isnull((select first i_pessoas
                                  from bethadba.pessoas
                                 where SIMILAR(nome,nome_resp) >= 80),0)
  from bethadba.parametros_rel as pr
 where pr.i_parametros_rel  = 2        
   and ((tipoInscricao = 'J' and pessoaJuridicaAx = 0)
    or (tipoInscricao = 'F' and pessoaFisicaAx = 0));


-- CORREÇÃO

