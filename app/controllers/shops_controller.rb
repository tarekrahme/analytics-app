class ShopsController < ApplicationController
  def index
    @shops = current_user.shops.customer

    if params[:month]
      @shops = @shops.where("DATE_TRUNC('month', activated_on) = ?", params[:month])
      @month_param = params[:month]
      @cohort_month = Date.parse(params[:month]).strftime("%B %Y")
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
    12.times do |i|
      cohort_month = month
      @data[month] = []
      cohort_shops = shops.where("activated_on >= ? AND activated_on < ?", month, month + 1.month)
      @data[month] << cohort_shops.count
      
      (12-i).times do |j|
        month += 1.month
        # get the count of cohort shops that have at least one transaction in the month
        active_shops = cohort_shops.joins(:transactions)
                        .where("DATE_TRUNC('month', transactions.provider_created_at) = ?", month)
                        .distinct
                        .count
        
        @data[cohort_month] << active_shops
      end

      month = start_from + i.months
    end

    pp @data
  end
end

    # @cohorts = CohortMe.analyze(period: "months", 
    #                             activation_class: Shop,
    #                             activation_user_id: 'id',
    #                             activity_class: Transaction,
    #                             activity_user_id: 'shop_id',
    #                             start_from_interval: 4)

    # p '----------------'
    # pp @cohorts