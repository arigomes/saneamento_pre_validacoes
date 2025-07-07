-- VALIDAÇÃO 83
-- Veririca pessoas jurídicas com cnpjs duplicados

select p.i_pessoas as pessoa, 
       p.nome as nome,
       pj.cnpj as cnpj
  from bethadba.pessoas as p,
  	   bethadba.pessoas_juridicas as pj
 where p.i_pessoas = pj.i_pessoas
   and pj.cnpj in (select distinct pessoas_juridicas.cnpj
                     from bethadba.pessoas_juridicas
                    group by pessoas_juridicas.cnpj
                   having count(pessoas_juridicas.cnpj) > 1);


-- CORREÇÃO
-- Atualiza os CNPJs duplicados para um CNPJ fictício, porém válido, para posterior correção manual
-- Gera CNPJs fictícios únicos para cada registro duplicado
-- Exemplo usando ROW_NUMBER para gerar sufixos únicos (ajuste conforme o SGBD se necessário)

update bethadba.pessoas_juridicas pj
   set cnpj = right('000000000000' || cast((row_number() over (order by pj.i_pessoas)) as varchar(12)), 12) || '91'
  from (select i_pessoas
          from bethadba.pessoas_juridicas
         where cnpj in (select cnpj
                          from bethadba.pessoas_juridicas
                         group by cnpj
                        having count(*) > 1)
           and i_pessoas not in (select min(i_pessoas)
                                   from bethadba.pessoas_juridicas
                                  group by cnpj
                                 having count(*) > 1)) as dup
 where pj.i_pessoas = dup.i_pessoas;