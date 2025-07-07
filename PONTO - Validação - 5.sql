-- VALIDAÇÃO 5
-- Busca as ocorrências do ponto com nome repetido

select LIST(i_ocorrencias_ponto) as ocorrencias_ponto, 
       trim(nome) as nose, 
       count(nome) as cods,
       mensagem_erro = 'Ocorrencias do ponto com nome repetido'
  from bethadba.ocorrencias_ponto
 group by nose
having cods > 1;


-- CORREÇÃO

