class TimelineController < ApplicationController
  def index
    @data = {}

    if current_user.plan != 1
      flash[:notice] = "Subscribe #{view_context.link_to('here', '/')} to see your timeline".html_safe
    end

    shops = current_user.shops
    current_date = Date.today

    36.times do |i|
      date = (current_date - i.months).strftime("%B %Y")
      customers_beginning_of_month = shops.customer_on_date((current_date - i.months).beginning_of_month).count
      
      new_customers = shops.new_customer_during_month(current_date - i.months)
      new_customers_ids = new_customers.pluck(:id)
      new_customers_count = new_customers.count
      new_mrr = new_customers.sum(:monthly_subscription)

      churned_customers = shops.churned_during_month(current_date - i.months)
      churned_customers_ids = churned_customers.pluck(:id)
      churned_customers_count = churned_customers.count
      churned_mrr = churned_customers.once_mrr_customer.sum(:monthly_subscription)

      # mrr = shops.customer_on_date((current_date - i.months).beginning_of_month).sum(:monthly_subscription)
      month_transactions = current_user.transactions.where("provider_created_at >= ? AND provider_created_at < ?", (current_date - i.months).beginning_of_month, (current_date - (i-1).months).beginning_of_month)
      actual_mrr = month_transactions.sum(:net_amount)
      arpu = (actual_mrr / month_transactions.count).round(1)

      @data[i] = {
        "date": date,
        "active_at_beginning_of_month": customers_beginning_of_month,
        "new": new_customers_count,
        "new_customers_ids": new_customers_ids,
        "new_mrr": new_mrr,
        "churned": churned_customers_count,
        "churned_customers_ids": churned_customers_ids,
        "churned_mrr": churned_mrr,
        # "net_mrr_change": new_mrr - churned_mrr,
        "actual_mrr": actual_mrr,
        "arpu": arpu
      }
    end
  end
end