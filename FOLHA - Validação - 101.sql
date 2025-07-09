-- VALIDAÇÃO 101
-- Verifica os bancos fora do padrao

select i_pessoas
  from bethadba.pessoas_contas
 where i_bancos >= 758
   and i_bancos != 800;


-- CORREÇÃO
-- Atualiza os bancos fora do padrão para o banco 800 (Banco do Brasil)

update bethadba.pessoas_contas
   set i_bancos = 800
 where i_bancos >= 758
   and i_bancos != 800;