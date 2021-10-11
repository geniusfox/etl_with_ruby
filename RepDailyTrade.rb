#!/bin/ruby
require File.expand_path('../boot',__FILE__)


#按照用户+交易类型汇总订单数量/trade数量和交易量数据
class  RepDailyTrade < EtlMaker
	self.table_name ='rep_daily_trades'
	self.primary_key="id".to_sym

	def retrieve_daily_trades(trade_date) 
		RepDailyTrade.where(:sep_date=>trade_date).delete_all #清除日期数据
		rep_sql="select  date_format(convert_tz(a.update_time, \"+08:00\", \"-04:00\"),'%Y-%m-%d') as sep_date, "
		rep_sql+="case when is_option = 1 then 'option' else 'equity'  end as symbol_type, apex_account_id, "
		rep_sql+="concat(last_name,first_name) as username, "
		rep_sql+="count(a.id) as orders, sum(trades) as trades, sum(abs(filled_amount)) as qty, "
		rep_sql+="group_concat(distinct(symbol)) as symbols "
		rep_sql+="from trade_core.order_summary a "
		rep_sql+="left join (select client_order_id,count(*) as trades from trade_core.eod_trade group by client_order_id)b on a.client_order_id = b.client_order_id "
		rep_sql+="left join account_core.user_detail c on c.user_id=a.user_id "
		rep_sql+="where order_status = 3 and left(apex_account_id,3) = '7XJ'"
		rep_sql+="and date_format(convert_tz(a.update_time, \"+08:00\", \"-04:00\"),'%Y-%m-%d') = '#{trade_date}' "
		rep_sql+="group by sep_date,symbol_type,apex_account_id "
		etl(rep_sql) {|item|
			RepDailyTrade.create({
				:sep_date=>item.sep_date,
				:symbol_type => item.symbol_type,
				:apex_account_id=> item.apex_account_id,
				:username => item.username,
				:trades=> (item.trades || 0),
				:orders=> item.orders,
				:qty => item.qty,
				:symbols => item.symbols
			})
		}
	end
end


if __FILE__ == $0
    #sep_date = ARGV[0]  || (Time.now()-24*60*60).strftime("%Y-%m-%d")
    trade_date=  TradeDay.get_previous_day()
    RepDailyTrade.new { |item|
    	item.retrieve_daily_trades trade_date
    }
end





