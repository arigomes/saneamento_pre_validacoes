call bethadba.dbp_conn_gera (1, year(today()), 300, 0);
call bethadba.pg_setoption('fire_triggers','off');
call bethadba.pg_setoption('wait_for_COMMIT','on');
commit;

-- FOLHA - Validação - 1

-- Atualiza os nomes dos logradouros duplicados para evitar duplicidade

update bethadba.ruas
   set nome = i_ruas || '-' || nome
 where i_ruas in (select i_ruas
                    from bethadba.ruas
                   where (select count(1)
                            from bethadba.ruas r
                           where (r.i_cidades = ruas.i_cidades or r.i_cidades is null)
                             and trim(r.nome) = trim(ruas.nome)) > 1);

commit;

-- FOLHA - Validação - 127

-- Atualiza os campos CNPJ que estão nulos para 0 para que não sejam considerados na validação e não gere erro de validação.

update bethadba.bethadba.rais_campos
   set CNPJ = right('000000000000' || cast((row_number() over) as varchar(12)), 12) || '91'
 where CNPJ is null;

commit;

-- FOLHA - Validação - 13

-- Atualiza os nomes dos bairros repetidos para evitar duplicidade

update bethadba.bairros
   set bairros.nome = bairros.nome || ' - (Cod: ' || i_bairros  || ')'
 where bairros.i_bairros in (select codigo
				   		       from (select max(i_bairros) as codigo,
							   				nome
      				  				   from bethadba.bairros
      				  				  where (select count(i_bairros)
	   		 		 						   from bethadba.bairros as b
       		 			 					  where trim(b.nome) = trim(bairros.nome)) > 1
       		 		  	 	  		  group by nome) as maior);

commit;

-- FOLHA - Validação - 134

-- Deleta as variáveis com data inicial maior que a data de rescisão
delete from bethadba.variaveis
 where exists (select 1
      			     from (select r.i_entidades,
      			 		    	        r.i_funcionarios,
      			 			            max(r.dt_rescisao) as data_rescisao
                         from bethadba.rescisoes r
                        where r.i_entidades = variaveis.i_entidades
                          and r.i_funcionarios = variaveis.i_funcionarios
                          and r.dt_canc_resc is null
                          and r.i_motivos_apos is null
                        group by r.i_entidades, r.i_funcionarios) resc
      			     join bethadba.funcionarios f
        		       on f.i_entidades = resc.i_entidades
       			      and f.i_funcionarios = resc.i_funcionarios
     			      where variaveis.i_entidades = resc.i_entidades
       			      and variaveis.i_funcionarios = resc.i_funcionarios
       			      and variaveis.i_eventos is not null
       			      and f.conselheiro_tutelar = 'N'
       			      and variaveis.dt_inicial > resc.data_rescisao);

-- Atualiza as variáveis com data final maior que a data de rescisão
update bethadba.variaveis
   set dt_final = cast(left(resc.data_rescisao, 7) || '-01' as date)
  from (select r.i_entidades,
               r.i_funcionarios,
               max(r.dt_rescisao) as data_rescisao
          from bethadba.rescisoes r
         where r.dt_canc_resc is null
           and r.i_motivos_apos is null
         group by r.i_entidades, r.i_funcionarios) resc
 where variaveis.i_entidades = resc.i_entidades
   and variaveis.i_funcionarios = resc.i_funcionarios
   and variaveis.i_eventos is not null
   and variaveis.dt_final > resc.data_rescisao;

commit;

-- FOLHA - Validação - 164

-- Atualizar categoria do eSocial para 701 (Contribuinte Individual) para autônomos

update bethadba.vinculos v
   set v.categoria_esocial = '701'
 where v.i_vinculos in (select hf.i_vinculos
                          from bethadba.funcionarios f 
                          join bethadba.hist_funcionarios hf
                            on f.i_entidades = hf.i_entidades
                           and f.i_funcionarios = hf.i_funcionarios
                         where f.tipo_func = 'A'
                           and f.conselheiro_tutelar = 'N'
                           and v.categoria_esocial not in ('701'));

commit;

-- FOLHA - Validação - 165

-- Atualiza os tipos de processo para 11 (Rescisão) onde necessário

update bethadba.dados_calc
  join bethadba.movimentos m
    on dc.i_entidades = m.i_entidades
   and dc.i_funcionarios = m.i_funcionarios
   and dc.i_tipos_proc = m.i_tipos_proc
   and dc.i_processamentos = m.i_processamentos
   and dc.i_competencias = m.i_competencias
   set i_tipos_proc = 11
 where dc.i_tipos_proc not in (11, 42)
   and m.mov_resc = 'S';

commit;

-- FOLHA - Validação - 173

-- Atualiza os registros da tabela afastamentos deixando nulo a coluna dt_ultimo_dia

update bethadba.afastamentos
   set dt_ultimo_dia = null
 where dt_ultimo_dia is not null
   and i_tipos_afast in (select a.i_tipos_afast
                           from bethadba.afastamentos a
                           join bethadba.tipos_afast ta
                             on a.i_tipos_afast = ta.i_tipos_afast
                          where ta.classif = 8
                            and a.dt_ultimo_dia is not null
                            and exists (select first 1
                                          from bethadba.rescisoes r
                                          join bethadba.motivos_resc mr
                                            on r.i_motivos_resc = mr.i_motivos_resc
                                          join bethadba.tipos_afast ta2
                                            on mr.i_tipos_afast = ta2.i_tipos_afast
                                         where r.i_entidades = a.i_entidades
                                           and r.i_funcionarios = a.i_funcionarios
                                           and r.dt_canc_resc is null
                                           and r.i_motivos_apos is null
                                           and r.dt_rescisao = a.dt_afastamento
                                           and ta2.classif = 8));

commit;

-- FOLHA - Validação - 176

-- Atualizar a categoria_esocial do vinculo do conselheiro para 771

update bethadba.vinculos
   set categoria_esocial = '771'
 where i_vinculos in (select hf.i_vinculos
                        from bethadba.hist_funcionarios as hf
                        join bethadba.funcionarios as f
                          on hf.i_entidades = f.i_entidades
                         and hf.i_funcionarios = f.i_funcionarios
                       where f.tipo_func = 'A' 
                         and f.conselheiro_tutelar = 'S'
                         and hf.i_vinculos is not null
                         and hf.i_vinculos in (select i_vinculos
                                                 from bethadba.vinculos
                                                where categoria_esocial <> '771'));

commit;

-- FOLHA - Validação - 187

-- Atualizar os registros com número da certidão contendo mais de 15 dígitos para os modelos antigos.

update bethadba.pessoas_fis_compl
   set num_reg = right(replicate('0', 15) + bethadba.dbf_retira_caracteres_especiais(num_reg), 15)
    where i_pessoas in (select i_pessoas
                     from (select i_pessoas,
                              modelo = if isnumeric(bethadba.dbf_retira_caracteres_especiais(pessoas_fis_compl.num_reg)) = 1 then
                                       'NOVO'
                                     else
                                       'ANTIGO'
                                     endif,
                              numeroNascimento = if modelo = 'ANTIGO' then 
                                               pessoas_fis_compl.num_reg 
                                             else
                                               bethadba.dbf_retira_alfa_de_inteiros(pessoas_fis_compl.num_reg)
                                             endif
                           from bethadba.pessoas_fis_compl
                          where numeroNascimento is not null
                           and length(numeroNascimento) > 15
                           and modelo = 'ANTIGO') as subquery);

commit;

-- FOLHA - Validação - 188

-- Atualiza a data de alteração do histórico para a data de nascimento atual para os registros onde a data de alteração é anterior à data de nascimento

update hist_pessoas_fis as hpf
   set hpf.dt_alteracoes = case when exists (select 1
                                               from hist_pessoas_fis hpf2
                                              where hpf2.i_pessoas = hpf.i_pessoas
                                                and hpf2.dt_alteracoes = pf.dt_nascimento)
                                then
                                  dateadd(day, 1, pf.dt_nascimento)
                                else
                                  pf.dt_nascimento
                                 end
  from pessoas_fisicas as pf
 where hpf.i_pessoas = pf.i_pessoas
   and hpf.dt_alteracoes < pf.dt_nascimento;

commit;

-- FOLHA - Validação - 191

-- Atualiza a data de ultimo dia para ser um dia após a data de afastamento para os registros que possuem data de ultimo dia anterior a data de afastamento

update afastamentos as a
   set a.dt_ultimo_dia = DATEADD(day, 1, a.dt_afastamento)
 where a.dt_ultimo_dia < a.dt_afastamento;

commit;

-- FOLHA - Validação - 192

-- Atualizar o campo num_reg para que o mesmo não seja duplicado na tabela pessoas_fis_compl

update bethadba.pessoas_fis_compl
   set num_reg = null
 where i_pessoas in (select i_pessoas
                       from (select i_pessoas,
                                    modelo = if isnumeric(bethadba.dbf_retira_caracteres_especiais(A.num_reg)) = 1 then
                                                'NOVO'
                                              else
                                                'ANTIGO'
                                              endif,
                                    numeroNascimento = if modelo = 'ANTIGO' then 
                                                          A.num_reg 
                                                        else
                                                          bethadba.dbf_retira_alfa_de_inteiros(A.num_reg)
                                                        endif
                               from bethadba.pessoas_fis_compl A
                              where numeroNascimento is not null
                                and exists(select first modeloB = if isnumeric(bethadba.dbf_retira_caracteres_especiais(B.num_reg)) = 1 then
                                                                      'NOVO'
                                                                  else
                                                                      'ANTIGO'
                                                                  endif,
                                                  numeroNascimentoB = if modeloB = 'ANTIGO' then 
                                                                          B.num_reg 
                                                                      else
                                                                          bethadba.dbf_retira_alfa_de_inteiros(B.num_reg)
                                                                      endif
                                             from bethadba.pessoas_fis_compl B
                                            where A.i_pessoas <> B.i_pessoas
                                              and numeroNascimentoB = numeroNascimento)) as subquery);

commit;

-- FOLHA - Validação - 196

-- Atualizar o tipo de vínculo para que não haja divergência de categoria_esocial

update bethadba.vinculos as v
   set tipo_vinculo = (select tipo_vinculo
                         from bethadba.vinculos as v2
                        where v2.categoria_esocial = v.categoria_esocial
                          and i_vinculos = (select min(v3.i_vinculos)
                                              from bethadba.vinculos as v3
                                             where v3.categoria_esocial = v.categoria_esocial))
 where categoria_esocial is not null
   and i_vinculos > (select min(v4.i_vinculos)
                       from bethadba.vinculos as v4
                      where v4.categoria_esocial = v.categoria_esocial);

commit;

-- FOLHA - Validação - 2

-- Atualiza a data de nascimento das pessoas para ser igual à data de admissão se a data de nascimento for maior que a data de admissão

update bethadba.pessoas_fisicas
   set PF.dt_nascimento = F.dt_admissao
  from bethadba.funcionarios as F
  left join bethadba.pessoas_fisicas as PF
    on PF.i_pessoas = F.i_pessoas
 where PF.dt_nascimento > F.dt_admissao;

commit;

-- FOLHA - Validação - 6

-- Atualiza a data de início da dependência para ser igual à data de nascimento do dependente se a data de nascimento for maior que a data de início da dependência
                
update bethadba.dependentes a 
  join bethadba.pessoas_fisicas b
    on (a.i_dependentes = b.i_pessoas)
   set a.dt_ini_depende = b.dt_nascimento
 where b.dt_nascimento > dt_ini_depende;

commit;

-- FOLHA - Validação - 62

-- Atualiza os cargos que não possuem configuração de férias

update bethadba.cargos_compl 
   set i_config_ferias = 1
  from bethadba.hist_cargos
 where i_config_ferias is null
   and cargos_compl.i_entidades = hist_cargos.i_entidades
   and cargos_compl.i_cargos = hist_cargos.i_cargos
   and exists(select 1
   			 	      from bethadba.periodos
               where periodos.i_entidades = hist_cargos.i_entidades
                 and periodos.i_funcionarios = hist_cargos.i_funcionarios);

commit;