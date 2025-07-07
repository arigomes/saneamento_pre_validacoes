-- VALIDAÇÃO 24
-- Verifica categoria eSocial nulo no motivo de aposentadoria

select i_motivos_apos,
       descricao,
       categoria_esocial
  from bethadba.motivos_apos
 where categoria_esocial is null;

              
-- CORREÇÃO
                
update bethadba.motivos_apos
   set categoria_esocial = '38' //Aposentadoria, exceto por ivalidez
 where i_motivos_apos in (1,2,3,4,8,9);

update bethadba.motivos_apos
   set categoria_esocial = '39' //Aposentadoria por ivalidez
 where i_motivos_apos in (5,6,7);