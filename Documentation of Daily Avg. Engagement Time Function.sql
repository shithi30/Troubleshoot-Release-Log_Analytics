/*
- Viz: https://datastudio.google.com/u/2/reporting/72e9308f-7d7e-45e6-931b-8b482fb8aeab/page/2TETC
- Data: 
- Function: data_vajapora.fn_group_wise_daily_avg_engagement_time()
- Table: data_vajapora.group_wise_daily_avg_engagement_time
- File: 
- Path: 
- Document/Presentation: 
- Email thread: 
- Notes (if any): 
	- Function Documentation Instruction: https://docs.google.com/document/d/1YDDlQOYPgJq0xxocYBsBDxM0K4KeBOi9P21s47u2GLk/edit
*/

CREATE OR REPLACE FUNCTION data_vajapora.fn_group_wise_daily_avg_engagement_time()
 RETURNS void
 LANGUAGE plpgsql
AS $function$

/*
=================================================================================================================================================
	 * Developed by 		: Shithi Mitra
	 * Supervised by		: Md.Nazrul Islam
	 * Date of Development	: 03-Aug-2021
	 * Date	of Documentation: 04-Aug-2021
	 * Comments/Notes by	: Shithi Maitra
	 * Function Version		: 1st version
	 --------------------------------------------------------------------------------------------------------------------------------------------
	 * Story Behind this Function:
		  What group of users spend how many minutes daily on TK platform may be an important product metric. 
		  This may indicate importance of TK in merchants' lives, which may in turn indicate monetary value of their time invested in TK.
		  Below are definitions of the user-groups covered in this function:
		  >> Roaming DAU    : Merchants who have been active on the app, but have not recorded any transaction on any given day 
		  >> DAU            : Merchants who have been active on the app on any given day 
		  >> 10RAU          : Merchants who have transacted >=10 days in the last 14 days
		  >> 3RAU           : Merchants who have transacted >=3 days in the last 7 days
		  >> FAU            : Merchants who have transacted in all 14 days of the last 14 days 
	  -------------------------------------------------------------------------------------------------------------------------------------------
	  * List of Tables Generated by this Function:
		  >> Auxiliary Table(s): none
		  >> Resultant Table(s): data_vajapora.group_wise_daily_avg_engagement_time
=================================================================================================================================================
*/

declare
	v_date date:=current_date-5;

begin
	/* ---------------------------------------------Block-01---------------------------------------------
  	   First, we delete last few days' data and regenerate the results.
  	   This is because, data is often synced afterwards as users turn on mobile data. 
	*/ --------------------------------------------------------------------------------------------------
	delete from data_vajapora.group_wise_daily_avg_engagement_time
	where event_date>=v_date; 
	
	/* ---------------------------------------------Block-02---------------------------------------------
  	   Second, we identify recent roamers.
  	   This is for calculating engagement time of users who opened the app, but recorded no txns.
	*/ --------------------------------------------------------------------------------------------------
	execute 'select * from tallykhata.fn_roaming_users()'; 

	/* ---------------------------------------------Block-03---------------------------------------------
  	   Third, we insert daily avg. engagement time in minutes.
  	   This is done for each user-group: DAUs, PUs, RAUs, FAUs.
	*/ --------------------------------------------------------------------------------------------------
	raise notice 'New OP goes below:'; 
	loop
		insert into data_vajapora.group_wise_daily_avg_engagement_time
		select 
			event_date, 
			avg(case when roaming_date is not null then sec_with_tk else null end)/60.00 as roaming_dau_avg_min_with_tk,
			avg(sec_with_tk)/60.00 as dau_avg_min_with_tk,
			avg(case when rau_3_date is not null then sec_with_tk else null end)/60.00 as rau_3_avg_min_with_tk,
			avg(case when rau_10_date is not null then sec_with_tk else null end)/60.00 as rau_10_avg_min_with_tk,
			avg(case when fau_date is not null then sec_with_tk else null end)/60.00 as fau_avg_min_with_tk,
			avg(case when pu_date is not null then sec_with_tk else null end)/60.00 as pu_avg_min_with_tk
		from 
			(select event_date, mobile_no, sec_with_tk
			from tallykhata.daily_times_spent_individual_data
			where event_date=v_date
			) tbl1 
			
			left join 
			
			(select rau_date as rau_10_date, mobile_no as rau_10_mobile_no
			from tallykhata.tallykahta_regular_active_user_new
			where 
				rau_category=10
				and rau_date=v_date
			) tbl2 on(tbl1.mobile_no=tbl2.rau_10_mobile_no and tbl1.event_date=tbl2.rau_10_date)
			
			left join 
			
			(select rau_date as rau_3_date, mobile_no as rau_3_mobile_no
			from tallykhata.tallykhata_regular_active_user
			where 
				rau_category=3
				and rau_date=v_date
			) tbl3 on(tbl1.mobile_no=tbl3.rau_3_mobile_no and tbl1.event_date=tbl3.rau_3_date)
			
			left join 
			
			(select report_date as fau_date, mobile as fau_mobile_no
			from tallykhata.fau_for_dashboard
			where 
				category in('fau', 'fau-1')
				and report_date=v_date
			) tbl4 on(tbl1.mobile_no=tbl4.fau_mobile_no and tbl1.event_date=tbl4.fau_date)
			
			left join 
			
			(select roaming_date, mobile_no as roamer_mobile_no
			from tallykhata.roaming_users
			where roaming_date=v_date
			) tbl5 on(tbl1.mobile_no=tbl5.roamer_mobile_no and tbl1.event_date=tbl5.roaming_date)
			
			left join 
			
			(select distinct report_date as pu_date, mobile_no as pu_mobile_no
			from tallykhata.tk_power_users_10
			where report_date=v_date
			) tbl6 on(tbl1.mobile_no=tbl6.pu_mobile_no and tbl1.event_date=tbl6.pu_date)
		group by 1; 
		raise notice 'Data generated for: %', v_date; 
		
		/* ---------------------------------------------Block-04---------------------------------------------
  	   	   Here, we increment the loop control variable for generating data until yesterday.
		*/ --------------------------------------------------------------------------------------------------
		v_date:=v_date+1;
		if v_date=current_date then exit;
		end if; 
	end loop;

	/* ---------------------------------------------End Block---------------------------------------------
   	   Thanks, the business/computational logics for the function end here.
   	   For further clarification, please contact: 
   	   Shithi Maita, Data & BI | TallyKhata
	*/ ---------------------------------------------------------------------------------------------------

END;
$function$
;

/*
select data_vajapora.fn_group_wise_daily_avg_engagement_time();

select *
from data_vajapora.group_wise_daily_avg_engagement_time;
*/

