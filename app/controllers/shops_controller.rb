class ShopsController < ApplicationController
  def index
    @shops = current_user.shops.once_customer

    if current_user.plan != 1
      flash[:notice] = "Subscribe #{view_context.link_to('here', '/')} to see your customers".html_safe
    end

    if params[:month]
      @shops = current_user.shops
      @shops = @shops.where("DATE_TRUNC('month', activated_on) = ?", params[:month])
      @month_param = params[:month]
      @cohort_month = Date.parse(params[:month]).strftime("%B %Y")
    end

    if params[:churn_timeframe].present?
      @shops = current_user.shops
    end

    if params[:search].present?
      @shops = current_user.shops
      @shops = @shops.where("name ILIKE ?", "%#{params[:search]}%")
    end

    if params[:sort_earnings] == 'asc'
      @earnings_asc = true
      @shops = @shops.reorder("total_earnings ASC")
    end

    if params[:sort_earnings] == 'desc'
      @shops = @shops.reorder("total_earnings DESC")
    end

    if params[:sort_payments] == 'asc'
      @payments_asc = true
      @shops = @shops.reorder("total_number_of_payments ASC")
    end

    if params[:sort_payments] == 'desc'
      @shops = @shops.reorder("total_number_of_payments DESC")
    end

    if params[:sort_avg_payments] == 'asc'
      @avg_payments_asc = true
      @shops = @shops.reorder("average_payment ASC")
    end

    if params[:sort_avg_payments] == 'desc'
      @shops = @shops.reorder("average_payment DESC")
    end

    if params[:sort_subscribed_in] == 'asc'
      @subscribed_in_asc = true
      @shops = @shops.reorder("activated_on ASC")
    end

    if params[:sort_subscribed_in] == 'desc'
      @shops = @shops.reorder("activated_on DESC")
    end

    if params[:filter_status] == 'active'
      @filter_status = 'active'
      @status_active = true
      @shops = @shops.active
    end

    if params[:filter_status] == 'churned'
      @filter_status = 'churned'
      @shops = @shops.churned
    end

    if params[:shop_ids]
      @churn_timeframe = params[:churn_timeframe]
      @shops = @shops.where(id: params[:shop_ids])
    end

    # paginate the shops with pagy gem
    @pagy, @shops = pagy(@shops, items: 20)
  end

  def cohort
    app = ShopifyApp.first

    @data = {}
    shops = app.shops

    # for each of the last 12 months get the number of activated shops in that month
    start_from = 12.months.ago.beginning_of_month

    month = start_from
    (12+1).times do |i|
      cohort_month = month
      @data[month] = []
      cohort_shops = shops.where("activated_on >= ? AND activated_on < ?", month, month + 1.month)
      @data[month] << cohort_shops.count
      @data[month] << cohort_shops.where("churned_on >= ? OR churned_on IS NULL", month.end_of_month).count
      
      (12-i).times do |j|
        month += 1.month
        # get the count of cohort shops that have not churned that month
        active_shops = cohort_shops.where("churned_on >= ? OR churned_on IS NULL", month.end_of_month).count

        # active_shops = cohort_shops.joins(:transactions)
        #                 .where("DATE_TRUNC('month', transactions.provider_created_at) = ?", month)
        #                 .distinct
        #                 .count
        
        @data[cohort_month] << active_shops
      end

      month = start_from + i.months
    end

    pp @data
  end
end

  # def main_chart
  #   days = params[:days].to_i
  #   # for each month get the number of customers that have at least one transaction
  #   # in that month
  #   customers_per_month = {}
  #   start_from = days.days.ago.beginning_of_day
  #   month = start_from
  #   days.times do |i|
  #     customers_per_month[month] = Shop.joins(:transactions)
  #                                     .where("DATE_TRUNC('month', transactions.provider_created_at) = ?", month) 
  #                                     .distinct
  #                                     .count
  #     month += 1.day
  #   end

  #   render json: customers_per_month
  # end

    # @cohorts = CohortMe.analyze(period: "months", 
    #                             activation_class: Shop,
    #                             activation_user_id: 'id',
    #                             activity_class: Transaction,
    #                             activity_user_id: 'shop_id',
    #                             start_from_interval: 4)

    # p '----------------'
    # pp @cohorts