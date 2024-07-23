select * from ipl_ball;
select * from ipl_matches;

--Your first priority is to get 2-3 players with high S.R who have faced at least 500 balls.And to do that you have to make a list of 10 players you want to bid in the auction so that when you try to grab them in auction you should not pay the amount greater than you have in the purse for a particular player.
select batsman,cast(strike_rate as decimal(5,2)) from (select batsman,sum(batsman_runs) as runs_scored,count(ball) as Balls_faced,cast(sum(batsman_runs) as float)/count(ball)*100 as strike_rate from ipl_ball where not extras_type in ('wides','no ball') group by batsman having count(ball)>500) order by strike_rate desc limit 10;

-- you need to get 2-3 players with good Average who have played more the 2 ipl seasons And to do that you have to make a list of 10 players you want to bid in the auction so that when you try to grab them in auction you should not pay the amount greater than you have in the purse for a particular player.
select batsman,average from (select batsman,cast(total_runs/total_dismissals as decimal(3,1))as average from(select batsman,sum(batsman_runs) as total_runs,sum(is_wicket) as total_dismissals,count(distinct extract(year from date)) as years_played from (select a.batsman,b.date,a.batsman_runs,a.is_wicket from ipl_ball as a left join ipl_matches as b on a.id=b.id) group by batsman) where years_played>2 order by average desc limit 10);

--Now you need to get 2-3 Hard-hitting players who have scored most runs in boundaries and have played more the 2 ipl season. To do that you have to make a list of 10 players you want to bid in the auction so that when you try to grab them in auction you should not pay the amount greater than you have in the purse for a particular player.
select batsman,cast(boundary_float_percentage as decimal(4,2)) as boundary_percentage from (select batsman,cast(boundary_runs as float)/total_runs*100 as boundary_float_percentage from (select batsman,count(distinct(extract(year from date))) as years_played,max(sum_of_runs) as total_runs,sum(batsman_runs) as boundary_runs from (select a.batsman,b.date,a.batsman_runs,sum(a.batsman_runs) over(partition by a.batsman) as sum_of_runs from ipl_ball as a left join ipl_matches as b on a.id=b.id) where batsman_runs=4 or batsman_runs=6 group by batsman) where years_played>2)order by boundary_percentage desc limit 10;

--Your first priority is to get 2-3 bowlers with good economy who have bowled at least 500 balls in IPL so far.To do that you have to make a list of 10 players you want to bid in the auction so that when you try to grab them in auction you should not pay the amount greater than you have in the purse for a particular player.
select bowler,round((cast(runs_conceded as float)/overs_bowled)::numeric,2) as economy from (select bowler,runs_conceded, cast(balls_bowled as float)/6 as overs_bowled from (select bowler,count(ball) as balls_bowled,sum(total_runs) as runs_conceded from ipl_ball group by bowler having count(ball)>500))order by economy limit 10 ;

--Now you need to get 2-3 bowlers with the best strike rate and who have bowled at least 500 balls in IPL so far.To do that you have to make a list of 10 players you want to bid in the auction so that when you try to grab them in auction you should not pay the amount greater than you have in the purse for a particular player
select bowler,cast(strike_rate as decimal(4,1)) as bowlers_strike_rate from(select bowler,cast(Total_balls_bowled as float)/wickets_taken as strike_rate from (select bowler,sum(is_wicket) as wickets_taken,max(balls_bowled) as Total_balls_bowled from (select bowler,is_wicket,dismissal_kind,count(ball) over(partition by bowler) as balls_bowled from ipl_ball where extras_type not in ('wides','noballs')) where not dismissal_kind in ('run out','retired hurt','obstructing the field')  group by bowler having max(balls_bowled)>500 order by wickets_taken desc) where wickets_taken>0 order by strike_rate)limit 10;

--Now you need to get 2-3 All_rounders with the best batting as well as bowling strike rate and who have faced at least 500 balls in IPL so far and have bowled minimum 300 balls.To do that you have to make a list of 10 players you want to bid in the auction so that when you try to grab them in auction you should not pay the amount greater than you have in the purse for a particular player.
with batsman_performance as (
    select
        batsman,
        cast(max(total_runs_scored) as float) / max(total_balls_faced) * 100 as batting_strike_rate
    from (
        select
            batsman,
            ball,
            sum(batsman_runs) over (partition by batsman) as total_runs_scored,
            count(ball) over (partition by batsman) as total_balls_faced
        from
            ipl_ball
	where extras_type not in ('wides','noballs')
    ) as batsman_aggregate
    group by
        batsman
    having
        max(total_balls_faced) > 500
),

bowler_performance as (
    select
        bowler,
        cast(max(total_balls_bowled) as float) / max(total_wickets_taken) as bowling_strike_rate
    from (
        select
            bowler,
            sum(is_wicket) over (partition by bowler) as total_wickets_taken,
            count(ball) over (partition by bowler) as total_balls_bowled
        from
            ipl_ball
        where
            dismissal_kind not in ('run out', 'retired hurt', 'obstructing the field') and extras_type not in ('wides','noballs')
    ) as bowler_aggregate
    group by
        bowler
    having
        max(total_balls_bowled) > 300
)
	select batsman_name,round(batting_strike_rate::numeric,2) as batting_strike_rate,round(bowling_strike_rate::numeric,2) as bowling_strike_rate from (select
    bp.batsman as batsman_name,
    bp.batting_strike_rate as batting_strike_rate,
    bowler_performance.bowler as bowler_name,
    bowler_performance.bowling_strike_rate as bowling_strike_rate,(bp.batting_strike_rate+bowler_performance.bowling_strike_rate) as All_rounder_strike_rate
from
    batsman_performance as bp
join
    bowler_performance on bp.batsman = bowler_performance.bowler order by all_rounder_strike_rate desc)limit 10;

--wicker_keeper
/*
Player should have been played at least 2 ipl seasons. 
Player should have good batting_strike_rate (i .e. S.R >125), balls faced should be > 500, good performance in Stumping, Catching and Fielding departments.
If player can bowl spin or medium pace the player should have good bowling strike rate (i.e. S.R < 20), economy<10 runs per over, should have bowled at least 300 balls or more, good performance in Stumping, Catching and Fielding departments
*/
--===============================================================================================================================================================================================================================================================================================================================================================================================================================================================
--Additional Questions for Final Assessment

--Deliveries is the table created using the IPL_Ball data whereas the Matches table has been created using the IPL_Matches data
create table Deliveries as (select * from ipl_ball);
create table Matches as (select * from IPL_Matches);

--Get the count of cities that have hosted an IPL match
select count(distinct(city)) as Count_cities from Matches; 

/*
Create table deliveries_v02 with all the columns of the table ‘deliveries’ and an additional column ball_result containing values boundary, dot or other depending on the total_run (boundary for >= 4, dot for 0 and other for any other number)
(Hint 1 : CASE WHEN statement is used to get condition based results)
(Hint 2: To convert the output data of the select statement into a table, you can use a subquery. Create table table_name as [entire select statement].
*/


create table deliveries_v02 as (select *,(
	case 
			when total_runs=0 then 'Dot Ball'
			when total_runs=1 then 'One Run'
			when total_runs=2 then 'Two Runs'
			when batsman_runs=3  then 'Three Runs'
			when total_runs>=4 then 'Boundary'
			end) as ball_result from Deliveries); 

select * from deliveries_v02;

--Write a query to fetch the total number of boundaries and dot balls from the deliveries_v02 table.
select ball_result,count(ball_result) as total_count from deliveries_v02 where ball_result in ('Boundary','Dot Ball') group by ball_result ;

--Write a query to fetch the total number of boundaries scored by each team from the deliveries_v02 table and order it in descending order of the number of boundaries scored.
select batting_team,count(ball_result) as Total_Boundaries_scored from deliveries_v02 where ball_result='Boundary' group by batting_team order by Total_Boundaries_scored desc;

--Write a query to fetch the total number of dot balls bowled by each team and order it in descending order of the total number of dot balls bowled.
select bowling_team,count(ball_result) as total_Dot_balls_bowled from deliveries_v02 where ball_result='Dot Ball' and bowling_team<>'NA' group by bowling_team order by total_Dot_balls_bowled desc; 

--Write a query to fetch the total number of dismissals by dismissal kinds where dismissal kind is not NA
select dismissal_kind,count(dismissal_kind) as dismissals from deliveries_v02 where dismissal_kind <>'NA' group by dismissal_kind order by dismissals desc;

--Write a query to get the top 5 bowlers who conceded maximum extra runs from the deliveries table
select bowler,sum(extra_runs) as max_extra_runs from deliveries_v02 group by bowler order by max_extra_runs desc limit 5 ;

--Write a query to create a table named deliveries_v03 with all the columns of deliveries_v02 table and two additional column (named venue and match_date) of venue and date from table matches
create table deliveries_v03 as (select * ,(select date as match_date from Matches where deliveries_v02.id=Matches.id ),(select venue as venue from Matches where deliveries_v02.id=Matches.id )from deliveries_v02);
select * from deliveries_v03;

--Write a query to fetch the total runs scored for each venue and order it in the descending order of total runs scored.
select venue,sum(total_runs) as total_runs_scored from deliveries_v03 group by venue order by total_runs_scored desc;

--Write a query to fetch the year-wise total runs scored at Eden Gardens and order it in the descending order of total runs scored.
select venue,sum(total_runs) as total_runs ,extract(year from match_date) as match_year from deliveries_v03 where venue='Eden Gardens' group by venue,match_year order by total_runs desc ;

