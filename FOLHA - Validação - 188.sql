-- VALIDAÇÃO 188
-- Data do historico do cadastro anterior a data de nascimento atual

select pf.i_pessoas,
       pf.dt_nascimento,
       hpf.dt_alteracoes
  from bethadba.hist_pessoas_fis as hpf 
  join bethadba.pessoas_fisicas as pf 
 where hpf.dt_alteracoes < pf.dt_nascimento;


-- CORREÇÃO

update hist_pessoas_fis as hpf
   set hpf.dt_alteracoes = pf.dt_nascimento
  from pessoas_fisicas as pf
 where hpf.i_pessoas = pf.i_pessoas
   and hpf.dt_alteracoes < pf.dt_nascimento;