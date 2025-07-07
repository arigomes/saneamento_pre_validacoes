-- VALIDAÇÃO 03
-- Busca a data de vencimento da CNH menor que a data de emissão da 1ª habilitação

select i_pessoas,
       dt_primeira_cnh,
       dt_vencto_cnh
  from bethadba.pessoas_fis_compl
 where dt_primeira_cnh > dt_vencto_cnh
 
union
 
select i_pessoas,
       dt_primeira_cnh,
       dt_vencto_cnh
  from bethadba.hist_pessoas_fis hpf  
 where dt_primeira_cnh > dt_vencto_cnh;


-- CORREÇÃO                  

update bethadba.pessoas_fis_compl
   set dt_vencto_cnh = dt_primeira_cnh
 where dt_vencto_cnh < dt_primeira_cnh;
 
update bethadba.hist_pessoas_fis
   set dt_vencto_cnh = dt_primeira_cnh
 where dt_vencto_cnh < dt_primeira_cnh;