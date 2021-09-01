--�� - ��������, �� - ��������� �����.

--1. � ����� ������� ������ ������ ���������?

select city "�����"
from airports 
group by city
having count(city) > 1

--� ������� airports ����������� ������ �� ������ (�� �������� city) � ��������� �� ����������. ��������� ������� ����� ����������� � 
--������� having, � ������������ � ������� ���������� ������� ������ 1. � ��������� ������� ������ ������ �������.


--2. � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?

select distinct(f.departure_airport) "��� ��"
from flights f
join aircrafts a2 on a2.aircraft_code = f.aircraft_code 
where f.aircraft_code in (
	select aircraft_code
	from aircrafts
	order by "range" desc
	limit 1)
	
--� �������� �������� ���������� ������� flights, � ������� ������� ������ �� ����� ��, �� ��� ������ �� ��� ��������� ��������. 
--��������� �������� ���������� � ������� aircrafts. ��������� ���������� join ������� flights ������� �� ������� aircrafts �� ����� ��
--(�� �������� aircraft_code).

--����� ������� ������ ������ ��� �� � ������������ ����������, ��������� ������� � where ��� �������� aircraft_code. ���������� ��� 
--�� ������������ ��������� ������� ���������: ���������� ������� aircrafts, ������� ��� ��, ��������� � ������� order by �� ��������
--range �� �������� (desc), ���������� limit ��������� ������ ������ ������.

--� �������� ������� ������� ������ ���������� ����� ��.


--3. ������� 10 ������ � ������������ �������� �������� ������

select f.flight_no "����� �����", f.actual_departure - f.scheduled_departure "����� ��������"
from flights f
where f.actual_departure is not null
order by f.actual_departure - f.scheduled_departure desc
limit 10

--��� ������ ���������� ���������� � ������� flights. �� ��� ������� ����� ����� flight_no � ����� ��������, ������� �������� ��������
--����� ����������� �������� ������ � ����������� �������� ������. ��������� ������� �������� ���� ��� �� ����������� ������, ��� � 
--�����������, ����������� ����� ������ ����� �������������. ������� ������ � ������� � where, ��� actual_departure �� ������ ���� null. 
--��������� � ������� order by �� ������� �������� �� �������� (desc), ���������� limit ��������� ������ ������ 10 �����.


--4. ���� �� �����, �� ������� �� ���� �������� ���������� ������?

select distinct t.book_ref "�����"
from tickets t 
left join boarding_passes bp on t.ticket_no = bp.ticket_no 
where bp.ticket_no is null

--���� ����� ����� ��������� ��������� �������, �� ������ ����� �������� ���������� �����. � �������� �������� ������� ���������� 
--tickets, ��� �������� ���� ��� �� ������, ��� � �� ������� (����� �������). ��������� ������� tickets ������� �� �������
--boarding_passes (������ �������) �� �������� ticket_no. ��� ���� ���������� ��� ���������� left join, ��� �� �������������� ������� ���
--������ �� ����� �������, ���� ���� �� ��� � ������ �������. ����� �������� ��� ������ ������ �� ����� ���������� �����, � ������� 
--where ���������, ��� ��� ������ ������� �� ������ ���� ������. � ��������� ������� ���������� ������ ������.


--5. ������� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
--�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� ��
--������ ����. �.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� ������� ���������
--�� ���� ��� ����� ������ ������ �� ����.

with cte1 as --������� ����� 
	(select bp.flight_id, count(bp.seat_no) t
	from boarding_passes bp 
	group by bp.flight_id),
cte2 as --����� �����
	(select s.aircraft_code, count(s.seat_no) t1
	from seats s 
	group by s.aircraft_code)
select f.departure_airport "�� ������", f.flight_no "����� �����", f.actual_departure "����� ������", c2.t1-c1.t "��������� �����", 
	concat(round((c2.t1-c1.t)::numeric/c2.t1*100, 0), '%') "% ��������� ����",
	sum(c1.t) over (partition by date_trunc('day', f.actual_departure), f.departure_airport order by f.actual_departure) "�������� ����������"
from flights f 
join cte1 c1 on c1.flight_id = f.flight_id
join cte2 c2 on c2.aircraft_code = f.aircraft_code 
where f.status = 'Arrived'

--����� ��������� ��������� ����� � ��������, ����� ��������, ������� ���� ������ ���������� ������� �� ������ ��������. ��������� ����
--���������� � ��������� cte1. �� ������� boarding_passes ��� ������� �������� flight_id ������� �������� count ���������� ������� ����
--seat_no.

--��� �������� % ��������� ���� ����� ����� ����� ����� ������ ��� ������� ���� ��. ���� ���������� ����� ��������� � ��������� cte2.
--�� ������� seats ��� ������� ���� �� aircraft_code ������� �������� count ���������� ������ seat_no.

--����� ����������� ������� ��������� ������� flights: � cte1 �� flight_id, � cte2 �� ���� �� aircraft_code.

--������� �� ������, ����� �����, ����������� ����� ������. ��������� ����� - ��� ������� ����� ����� ���-��� ������ � �������� ��������.
--���������� ��������� - ������ ������� � ������ ���-�� ������*100. �������� ������� �� ����� � ������� ������� round, ��� �����������
--���������� �������� ��� ������ numeric. �������� concat ������� ���� %.

--������������� ���� ���������� ���������� �������� � ������� ������� �������. ��� ����� ���������� ���������� ������� sum ��� ���-��
--������� ������, ����� �������� ������� ������� ������������ over, ��������� ������������ partition by, ����� ������������� ������ ��
--��� � �� ������. ���� ������ ����� �� ������������ ������� ������ � ������� �-�� date_trunc('day', ..). ������� ������ ����� ������
--�� ������� ������ �� �����������.

--��������� ��� ���������� ���� ���������� ���������� � ������� where ��������� ������ ������ arrived.


--6. ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.

select f.aircraft_code "��� ��������", 
	concat(round(count(f.flight_id)::numeric/(select count(flight_id) from flights)*100, 0), '%') "% ���������"
from flights f 
group by f.aircraft_code

--��� ������ ���� � ������� flights. C���������� ������ �� ����� �� � ��������� ���������� �-��� count ���������� ��������� �� ��� 
--� ������ ���������� ���������. ����� ���������� ��������� ��������� ����������� � select ����� � ������� �-�� count. �������� ���������
--�� ����� � ������� ������� round, ��� ����������� ���������� �������� ��� ������ numeric. �������� concat ������� ���� %.


--7. ���� �� ������, � ������� ����� ��������� ������-������� �������, ��� ������-������� � ������ ��������?

--� �������������� ������������� 
with cte_1 as --������ ��� ������� id
	(select distinct(tf.flight_id), tf.fare_conditions, tf.amount 
	from ticket_flights tf 
	where tf.fare_conditions = 'Economy'),
cte_2 as --������ ��� ������� id
	(select distinct(tf.flight_id), tf.fare_conditions, tf.amount 
	from ticket_flights tf 
	where tf.fare_conditions = 'Business')
select distinct(f.arrival_city) "����� �������", c1.fare_conditions "������", c1.amount "�����", 
	c2.fare_conditions "������", c2.amount "�����" 
from flights_v f
join cte_1 c1 on c1.flight_id = f.flight_id
join cte_2 c2 on c2.flight_id = f.flight_id --182482/3537ms
where c1.amount > c2.amount

--��� ������������� �������������
with cte_1 as --������ ��� ������� id
	(select distinct(tf.flight_id), tf.fare_conditions, tf.amount 
	from ticket_flights tf 
	where tf.fare_conditions = 'Economy'),
cte_2 as --������ ��� ������� id
	(select distinct(tf.flight_id), tf.fare_conditions, tf.amount 
	from ticket_flights tf 
	where tf.fare_conditions = 'Business')
select distinct(a.city) "����� �������", c1.fare_conditions "������", c1.amount "�����", 
	c2.fare_conditions "������", c2.amount "�����" 
from flights f
join cte_1 c1 on c1.flight_id = f.flight_id
join cte_2 c2 on c2.flight_id = f.flight_id
join airports a on a.airport_code = f.arrival_airport --182288/3540ms
where c1.amount > c2.amount

--����� ��� ������� �������� (�� ���� ��� ������� flight_id) ����� ����� ������ ��� ������-������ � ��� ������-������ � ����� ��������
--��� ��� �����. ��� ������� ������ ������������ �������� ��������� cte: ��� ������ cte_1, ��� ������� cte_2. � ��� ��������� �� �������
--flight_id ��������� amount �� ������� ticket_flights. ������� ���������� �������� flights_id, ����� ������������ � �����.

--� �������� ������ ������������ ������������� flights_v, ������ ��� ��� �������� ������ � ������� � ������� �� ������� flights.
--���� �� ������������ �������������, � ����� �� ������ ������� flights � ��������� �� ������� � ������� �� ������� airports, ��� �������
--�������������� ������ � ������. �� ����������� �������� � ������� ������� ���.

--��������� ������������� flights_v ����������� ������� � cte �� flight_id. ��� �� �������� � ����� ������ ��� ������� �������� �����
--��� ������-������ � ��� ������-������ � ����� �� ��������. ��������� ������� � where, ��� ����� ������-������ ������ ���� ����, ���
--����� ������-������.

--� ��������� ������� ������ ���������� ������� �������, ��� ���������� - ����� ������������ � �����.


--8. ����� ������ �������� ��� ������ ������?

--� �������������� ���. �������������
select a.city "����� ������", a2.city "����� �������"
from airports a, airports a2
where not a.city = a2.city
except 
select r.departure_city, r.arrival_city 
from routes r --168/29ms

--��� ������������� ���. �������������
create view test as
select distinct(f.flight_no), f.departure_airport, a.city dep_city, f.arrival_airport, a2.city arr_city 
from flights f 
join airports a on a.airport_code = f.departure_airport 
join airports a2 on a2.airport_code = f.arrival_airport 

select a.city "����� ������", a2.city "����� �������"
from airports a, airports a2
where not a.city = a2.city
except 
select t.dep_city, t.arr_city 
from test t --3034/268ms

--����� ������������ ��� ��������� ���������� ������� ���������� ������� airports, ������� �������� � ���� ������ city. � �����������
--from ����� ������� ������ ������ ������� ������, �� �������� ������ ������. � ��������� ������� city �� ������ �������. ��� �� �������
--��������� ������������. ����� ��������� ���� � ���������� �������, ������ ������� � where. ����� � ������� ��������� except ���������
--�� ����������� ������ ������, ����� �������� ���� ������ �����. 

--����� �������� ������ �������, ����� �������� ���� ������ �����, ������ ������������ ���. ������������� routes. ��� �������� ���� �� 
--������� ��������, ������� ������. ��������� ��� �������� ������� ������������, � �������� ������������ ����� ������������ ������� 
--flights, ��������� �� ������� � ������� � ������� �� �� ������ �������������. �� � ����� ������ ��������� ����������� �������� 
--���������� � 18 ���, � ����� �� ���������� ������� - � 9 ���.


--9. ��������� ���������� ����� �����������, ���������� ������� �������, �������� � ���������� ������������ ����������
--���������  � ���������, ������������� ��� �����

--� �������������� ���. �������������
select r.flight_no "����� �����", r.departure_airport "�� ������", r.arrival_airport "�� �������", 
round(6371*(acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude)))::numeric,0) "����������, ��", a3."range" "��������� ��, ��",
	case when round(6371*(acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude)))::numeric,0) > a3."range" then '����'
	else '�������'
	end "������"
from routes r 
join airports a on a.airport_code = r.departure_airport
join airports a2 on a2.airport_code = r.arrival_airport
join aircrafts a3 on a3.aircraft_code = r.aircraft_code --93.86/25ms

--��� ������������� ���. �������������
create view test1 as
select distinct(f.flight_no), f.departure_airport, f.arrival_airport, f.aircraft_code 
from flights f 

explain analyze
select t.flight_no "����� �����", t.departure_airport "�� ������", t.arrival_airport "�� �������", 
round(6371*(acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude)))::numeric,0) "����������, ��", a3."range" "��������� ��, ��",
	case when round(6371*(acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude)))::numeric,0) > a3."range" then '����'
	else '�������'
	end "������"
from test1 t
join airports a on a.airport_code = t.departure_airport
join airports a2 on a2.airport_code = t.arrival_airport
join aircrafts a3 on a3.aircraft_code = t.aircraft_code --1143/125ms

--� �������� �������� ������� � �������� ��������� ������ ������������ ���. ������������� routs. ��� ��, ��� � � ���������� �������,
--������������ - ������������ ������������� �� ������� flights. �� � ����� ������ ��������� ����������� �������� ���������� � 12 ���, 
--� ����� �� ���������� ������� - � 5 ���.

--������ �� ������ � ������� ���������� ��������� ����������� �� �� ���������������. ���������� �������� � ������� airports.
--���������� join ������� ��������� ������� �� ������� airports �� �� ������, ����� �������� ������� �� ��� �� �������, �� �� 
--�� �������. ��������� � ����� ������� �� ���������� ������� airports ������, ������ �� ��� ������ ������. ����� �������� �
--���������� �� ���������� ����� �������� ������ �� ������� aircrafts �� aircraft_code.

--� ��������� ������� ����� �����, �� ������ � �������. ����� ���������� ��������� ���������� �� �������. ������� airports ������
--���������� � ��������, ������� ���������� ������� sind � cosd. ����� � ������� ��������� case ���������� ���������� ���������� � 
--���������� ��. ���� ���������� ������, ��� ��������� ��, �� �� �� �������. �, ��������������, ���� ��������, �� �� �������.


