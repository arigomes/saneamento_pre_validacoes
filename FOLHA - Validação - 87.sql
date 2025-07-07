-- VALIDAÇÃO 87
-- Dependente é a mesma pessoa que o responsavel

select pf.i_pessoas as pessoa,
	   p.nome as nm,
	   pf.cpf as cpf, 
	   dep.i_pessoas as pessoa_dep, 
	   pdep.nome nm_dep, 
	   dep.cpf cpf_dep
  from bethadba.dependentes,
  	   bethadba.pessoas_fisicas pf,
  	   bethadba.pessoas p,
  	   bethadba.pessoas_fisicas dep,
  	   bethadba.pessoas pdep
 where pf.i_pessoas = dependentes.i_pessoas
   and pf.i_pessoas = p.i_pessoas
   and dep.i_pessoas = dependentes.i_dependentes
   and dep.i_pessoas = pdep.i_pessoas
   and ((dep.cpf = pf.cpf) or (pdep.nome = p.nome));


-- CORREÇÃO
-- Exclui o dependente que é a mesma pessoa que o responsável

delete from bethadba.dependentes
 where exists (select 1
	  			 from bethadba.pessoas_fisicas pf
	  			 join bethadba.pessoas_fisicas dep
				   on dep.i_pessoas = dependentes.i_dependentes
	  			 join bethadba.pessoas p
				   on p.i_pessoas = pf.i_pessoas
	  			 join bethadba.pessoas pdep
				   on pdep.i_pessoas = dep.i_pessoas
	 			where pf.i_pessoas = dependentes.i_pessoas
	   			  and ((dep.cpf = pf.cpf) or (pdep.nome = p.nome)));