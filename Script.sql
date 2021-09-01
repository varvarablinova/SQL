--АП - аэропорт, ВС - воздушное судно.

--1. В каких городах больше одного аэропорта?

select city "Город"
from airports 
group by city
having count(city) > 1

--В таблице airports сгруппируем данные по городу (по атрибуту city) и посчитаем их количество. Добавляем условие после группировки с 
--помощью having, в соответствии с которым количество городов больше 1. В результат выводим только список городов.


--2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?

select distinct(f.departure_airport) "Код АП"
from flights f
join aircrafts a2 on a2.aircraft_code = f.aircraft_code 
where f.aircraft_code in (
	select aircraft_code
	from aircrafts
	order by "range" desc
	limit 1)
	
--В качестве основной используем таблицу flights, в которой имеются данные по типам ВС, но нет данных по его дальности перелета. 
--Дальность перелета содержится в таблице aircrafts. Обогощаем оператором join таблицу flights данными из таблицы aircrafts по типам ВС
--(по атрибуту aircraft_code).

--Чтобы вывести строки только для ВС с максимальной дальностью, добавляем условие в where для атрибута aircraft_code. Определить тип 
--ВС максимальной дальности поможет подзапрос: используем таблицу aircrafts, выводим тип ВС, сортируем с помощью order by по атрибуту
--range по убыванию (desc), оператором limit оставляем только первую строку.

--В основном запросе выводим список уникальных кодов АП.


--3. Вывести 10 рейсов с максимальным временем задержки вылета

select f.flight_no "Номер рейса", f.actual_departure - f.scheduled_departure "Время задержки"
from flights f
where f.actual_departure is not null
order by f.actual_departure - f.scheduled_departure desc
limit 10

--Вся нужная информация содержится в таблице flights. Из нее выводим номер рейса flight_no и время задержки, которое является разницей
--между фактическим временем вылета и планируемым временем вылета. Поскольку таблица содержит инфо как по совершенным рейсам, так и 
--планируемым, фактическое время вылета может отсутствовать. Поэтому укажем в условии в where, что actual_departure не должно быть null. 
--Сортируем с помощью order by по времени задержки по убыванию (desc), оператором limit оставляем только первые 10 строк.


--4. Были ли брони, по которым не были получены посадочные талоны?

select distinct t.book_ref "Брони"
from tickets t 
left join boarding_passes bp on t.ticket_no = bp.ticket_no 
where bp.ticket_no is null

--Одна бронь может содержать несколько билетов, на каждый билет выдается посадочный талон. В качестве основной таблицы используем 
--tickets, она содержит ифно как по броням, так и по билетам (левая таблица). Обогощаем таблицу tickets данными из таблицы
--boarding_passes (правая таблица) по атрибуту ticket_no. При этом используем тип соединения left join, так мы гарантированно выведем все
--данные из левой таблицы, даже если их нет в правой таблице. Чтобы выяснить для какого билета не выдан посадочный талон, в условии 
--where указываем, что для правой таблицы не должно быть данных. В результат выводим уникальные номера броней.


--5. Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
--Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на
--каждый день. Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта
--на этом или более ранних рейсах за день.

with cte1 as --занятые места 
	(select bp.flight_id, count(bp.seat_no) t
	from boarding_passes bp 
	group by bp.flight_id),
cte2 as --всего места
	(select s.aircraft_code, count(s.seat_no) t1
	from seats s 
	group by s.aircraft_code)
select f.departure_airport "АП вылета", f.flight_no "Номер рейса", f.actual_departure "Время вылета", c2.t1-c1.t "Свободные места", 
	concat(round((c2.t1-c1.t)::numeric/c2.t1*100, 0), '%') "% свободных мест",
	sum(c1.t) over (partition by date_trunc('day', f.actual_departure), f.departure_airport order by f.actual_departure) "Вывезено пассажиров"
from flights f 
join cte1 c1 on c1.flight_id = f.flight_id
join cte2 c2 on c2.aircraft_code = f.aircraft_code 
where f.status = 'Arrived'

--Чтобы посчитать свободные места в самолете, нужно выяснить, сколько было выдано посадочных талонов на каждом перелете. Посчитаем этот
--показатель в отдельной cte1. Из таблицы boarding_passes для каждого перелета flight_id считаем функцией count количество занятых мест
--seat_no.

--Для подсчета % свободных мест нужно знать общее число кресел для каждого типа ВС. Этот показатель также посчитаем в отдельной cte2.
--Из таблицы seats для каждого типа ВС aircraft_code считаем функцией count количество кресел seat_no.

--Далее полученными данными обогощаем таблицу flights: с cte1 по flight_id, с cte2 по типу ВС aircraft_code.

--Выводим АП вылета, номер рейса, фактическое время вылета. Свободные места - это разница между общим кол-вом кресел и занятыми креслами.
--Процентное отношение - данная разница к общему кол-ву кресел*100. Округлим процент до целых с помощью функции round, для корректного
--округления присвоим тип данных numeric. Функцией concat добавим знак %.

--Накопительный итог вывезенных пассажиров получаем с помощью оконной функции. Для этого используем агрегатную функцию sum для кол-ва
--занятых кресел, далее вызываем оконную функцию предложением over, дополняем предложением partition by, чтобы сгруппировать строки по
--дню и АП вылета. День вылета берем из фактического времени вылета с помощью ф-ии date_trunc('day', ..). Порядок внутри групп задаем
--по времени вылета по возрастанию.

--Поскольку нас интересует факт вывезенных пассажиров в условии where указываем статус рейсов arrived.


--6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.

select f.aircraft_code "Тип самолета", 
	concat(round(count(f.flight_id)::numeric/(select count(flight_id) from flights)*100, 0), '%') "% перелетов"
from flights f 
group by f.aircraft_code

--Все данные есть в таблице flights. Cгруппируем данные по типам ВС и посчитаем агрегатной ф-ией count количество перелетов по ним 
--к общему количеству перелетов. Общее количество перелетов определим подзапросом в select также с помощью ф-ии count. Округлим результат
--до целых с помощью функции round, для корректного округления присвоим тип данных numeric. Функцией concat добавим знак %.


--7. Были ли города, в которые можно добраться бизнес-классом дешевле, чем эконом-классом в рамках перелета?

--с использованием представления 
with cte_1 as --эконом для каждого id
	(select distinct(tf.flight_id), tf.fare_conditions, tf.amount 
	from ticket_flights tf 
	where tf.fare_conditions = 'Economy'),
cte_2 as --бизнес для каждого id
	(select distinct(tf.flight_id), tf.fare_conditions, tf.amount 
	from ticket_flights tf 
	where tf.fare_conditions = 'Business')
select distinct(f.arrival_city) "Город прилета", c1.fare_conditions "Эконом", c1.amount "Сумма", 
	c2.fare_conditions "Бизнес", c2.amount "Сумма" 
from flights_v f
join cte_1 c1 on c1.flight_id = f.flight_id
join cte_2 c2 on c2.flight_id = f.flight_id --182482/3537ms
where c1.amount > c2.amount

--без использования представления
with cte_1 as --эконом для каждого id
	(select distinct(tf.flight_id), tf.fare_conditions, tf.amount 
	from ticket_flights tf 
	where tf.fare_conditions = 'Economy'),
cte_2 as --бизнес для каждого id
	(select distinct(tf.flight_id), tf.fare_conditions, tf.amount 
	from ticket_flights tf 
	where tf.fare_conditions = 'Business')
select distinct(a.city) "Город прилета", c1.fare_conditions "Эконом", c1.amount "Сумма", 
	c2.fare_conditions "Бизнес", c2.amount "Сумма" 
from flights f
join cte_1 c1 on c1.flight_id = f.flight_id
join cte_2 c2 on c2.flight_id = f.flight_id
join airports a on a.airport_code = f.arrival_airport --182288/3540ms
where c1.amount > c2.amount

--Нужно для каждого перелета (то есть для каждого flight_id) найти сумму билета для эконом-класса и для бизнес-класса и далее сравнить
--эти две суммы. Для каждого класса обслуживания создадим отдельную cte: для эконом cte_1, для бизнеса cte_2. В них определим по каждому
--flight_id стоимость amount из таблицы ticket_flights. Выведем уникальные значения flights_id, класс обслуживания и сумму.

--В качестве основы использовано представление flights_v, потому что оно содержит данные о городах в отличие от таблицы flights.
--Если не использовать представление, а брать за основу таблицу flights и обогощать ее данными о городах из таблицы airports, это добавит
--дополнительную строку в скрипт. По затраченным ресурсам и времени разницы нет.

--Обогощаем представление flights_v полученными данными в cte по flight_id. Так мы получили в одной строке для каждого перелета сумму
--для эконом-класса и для бизнес-класса и можем их сравнить. Указываем условие в where, что сумма эконом-класса должна быть выше, чем
--сумма бизнес-класса.

--В результат выводим список уникальных городов прилета, для информации - класс обслуживания и сумму.


--8. Между какими городами нет прямых рейсов?

--с использованием мат. представления
select a.city "Город вылета", a2.city "Город прилета"
from airports a, airports a2
where not a.city = a2.city
except 
select r.departure_city, r.arrival_city 
from routes r --168/29ms

--без использования мат. представления
create view test as
select distinct(f.flight_no), f.departure_airport, a.city dep_city, f.arrival_airport, a2.city arr_city 
from flights f 
join airports a on a.airport_code = f.departure_airport 
join airports a2 on a2.airport_code = f.arrival_airport 

select a.city "Город вылета", a2.city "Город прилета"
from airports a, airports a2
where not a.city = a2.city
except 
select t.dep_city, t.arr_city 
from test t --3034/268ms

--Чтобы сформировать все возможные комбинации городов используем таблицу airports, которая содержит в себе города city. В предложении
--from через запятую укажем данную таблицу дважды, но присвоим разные алиасы. В результат выведем city из каждой таблицы. Так мы получим
--декартово произведение. Чтобы исключить пары с одинаковым городом, укажем условие в where. Далее с помощью оператора except исключаем
--из полученного списка города, между которыми есть прямые рейсы. 

--Чтобы получить список городов, между которыми есть прямые рейсы, удобно использовать мат. представление routes. Оно содержит инфо по 
--каждому маршруту, включая города. Поскольку это нарушает принцип нормализации, в качестве альтернативы можно использовать таблицу 
--flights, обогатить ее данными о городах и создать на ее основе представление. Но в таком случае стоимость затраченных ресурсов 
--увеличится в 18 раз, а время на выполнение запроса - в 9 раз.


--9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью
--перелетов  в самолетах, обслуживающих эти рейсы

--с использованием мат. представления
select r.flight_no "Номер рейса", r.departure_airport "АП вылета", r.arrival_airport "АП прилета", 
round(6371*(acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude)))::numeric,0) "Расстояние, км", a3."range" "Дальность ВС, км",
	case when round(6371*(acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude)))::numeric,0) > a3."range" then 'Упал'
	else 'Долетел'
	end "Статус"
from routes r 
join airports a on a.airport_code = r.departure_airport
join airports a2 on a2.airport_code = r.arrival_airport
join aircrafts a3 on a3.aircraft_code = r.aircraft_code --93.86/25ms

--без использования мат. представления
create view test1 as
select distinct(f.flight_no), f.departure_airport, f.arrival_airport, f.aircraft_code 
from flights f 

explain analyze
select t.flight_no "Номер рейса", t.departure_airport "АП вылета", t.arrival_airport "АП прилета", 
round(6371*(acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude)))::numeric,0) "Расстояние, км", a3."range" "Дальность ВС, км",
	case when round(6371*(acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude)))::numeric,0) > a3."range" then 'Упал'
	else 'Долетел'
	end "Статус"
from test1 t
join airports a on a.airport_code = t.departure_airport
join airports a2 on a2.airport_code = t.arrival_airport
join aircrafts a3 on a3.aircraft_code = t.aircraft_code --1143/125ms

--в качестве основной таблицы с перечнем маршрутов удобно использовать мат. представление routs. Так же, как и в предыдущем задании,
--альтернатива - использовать представление из таблицы flights. Но в таком случае стоимость затраченных ресурсов увеличится в 12 раз, 
--а время на выполнение запроса - в 5 раз.

--список АП вылета и прилета необходимо дополнить информацией об их местпололожении. Координаты хранятся в таблице airports.
--Оператором join сначала обогощаем данными из таблицы airports по АП вылета, затем обогащем данными из той же таблицы, но по 
--АП прилета. Поскольку в одном запросе мы используем таблицу airports дважды, задаем ей два разных алиаса. Чтобы сравнить с
--дальностью ВС необходимо также добавить данные из таблицы aircrafts по aircraft_code.

--в результат выводим номер рейса, АП вылета и прилета. Далее необходимо посчитать расстояние по формуле. Таблица airports хранит
--координаты в градусах, поэтому используем функции sind и cosd. Далее с помощью оператора case сравниваем полученное расстояние с 
--дальностью ВС. Если расстояние больше, чем дальность ВС, то ВС не долетит. И, соответственно, если наоборот, то ВС долетит.


