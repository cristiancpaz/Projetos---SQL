

--1) Mostrar, por departamento, o percentual de funcionários em cada plano de saúde.

select departamento.nome, planosaude.nome,trunc(100.0 * tmp1.qtde / tmp2.total,2) 
from    
    (select departamento, planosaude, count(*) as qtde 
    from funcionario 
    where planosaude is not null
    group by 1,2)as tmp1
 join 
(select departamento, count(*) as total 
from funcionario group by 1) as tmp2
on tmp1.departamento = tmp2.departamento
join departamento on tmp1.departamento = departamento.codigo
join planosaude on tmp1.planosaude = planosaude.codigo order by 1,2;
--2) Mostrar quais dos departamentos com as 3 maiores equipes são também os com as 3 maiores folhas de pagamento.


(select departamento.nome as nome, sum(salario) as total
from funcionario
join departamento on funcionario.departamento = departamento.codigo
group by 1 order by 2 desc limit 3) as b
group by 1,2 order by 2 desc;

--3) Considerando que não existem trocas de pessoal entre departamentos, mostrar quais dos funcionários mais idosos de cada departamento são também os mais antigos de cada departamento.



select funcionario.nome, departamento.nome 
from
    (select funcionario.nome as nome, funcionario.departamento
    from funcionario
    where contratacao in 
    (select  min(contratacao) as contratacao
    from funcionario
    group by departamento order by 1 asc))as tmp1
    join
    (select funcionario.nome as nome, funcionario.departamento
    from funcionario
    where nascimento IN
    (select min(funcionario.nascimento) as nascimento  
    from funcionario
    group by departamento order by 1 asc)) as tmp2
on tmp1.nome = tmp2.nome
join funcionario on tmp1.nome = funcionario.nome
join departamento on funcionario.departamento = departamento.codigo;

--revisar

--4) Mostrar, por plano de saúde, a quantidade de vidas (funcionários e dependentes) por faixa etária (-20, 20-30, 30-40, 40-50, 50-60, 60-70, 70-).

select planosaude.nome, 
case 
    when date_part('year', age(nascimento)) <  20 then'1) 00-20'
    when date_part('year', age(nascimento)) <  30 then'2) 20-30'
    when date_part('year', age(nascimento)) <  40 then'3) 30-40'
    when date_part('year', age(nascimento)) <  50 then'4) 40-50'
    when date_part('year', age(nascimento)) <  60 then'5) 50-60'
    when date_part('year', age(nascimento)) <  70 then'6) 60-70'
    when date_part('year', age(nascimento)) >= 70 then'7) 70-'
    end faixa_etaria, count(*) as qtde
    from funcionario
    join planosaude on funcionario.planosaude = planosaude.codigo
    where planosaude is not null
    group by 1,2
    order by 1,2;

--5) Mostrar o nome e o curso dos alunos de cursos técnicos que locaram livros sobre PostgreSQL nos últimos 3 meses.


select usuario.nome, usuario.curso, livro.titulo
from usuario
join locacao on usuario.codigo = locacao.usuario
join exemplar on locacao.exemplar = exemplar.codigo
join livro on exemplar.livro = livro.codigo
where usuario.curso like '%integrado%' and usuario.curso is not null
and livro.titulo like '%postgresql%' and locacao.retirada in 
(select retirada 
from locacao 
where retirada > '2018-03-01' and retirada < '2018-06-01');

--6) Mostrar o ranking dos livros mais locados por curso no ano passado.

select livro.titulo, usuario.curso, count(*)
from livro
join exemplar on livro.codigo = exemplar.livro
join locacao on locacao.exemplar = exemplar.codigo
join usuario on locacao.usuario = usuario.codigo
where usuario.curso is not null
group by 1,2 --order by 3 desc;
having count(*) in 
(select a.cont from
(select livro.titulo, count(*) as cont
from livro
join exemplar on livro.codigo = exemplar.livro
join locacao on locacao.exemplar = exemplar.codigo
join usuario on locacao.usuario = usuario.codigo
where retirada > current_date - cast('3 years' as interval)
group by 1 order by 2 desc)as a) order by 3 desc;


--7) Mostrar o nome dos alunos do Curso Superior de Tecnologia em Análise e Desenvolvimento de Sistemas que locaram mais de uma vez o mesmo livro sobre PostgreSQL.
locacao
exemplar
usuario

select locacao.usuario, usuario.curso
from usuario
join locacao on usuario.codigo = locacao.usuario
where usuario.curso = 'curso superior de tecnologia em analise e desenvolvimento de sistemas' and locacao.usuario =any
(select a.usuario from
(select livro.titulo, locacao.usuario, count(*)
from livro
join exemplar on livro.codigo = exemplar.livro
join locacao on exemplar.codigo = locacao.exemplar
where livro.titulo like '%postgresql%'
group by 1,2
having count(*) > 1)as a);

--8) Mostrar o título dos livros sobre PostgreSQL não locados nos últimos 3 meses.
select b.titulo 
from 
(select livro.titulo as titulo,locacao.exemplar as exemplar, count(*)
from livro
join exemplar on exemplar.livro = livro.codigo
join locacao on exemplar.codigo = locacao.exemplar--1000
where --locacao.retirada > current_date - cast('3 years' as interval)and 
livro.titulo like '%postgresql%' 
group by 1,2) as b
where b.titulo not in
(select a.titulo from
(select locacao.exemplar as exemplar,locacao.retirada,livro.titulo as titulo
from locacao
join exemplar on locacao.exemplar = exemplar.codigo
join livro on exemplar.livro = livro.codigo
where locacao.retirada > current_date - cast('2 years' as interval) 
and livro.titulo like '%postgresql%')as a);

--9) Mostrar o tempo médio das locações de alunos do Curso Superior de Tecnologia em Análise e Desenvolvimento de Sistemas.

select avg(entrega - retirada) 
from locacao 
join usuario on locacao.usuario = usuario.codigo 
where usuario.curso = 'curso superior de tecnologia em analise e desenvolvimento de sistemas';

--10) Mostrar os aniversariantes do mês, indicando se é funcionário ou dependente.

(select funcionario.nome, extract('month' from funcionario.nascimento) as mes
from funcionario
where extract('month' from nascimento) = extract('month' from current_date))
union
(select dependente.nome, extract('month' from dependente.nascimento) as mes
from dependente
where extract('month' from nascimento) = extract('month' from current_date));


--11) Mostrar o funcionário com mais filhos.

select funcionario.nome, count(dependente.funcionario) as qtde
from funcionario
join dependente on funcionario.codigo = dependente.funcionario
group by 1
having count(dependente.funcionario) =
(select distinct max(a.qtde) from
(select dependente.funcionario, count(*) as qtde
from dependente
group by 1 order by 2 desc) as a);
--12) Mostrar, por departamento, os funcionários com 3 ou mais dependentes que não possuem plano de saúde.

select b.funcionario, b.departamento, count(*) from 
(select funcionario.codigo as funcionario, funcionario.departamento as departamento, funcionario.planosaude
from funcionario
where funcionario.planosaude is null and funcionario.codigo in 
(select a.funcionario from 
(select dependente.funcionario as funcionario, count(*)
from dependente
group by 1
having count(*) >= 3) as a)) as b group by 1,2;



--13) Mostrar o plano de saúde que cuida de cada vida (funcionários e dependentes) da empresa.
    -- Caso a vida não possua plano de saúde, deve ser mostrado '---' no lugar.

--14) Mostrar, por departamento, o plano de saúde preferido pelos funcionários.

