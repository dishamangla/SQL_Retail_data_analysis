CREATE DATABASE RETAIL_DATA_ANALYSIS; --Creating a new database 
USE RETAIL_DATA_ANALYSIS; --making the database active

--Data Preparation and Understanding
--Q1.what is the total number of rows in each of the 3 tables in the database?

select count(*) as [Total number of rows] from Customer;
select count(*) as [Total number of rows] from prod_cat_info;
select count(*) as [Total number of rows] from Transactions;

--Q2.what is the total number of transactions that have a return?

select count(transaction_id) as [Total_Transactions_of_returnType] from Transactions where cast(total_amt as float)<0;

--Q3.As you would have noticed,the dates provided across the datasets are not in a correct format.As first steps, pls convert
--the date variables into valid date formats before proceeding ahead.

select customer_Id,convert(Date,DOB,105) as DOB,Gender,city_code from Customer; 
select transaction_id,cust_id,Convert(Date,tran_date,105) as tran_date,prod_subcat_code,prod_cat_code,Qty,Rate	,
Tax,total_amt,Store_type from Transactions;

--Q4.what is the time range of the transaction data available for analysis?show the output in number of days,months and years
--simultaneously in different columns.
--method 1
with T1 as (select Top 1 '1' as R,Convert(Date,tran_date,105) as Last_date from Transactions order by Last_date desc)  ,
T2 as (select Top 1 '1' as R ,Convert(Date,tran_date,105) as first_date from Transactions order by first_date asc)
select datepart(day,T1.Last_date )-datepart(day,T2.first_date ) as [Days] ,
datepart(month,T1.Last_date )-datepart(month,T2.first_date ) as [month]
,datediff(year,T2.first_date,T1.Last_date) as [year] from T1 inner join T2 on T1.R=T2.R 

--method 2
with T1 as (select Top 1 '1' as R,Convert(Date,tran_date,105) as Last_date from Transactions order by Last_date desc)  ,
T2 as (select Top 1 '1' as R ,Convert(Date,tran_date,105) as first_date from Transactions order by first_date asc)
select datediff(day,T2.first_date,T1.Last_date) as [Days] ,
datediff(month,T2.first_date,T1.Last_date) as [month]
,datediff(year,T2.first_date,T1.Last_date) as [year] from T1 inner join T2 on T1.R=T2.R 

--Q5.Which product category does the sub category "DIY" belong to?

select Prod_cat from prod_cat_info where prod_subcat in ('DIY');

--Data Analysis
--Q1.Which channel is most frequently used for transactions?
select channel from (
select top 1 store_type as channel ,count(transaction_id) as [No.of Transactions] from Transactions group by Store_type 
order by [No.of Transactions] desc ) as T;

--Q2.What is the count of Male and Female customers in the database?

select Gender,count(Customer_id) as [Total ] from Customer where Gender like '%M%' group by gender Union all
select Gender,count(Customer_id) as [Total ] from Customer where Gender like '%F%' group by gender;

--Q3.From which city do we have the maximum number of customers and how many?

select Top 1 city_code ,count(customer_id) as Total_Customers from Customer group by city_code order by Total_Customers desc;

--Q4.How many sub-categories are there under the books category?

select count(Prod_Subcat) as [ Total sub-categories] from prod_cat_info where lower(prod_cat) = 'books';

--Q5.What is the maximum quantity of products ever ordered?

select top 1 qty as max_quantity from Transactions order by cast(qty as int) desc;

--Q6.what is the net total revenue generated in categories Electronics and Books?
select round(SUM(cast(T.Total_amt as float)),2) as Total_revenue from Transactions as T 
inner join prod_cat_info as P on  T.prod_cat_code=P.prod_cat_code and T.prod_subcat_code=P.prod_sub_cat_code
where prod_cat in ('Electronics','Books');


--Q7.How many customers have>10 transactions with us,excluding returns?

select count(cust_id) as [Total Customers] from(select cust_id,count(cust_id) as [TotalCustomers] from Transactions where cast(total_amt as float)>0 
group by cust_id having count(Transaction_id)>10) as T1;

--Q8.What is the combined revenue earned from the "Electronics" & "Clothing" categories,from "Flagship stores"?

select round(sum(cast(total_amt as float)),2) as Total_Revenue from Transactions as T
left join prod_cat_info as P on T.prod_cat_code=P.prod_cat_code  and T.prod_subcat_code=P.prod_sub_cat_code
where T.Store_type like 'Flagship%' and P.prod_cat in('Clothing ','Electronics');

--Q9.What is the total revenue generated from "Male" Customers in "Electronics" Category?Output Should display total revenue by
--prod sub-cat.

select P.prod_subcat, round(sum(cast(T.total_amt as float)),2) as Total_Revenue from Transactions as T 
left join prod_cat_info as P on T.prod_cat_code=P.prod_cat_code and T.prod_subcat_code=P.prod_sub_cat_code
left join customer as C on C.customer_Id=T.cust_id
where C.Gender='M' and P.prod_cat in('Electronics')
group by P.prod_subcat;

--Q10.What is the percentage of sales and returns by product sub category;display only top 5 sub categories in terms of sales?

select Sub_Categories,round(sum(sales)/(select sum(cast(total_amt as float)) from Transactions)*100,2) as [Sales in Percentage],
abs(round(sum([return])/(select sum(cast(total_amt as float)) from Transactions)*100,2)) as [Returns in Percentage]
from (
select P.prod_subcat as Sub_Categories,cast(T.total_amt as float)
as Sales,case when cast(total_amt as float)<0 
then (cast(total_amt as float)) else 0 
end as [Return]
from Transactions as T 
left join prod_cat_info as P on T.prod_cat_code=P.prod_cat_code and T.prod_subcat_code=P.prod_sub_cat_code
where P.prod_subcat in (select top 5 P.prod_subcat  from Transactions as T 
left join prod_cat_info as P on T.prod_cat_code=P.prod_cat_code and T.prod_subcat_code=P.prod_sub_cat_code
group by  P.prod_subcat
order by sum(cast(total_amt as float)) desc)
) as T
group by Sub_Categories;

--Q11.For all customers aged between 25 to 35 years find what is the net total revenue generated by these consumers in last 30days 
--of transcations from max transcation date available in the data?

select round(sum(cast(total_amt as float)),2) as Total_Revenue  from Transactions as T 
inner join Customer as C on T.cust_id=C.customer_Id
where DATEDIFF(Year,convert(date,DOB,105),(select MAX(convert(date,tran_date,105)) as d from transactions )) 
between 25 and 35 
and DATEDIFF(day,(select MAX(convert(date,tran_date,105)) as d from transactions  ),
dateadd(day,-30,(select MAX(convert(date,tran_date,105)) as d from transactions)))=-30 ;

--Q12.which product category has seen the max value of returns in the last 3 months of transactions?

select top 1 P.Prod_cat from prod_cat_info as P 
left join Transactions as T on T.prod_cat_code=P.prod_cat_code and T.prod_subcat_code=P.prod_sub_cat_code
where cast(total_amt as float)<0 and DATEDIFF(month,(select MAX(convert(date,tran_date,105)) as d from transactions  ),
dateadd(month,-3,(select MAX(convert(date,tran_date,105)) as d from transactions   )))=-3 
group by P.Prod_cat
order by count(transaction_id) desc;

--Q13.Which store sells the maximum products;by value of sales amount and by quantity sold?

select  Store_type from(select top 1 Store_type ,sum(cast(total_amt as float)) as tot_sales,
sum(cast(Qty as float)) as tot_Qty from Transactions 
group by Store_type order by tot_sales desc,tot_Qty desc) as T1;

--Q14.What are the categories for which average revenue is above the overall average.

select Prod_cat as Categories from (select P.Prod_cat,AVG(cast(total_amt as float)) as [Avg] from prod_cat_info as P
inner join Transactions as T 
on T.prod_cat_code=P.prod_cat_code and T.prod_subcat_code=P.prod_sub_cat_code 
group by P.prod_cat
having AVG(cast(total_amt as float)) >(select AVG(cast(total_amt as float)) from Transactions)) as T2

--Q15.find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of 
--quantity sold.

with TBL1 as (select top 5 prod_cat_code,sum(cast(qty as int)) as tot_qty from Transactions group by prod_cat_code
order by tot_qty desc),
TBL2 as ( select P.Prod_subcat,P.prod_cat,T.prod_cat_code,round(AVG(cast(T.total_amt as float)),2) as [Average] ,
round(SUM(cast(T.total_amt as float)),2) as Total_Revenue 
from prod_cat_info as P
inner join Transactions as T 
on T.prod_cat_code=P.prod_cat_code and T.prod_subcat_code=P.prod_sub_cat_code 
group by T.prod_cat_code,P.prod_subcat,P.prod_cat)
select TBL2.* from TBL1 inner join TBL2 on TBL2.prod_cat_code=TBL1.prod_cat_code;
