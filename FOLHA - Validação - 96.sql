-- VALIDAÇÃO 96
-- Pensionista menor de idade sem responsavel informado

select beneficiarios.i_funcionarios as Matriculas,
       pessoas_fisicas.i_pessoas as PessoasFisicas,
       pessoas_fisicas.dt_nascimento as DataNascimento,
       datename(year, getdate()) - datename(year, dt_nascimento) as IdadePensionista,
       (select i_pessoas
          from bethadba.beneficiarios_repres_legal brl
         where beneficiarios.i_entidades = brl.i_entidades
           and beneficiarios.i_funcionarios = brl.i_funcionarios) as responsavel,
       data_recebido
  from bethadba.beneficiarios,
       bethadba.funcionarios,
       bethadba.pessoas_fisicas
 where funcionarios.i_funcionarios = beneficiarios.i_funcionarios
   and pessoas_fisicas.i_pessoas = funcionarios.i_pessoas
   and idadePensionista < 18 
   and responsavel is null;


-- CORREÇÃO
-- Insere um responsável legal para o beneficiário menor de idade

insert into bethadba.beneficiarios_repres_legal (i_entidades, i_funcionarios, i_pessoas, tipo, dt_inicial, dt_final)
values (2, 292, 2835, 5, 2020-09-01, null);