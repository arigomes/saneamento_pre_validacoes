-- VALIDAÇÃO 01
-- Descricao de Logradouros Duplicadas

select list(i_ruas) as ruas, 
       trim(nome) as nome,
       i_cidades, 
       count(nome) as quantidade
  from bethadba.ruas 
 group by nome, i_cidades
having quantidade > 1;


-- CORREÇÃO

update bethadba.ruas
   set nome = i_ruas || '-' || nome
 where i_ruas in(select i_ruas
                   from bethadba.ruas
                  where (select count(1)
                           from bethadba.ruas r
                          where r.i_cidades = ruas.i_cidades
                            and trim(r.nome) = trim(ruas.nome)) > 1);
                    
update bethadba.ruas
   set nome = i_ruas || '-' || nome
 where i_ruas in(select i_ruas
                   from bethadba.ruas
                  where nome in (select nome
                                   from bethadba.ruas r
                                  where trim(r.nome) = trim(ruas.nome)
                                    and r.i_cidades is null
                                    and r.cep = ruas.cep 
                                    and ruas.tipo <> r.tipo));

begin
    declare w_segunda_rua integer;
    declare w_nome varchar(120);
	
    llloop: for ll as meuloop2 dynamic scroll cursor for
        select substring(ruas, 0,4) as primeira_rua,
               substring(ruas, 6,4) as segunda_rua,
               nome
          from (select list(i_ruas) as ruas,
                       trim(nome) as nome,
                       i_cidades,
                       count(nome) as quantidade
                  from bethadba.ruas 
                 group by nome, i_cidades
                having quantidade > 1) as teste
         where length(ruas) >= 4
    do
        set w_segunda_rua = segunda_rua;
        set w_nome = nome;

        update bethadba.ruas 
        set nome = w_nome || ' (Cod: ' || w_segunda_rua || ')'
        where i_ruas = w_segunda_rua
        and nome = w_nome
    end for;
end;