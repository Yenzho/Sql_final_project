
--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите названия самолётов, которые имеют менее 50 посадочных мест.
select a.model 
from aircrafts a 
join seats s on s.aircraft_code = a.aircraft_code 
group by a.model
having count(s.seat_no) < 50;



--ЗАДАНИЕ №2
--Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых

select *, round((sum_amount / lag(sum_amount) over (order by month_start) - 1) * 100, 2) as percentage
from(
	select date_trunc('month', book_date) AS month_start, 
		sum(total_amount) as sum_amount 
	from bookings b
	group by date_trunc('month', book_date))



--ЗАДАНИЕ №3
--Выведите названия самолётов без бизнес-класса. Используйте в решении функцию array_agg
--Первый вариант решения с cte
with cte as (
    select aircraft_code
    from seats
    where fare_conditions = 'Business')	
select model, array_agg(distinct fare_conditions) as class_types
from aircrafts a 
join seats s on s.aircraft_code = a.aircraft_code 
where a.aircraft_code not in (select * from cte)
group by a.aircraft_code

--Второй вариант решения
select  a.aircraft_code, a.model, array_agg(distinct s.fare_conditions) as class_types
from aircrafts a
left join seats s on a.aircraft_code = s.aircraft_code
group by a.aircraft_code 
having not 'Business' = any(array_agg(distinct s.fare_conditions));



--ЗАДАНИЕ №4
--Выведите накопительный итог количества мест в самолётах по каждому аэропорту на каждый день. 
--Учтите только те самолеты, которые летали пустыми и только те дни, когда из одного аэропорта вылетело более одного такого самолёта.
--Выведите в результат код аэропорта, дату вылета, количество пустых мест и накопительный итог.

--Накопительный итог мест по каждому аэропорту на каждый день
select sum(count(s.seat_no)) over (partition by date_trunc('day', f.actual_departure), f.departure_airport order by f.actual_departure) as cumulative_seat_count,
	f.departure_airport, f.actual_departure
from flights f
left join seats s on f.aircraft_code = s.aircraft_code
left join boarding_passes bp on f.flight_id = bp.flight_id and s.seat_no = bp.seat_no
group by f.flight_id

--Само решение, с накопительным итогом по пустым местам в пустых самолетах

with cte as (
	select date_trunc('day', f.actual_departure) AS actual_departure,
	    f.departure_airport as airport_name,
	    count(s.seat_no) as seat_count,
	    f.aircraft_code AS board
	from flights f
	left join seats s on f.aircraft_code = s.aircraft_code
	left join boarding_passes bp on f.flight_id = bp.flight_id and s.seat_no = bp.seat_no
	where f.status = 'Departed' or f.status = 'Arrived'
	group by f.flight_id
	having count(bp.ticket_no) = 0)	
select actual_departure, airport_name, seat_count, cumulative_free_seat_count
from(
	select actual_departure, airport_name, seat_count,
		sum(seat_count) over (partition by actual_departure, airport_name order by actual_departure) as cumulative_free_seat_count,
		count(board) over (partition by actual_departure, airport_name) as count_of_boards
	from cte
	group by actual_departure, airport_name, seat_count, board)
where count_of_boards > 1



--ЗАДАНИЕ №5
--Найдите процентное соотношение перелётов по маршрутам от общего количества перелётов. Выведите в результат названия аэропортов и процентное отношение.
--Используйте в решении оконную функцию.

--Тут можно было бы использовать CTE и отдельно вывести количество перелетов, но так как написано использовать оконные функции, решил использовать их больше.	

select distinct  departure_airport, arrival_airport, 
	dp.airport_name as "Аэропорт отбытия", ar.airport_name as "Аэропорт прибытия",
	count(flight_id) over (partition by departure_airport, arrival_airport),
	round((count(flight_id) over (partition by departure_airport, arrival_airport) * 100.0) / sum(count(flight_id)) over (), 2) as percentage
from flights f
left join airports dp on dp.airport_code = f.departure_airport 
left join airports ar on ar.airport_code = f.arrival_airport
group by flight_id, dp.airport_name, ar.airport_name


--ЗАДАНИЕ №6
--Выведите количество пассажиров по каждому коду сотового оператора. Код оператора – это три символа после +7

select substring() (contact_data->>'phone' from '\+7(\d{3})') as operator_code,
    count(*) as passenger_count
from tickets t 
group by operator_code


--ЗАДАНИЕ №7
--Классифицируйте финансовые обороты (сумму стоимости перелетов) по маршрутам:
--до 50 млн – low
--от 50 млн включительно до 150 млн – middle
--от 150 млн включительно – high
--Выведите в результат количество маршрутов в каждом полученном классе.

with cte as (
	select f.departure_airport, f.arrival_airport,
	    sum(tf.amount) as total_amount,
	    case
	        when sum(tf.amount) < 50000000 then 'low'
	        when sum(tf.amount) >= 50000000 and sum(tf.amount) < 150000000 then 'middle'
	        when sum(tf.amount) >= 150000000 then 'high'
	    end as financial_class
	from flights f
	join ticket_flights tf on f.flight_id = tf.flight_id
	group by f.departure_airport, f.arrival_airport)
select financial_class, count(*)
from cte
group by financial_class



--======== Задания со звездой ==============

--ЗАДАНИЕ №8
--Вычислите медиану стоимости перелетов, медиану стоимости бронирования и отношение медианы бронирования к медиане стоимости перелетов, результат округлите до сотых.


select percentile_cont(0.5) within group (order by tf.amount) as median_flight_cost,
	percentile_cont(0.5) within group (order by b.total_amount) as median_booking_cost,
	round(percentile_cont(0.5) within group (order by b.total_amount)::numeric / percentile_cont(0.5) within group (order by tf.amount)::numeric, 2) as ratio
from tickets t 
left join ticket_flights tf  on t.ticket_no = tf.ticket_no
left join bookings b on b.book_ref = t.book_ref

--ЗАДАНИЕ №9
--Найдите значение минимальной стоимости одного километра полёта для пассажира. Для этого определите расстояние между аэропортами и учтите стоимость перелета.
--Для поиска расстояния между двумя точками на поверхности Земли используйте дополнительный модуль earthdistance. 
--Для работы данного модуля нужно установить ещё один модуль – cube.
--Важно: 
--Установка дополнительных модулей происходит через оператор CREATE EXTENSION название_модуля.
--В облачной базе данных модули уже установлены.
--Функция earth_distance возвращает результат в метрах.

create extension cube

create extension earthdistance

with cte as (
	select dp.airport_name as departure_airport_name,
		ar.airport_name as arrival_airport_name, 
		avg(tf.amount) as average_flight_cost,
		min(tf.amount) as min_flight_cost,
		(earth_distance(ll_to_earth(dp.latitude, dp.longitude), ll_to_earth(ar.latitude, ar.longitude))::int)/1000 as distance_in_km
	from flights f 
	left join ticket_flights tf on f.flight_id = tf.flight_id 
	left join airports dp on f.departure_airport = dp.airport_code
	left join airports ar on ar.airport_code = f.arrival_airport   
	group by ar.airport_code, dp.airport_code)
select *, round(average_flight_cost/distance_in_km, 2) as avg_cost_per_km,
	round(min_flight_cost/distance_in_km, 2) as min_cost_per_km
from cte
order by min_cost_per_km

--Так как в условии не сказано минимальная цена за км в среднем, отсортировал по минимальной цене в целом по базе. Но на всякий случай добавил среднюю минимальную цену.
--Столбцы вывел все для большего понимания.
