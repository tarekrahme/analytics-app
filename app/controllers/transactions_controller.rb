class TransactionsController < ApplicationController
  def index
    user = current_user

    if user.plan != 1
      flash[:notice] = "Subscribe #{view_context.link_to('here', '/')} to see your earnings".html_safe
    end

    @transactions = user.transactions

    if params[:days].present?
      if params[:days] == "this_month"
        @days = Date.today - Date.today.at_beginning_of_month + 1
        transactions_since_beginning_of_period = @transactions.where("provider_created_at >= ?", Date.today.at_beginning_of_month)
      else
        @days = params[:days].to_i
        transactions_since_beginning_of_period = @transactions.where("provider_created_at >= ?", @days.days.ago)
      end
    else
      @days = 30
      transactions_since_beginning_of_period = @transactions.where("provider_created_at >= ?", @days.days.ago)
    end

    shops = user.shops

    @total_earnings = transactions_since_beginning_of_period.sum(:net_amount)
    @number_of_transactions = transactions_since_beginning_of_period.count
    @previous_total_earnings = @transactions.where("provider_created_at >= ?", (@days + @days).days.ago).where("provider_created_at < ?", @days.days.ago).sum(:net_amount)
    @change = ((@total_earnings - @previous_total_earnings) / @previous_total_earnings.to_f * 100).round(2)
    @number_of_customers = shops.current_customer.count
    @average_revenue_per_customer = (@total_earnings / @number_of_transactions).round(2)
    @average_revenue_per_day = (@total_earnings / @days).round(2)
    churned_shops = shops.churned_since(@days.days.ago)
    @churned_shops_ids = churned_shops.pluck(:id)
    @churned_shops_count = @churned_shops_ids.count
    @number_of_customers_at_beginning_of_period = shops.customer_on_date(@days.days.ago).count
    @churn_denominator = (@number_of_customers_at_beginning_of_period + @number_of_customers) / 2.0
    @user_churn = (@churned_shops_count / @churn_denominator.to_f * 100).round(2)
    @revenue_churn = churned_shops.sum(:monthly_subscription).round(2)
  end

  def main_chart
    days = params[:days].to_i
    transactions = Transaction.where("provider_created_at >= ?", days.days.ago)
                            .group_by_day(:provider_created_at)
                            .sum(:net_amount)
    cumulative_sum = 0
    data = transactions.map { |date, amount| cumulative_sum += amount; [date, cumulative_sum] }

    render json: data
  end
end