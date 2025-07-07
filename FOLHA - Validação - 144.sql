-- VALIDAÇÃO 144
-- Pessoa fisica sem data de nascimento

select i_pessoas
  from bethadba.pessoas_fisicas
 where dt_nascimento is null
 order by i_pessoas;


-- CORREÇÃO

update bethadba.pessoas_fisicas pf
   set pf.dt_nascimento = DATEADD(year, -18, hpf.dt_alteracoes)
  from bethadba.hist_pessoas_fis hpf
 where pf.dt_nascimento is null
   and pf.i_pessoas = hpf.i_pessoas;