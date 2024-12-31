use project1

select * from credit_card_transcations

select count(distinct transaction_id) from credit_card_transcations;--unique

select distinct exp_type from credit_card_transcations; -- 4 cards 2 genders  2013-2015 data in dates column

select amount from credit_card_transcations order by amount desc

select max(transaction_date),min(transaction_date) from credit_card_transcations


solve below questions

1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends

with cte as (
select city,sum(amount) as spends from credit_card_transcations group by city),
tlt_spend as (select sum(cast(spends as bigint)) as total_spend from cte)
select top 5 *,round((spends*1.0/total_spend)*100,2) as perc_contri from cte c,tlt_spend s
order by spends desc




2- write a query to print highest spend month and amount spent in that month for each card type

with cte as (
select card_type,datepart(year,transaction_date) as year,datepart(month,transaction_date) as month,sum(amount) as spend from credit_card_transcations
group by card_type,datepart(year,transaction_date),datepart(month,transaction_date)),
final_tab as (select *,max(spend) over(partition by card_type) as highest_spend from cte)
select * from final_tab where spend = highest_spend


3- write a query to print the transaction details(all columns from the table) for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte as (
select *,sum(cast(amount as bigint)) over(partition by card_type order by transaction_date,transaction_id) as spend from credit_card_transcations),
ranks_tab as (select *,rank() over(partition by card_type order by spend) as ranks
from cte where spend >=1000000)
select * from  ranks_tab where ranks =1



4- write a query to find city which had lowest percentage spend for gold card type

with cte as (
select top 1 city,card_type,sum(amount) as amount
,sum(case when card_type='Gold' then amount end) as gold_amount
from credit_card_transcations
group by city,card_type)
select 
city,sum(gold_amount)*1.0/sum(amount) as gold_ratio
from cte
group by city
having count(gold_amount) > 0 and sum(gold_amount)>0
order by gold_ratio;

5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with cte as (
select city,exp_type,sum(amount) spend from credit_card_transcations group by city,exp_type),
rank_tab as (select *,rank() over(partition by city order by spend desc) as max_ranks,rank() over(partition by city order by spend asc) as min_ranks from cte
)
select city,max(case when max_ranks = 1 then exp_type end) as highest_expense_type, max(case when min_ranks = 1 then exp_type end) as lowest_expense_type from rank_tab group by city




6- write a query to find percentage contribution of spends by females for each expense type

with cte as (
select exp_type,sum(amount) female_spend from credit_card_transcations where gender = 'F' group by exp_type),
tlt as (select exp_type,sum(amount) total_spend from credit_card_transcations group by exp_type)
select c.exp_type,female_spend,total_spend,(female_spend*1.0/total_spend*100) as perc_female_spend from cte c
inner join tlt t on c.exp_type = t.exp_type



7- which card and expense type combination saw highest month over month growth in Jan-2014

with cte as (
select card_type,exp_type,datepart(year,transaction_date) as years,datepart(month,transaction_date) as months,
sum(amount) sums from credit_card_transcations group by card_type,exp_type,datepart(year,transaction_date),datepart(month,transaction_date)
), running as (
select *,lag(sums,1) over (partition by card_type,exp_type order by years,months) as run_sum from cte)
select top 1 *,(sums-run_sum) as inc from running where years = 2014 and months = 1 order by inc desc


8- during weekends which city has highest total spend to total no of transcations ratio 

select datepart(w,transaction_date) from credit_card_transcations

select top 1 city,sum(amount)/count(1) ratio from credit_card_transcations where datepart(w,transaction_date) in (1,7) group by city order by ratio desc



9- which city took least number of days to reach its 500th transaction after the first transaction in that city

with cte as(
select city, transaction_date, row_number() over(partition by city order by transaction_date asc) num from credit_card_transcations),
firsts as (
select *,lag(transaction_date,1) over(partition by city order by transaction_date) first_date from cte where num in (1,500))
select top 1 city,datediff(day,first_date,transaction_date) as diff from firsts where num = 500 order by diff asc
