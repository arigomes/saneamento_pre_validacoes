-- VALIDAÇÃO 11
-- Verifica CNPJ Nulo

select pj.i_pessoas
  from bethadba.pessoas_juridicas pj 
 inner join bethadba.pessoas p
    on (pj.i_pessoas = p.i_pessoas)
 where cnpj is null;


-- CORREÇÃO
-- Atualiza o CNPJ nulo para um valor padrão (exemplo: '32646663000174') para evitar problemas de integridade referencial

update bethadba.pessoas_juridicas
   set cnpj ='32646663000174'
 where i_pessoas = 548;