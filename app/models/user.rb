# == Schema Information
#
# Table name: users
#
#  id                       :bigint           not null, primary key
#  email                    :string           default(""), not null
#  encrypted_password       :string           default(""), not null
#  reset_password_token     :string
#  reset_password_sent_at   :datetime
#  remember_created_at      :datetime
#  sign_in_count            :integer          default(0), not null
#  current_sign_in_at       :datetime
#  last_sign_in_at          :datetime
#  current_sign_in_ip       :string
#  last_sign_in_ip          :string
#  confirmation_token       :string
#  confirmed_at             :datetime
#  confirmation_sent_at     :datetime
#  unconfirmed_email        :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  access_token             :string
#  organisation_provider_id :string
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :trackable

  encrypts :access_token

  has_many :shopify_apps, dependent: :destroy
  has_many :shops, -> { order('shops.name ASC') }
  has_many :transactions, through: :shopify_apps
  has_many :plans, through: :shopify_apps
  has_many :events, through: :shopify_apps

  def retreive_data(since: nil)
    require "httparty"
    require "json"

    # Set the GraphQL query
    query = <<-GRAPHQL
      query($cursor: String, $since: DateTime) {
        transactions(after: $cursor, first: 80, types: [APP_SUBSCRIPTION_SALE], createdAtMin: $since) {
          edges {
            cursor
            node {
              id
              createdAt
              ... on AppSubscriptionSale {
                billingInterval
                chargeId
                grossAmount {
                  amount
                }
                shopifyFee {
                  amount
                }
                netAmount {
                  amount
                }
                app {
                  name
                  id
                }
                shop {
                  myshopifyDomain
                  id
                  name
                }
              }
            }
          }
          pageInfo {
            hasNextPage
          }
        }
      }
    GRAPHQL

    # Set the endpoint URL and access token
    endpoint = "https://partners.shopify.com/#{organisation_provider_id}/api/2023-04/graphql.json"

    # Prepare the headers and request body
    headers = {
      "Content-Type" => "application/json",
      "X-Shopify-Access-Token" => access_token
    }

    cursor = nil
    has_next_page = true
    since = since.present? ? since : "2016-01-01T00:00:00Z"

    while has_next_page do
      body = { query: query, variables: { cursor: cursor, since: since } }

      # Make the POST request
      response = HTTParty.post(endpoint, headers: headers, body: body.to_json)

      # Parse the JSON response
      result = JSON.parse(response.body)
      
      return unless result["data"]
      transactions = result["data"]["transactions"]["edges"]

      transactions.each do |transaction_edge|
        transaction = transaction_edge["node"]

        transaction_id = transaction["id"]
        transaction_created_at = transaction["createdAt"]
        transaction_billing_interval = transaction["billingInterval"]
        transaction_gross_amount = transaction["grossAmount"]["amount"]
        transaction_shopify_fee = transaction["shopifyFee"]["amount"]
        transaction_net_amount = transaction["netAmount"]["amount"]
        transaction_type = "APP_SUBSCRIPTION_SALE"
        
        app_name = transaction["app"]["name"]
        app_id = transaction["app"]["id"]

        shop_shopify_domain = transaction["shop"]["myshopifyDomain"]
        shop_provider_id = transaction["shop"]["id"]
        shop_name = transaction["shop"]["name"]
        
        begin
          app = ShopifyApp.find_or_create_by(user_id: id, provider_id: app_id) do |app|
            app.name = app_name
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end
        
        begin
          shop = Shop.find_or_create_by(user_id: id, provider_id: shop_provider_id) do |shop|
            shop.shopify_app_id = app.id
            shop.shopify_domain = shop_shopify_domain
            shop.provider_id = shop_provider_id
            shop.name = shop_name
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end

        begin
          Transaction.find_or_create_by(shop_id: shop.id, provider_id: transaction_id) do |transaction|
            transaction.shopify_app_id = app.id
            transaction.provider_created_at = transaction_created_at
            transaction.interval = transaction_billing_interval
            transaction.gross_amount = transaction_gross_amount
            transaction.net_amount = transaction_net_amount
            transaction.shopify_fee = transaction_shopify_fee
            transaction.transaction_type = transaction_type
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end

      has_next_page = result["data"]["transactions"]["pageInfo"]["hasNextPage"]
      cursor = result["data"]["transactions"]["edges"].last["cursor"] if has_next_page
      sleep 0.3
    end

    # Set the GraphQL query
    query = <<-GRAPHQL
      query($cursor: String, $since: DateTime) {
        transactions(after: $cursor, first: 80, types: [APP_SALE_ADJUSTMENT], createdAtMin: $since) {
          edges {
            cursor
            node {
              id
              createdAt
              ... on AppSaleAdjustment {
                chargeId
                grossAmount {
                  amount
                }
                shopifyFee {
                  amount
                }
                netAmount {
                  amount
                }
                app {
                  name
                  id
                }
                shop {
                  myshopifyDomain
                  id
                  name
                }
              }
            }
          }
          pageInfo {
            hasNextPage
          }
        }
      }
    GRAPHQL

    cursor = nil
    has_next_page = true

    while has_next_page do
      body = { query: query, variables: { cursor: cursor, since: since } }

      # Make the POST request
      response = HTTParty.post(endpoint, headers: headers, body: body.to_json)

      # Parse the JSON response
      result = JSON.parse(response.body)
      
      return unless result["data"]
      transactions = result["data"]["transactions"]["edges"]

      transactions.each do |transaction_edge|
        transaction = transaction_edge["node"]

        transaction_id = transaction["id"]
        transaction_created_at = transaction["createdAt"]
        transaction_gross_amount = transaction["grossAmount"]["amount"]
        transaction_shopify_fee = transaction["shopifyFee"]["amount"]
        transaction_net_amount = transaction["netAmount"]["amount"]
        transaction_type = "APP_SALE_ADJUSTMENT"
        
        app_name = transaction["app"]["name"]
        app_id = transaction["app"]["id"]

        shop_shopify_domain = transaction["shop"]["myshopifyDomain"]
        shop_provider_id = transaction["shop"]["id"]
        shop_name = transaction["shop"]["name"]
        
        begin
          app = ShopifyApp.find_or_create_by(user_id: id, provider_id: app_id) do |app|
            app.name = app_name
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end
        
        begin
          shop = Shop.find_or_create_by(user_id: id, provider_id: shop_provider_id) do |shop|
            shop.shopify_app_id = app.id
            shop.shopify_domain = shop_shopify_domain
            shop.provider_id = shop_provider_id
            shop.name = shop_name
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end

        begin
          Transaction.find_or_create_by(shop_id: shop.id, provider_id: transaction_id) do |transaction|
            transaction.shopify_app_id = app.id
            transaction.provider_created_at = transaction_created_at
            transaction.gross_amount = transaction_gross_amount
            transaction.net_amount = transaction_net_amount
            transaction.shopify_fee = transaction_shopify_fee
            transaction.transaction_type = transaction_type
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end

      has_next_page = result["data"]["transactions"]["pageInfo"]["hasNextPage"]
      cursor = result["data"]["transactions"]["edges"].last["cursor"] if has_next_page
      sleep 0.3
    end

    # Set the GraphQL query
    query = <<-GRAPHQL
      query($cursor: String, $since: DateTime) {
        transactions(after: $cursor, first: 80, types: [APP_ONE_TIME_SALE], createdAtMin: $since) {
          edges {
            cursor
            node {
              id
              createdAt
              ... on AppOneTimeSale {
                chargeId
                grossAmount {
                  amount
                }
                shopifyFee {
                  amount
                }
                netAmount {
                  amount
                }
                app {
                  name
                  id
                }
                shop {
                  myshopifyDomain
                  id
                  name
                }
              }
            }
          }
          pageInfo {
            hasNextPage
          }
        }
      }
    GRAPHQL

    cursor = nil
    has_next_page = true

    while has_next_page do
      body = { query: query, variables: { cursor: cursor, since: since } }

      # Make the POST request
      response = HTTParty.post(endpoint, headers: headers, body: body.to_json)

      # Parse the JSON response
      result = JSON.parse(response.body)
      
      return unless result["data"]
      transactions = result["data"]["transactions"]["edges"]

      transactions.each do |transaction_edge|
        transaction = transaction_edge["node"]

        transaction_id = transaction["id"]
        transaction_created_at = transaction["createdAt"]
        transaction_gross_amount = transaction["grossAmount"]["amount"]
        transaction_shopify_fee = transaction["shopifyFee"]["amount"]
        transaction_net_amount = transaction["netAmount"]["amount"]
        transaction_type = "APP_ONE_TIME_SALE"
        
        app_name = transaction["app"]["name"]
        app_id = transaction["app"]["id"]

        shop_shopify_domain = transaction["shop"]["myshopifyDomain"]
        shop_provider_id = transaction["shop"]["id"]
        shop_name = transaction["shop"]["name"]
        
        begin
          app = ShopifyApp.find_or_create_by(user_id: id, provider_id: app_id) do |app|
            app.name = app_name
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end
        
        begin
          shop = Shop.find_or_create_by(user_id: id, provider_id: shop_provider_id) do |shop|
            shop.shopify_app_id = app.id
            shop.shopify_domain = shop_shopify_domain
            shop.provider_id = shop_provider_id
            shop.name = shop_name
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end

        begin
          Transaction.find_or_create_by(shop_id: shop.id, provider_id: transaction_id) do |transaction|
            transaction.shopify_app_id = app.id
            transaction.provider_created_at = transaction_created_at
            transaction.gross_amount = transaction_gross_amount
            transaction.net_amount = transaction_net_amount
            transaction.shopify_fee = transaction_shopify_fee
            transaction.transaction_type = transaction_type
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end

      has_next_page = result["data"]["transactions"]["pageInfo"]["hasNextPage"]
      cursor = result["data"]["transactions"]["edges"].last["cursor"] if has_next_page
      sleep 0.3
    end
    
    # Set the GraphQL query
    query = <<-GRAPHQL
      query($cursor: String, $since: DateTime) {
        transactions(after: $cursor, first: 80, types: [APP_USAGE_SALE], createdAtMin: $since) {
          edges {
            cursor
            node {
              id
              createdAt
              ... on AppUsageSale {
                chargeId
                grossAmount {
                  amount
                }
                shopifyFee {
                  amount
                }
                netAmount {
                  amount
                }
                app {
                  name
                  id
                }
                shop {
                  myshopifyDomain
                  id
                  name
                }
              }
            }
          }
          pageInfo {
            hasNextPage
          }
        }
      }
    GRAPHQL
  
    cursor = nil
    has_next_page = true

    while has_next_page do
      body = { query: query, variables: { cursor: cursor, since: since } }

      # Make the POST request
      response = HTTParty.post(endpoint, headers: headers, body: body.to_json)

      # Parse the JSON response
      result = JSON.parse(response.body)
      
      return unless result["data"]
      transactions = result["data"]["transactions"]["edges"]

      transactions.each do |transaction_edge|
        transaction = transaction_edge["node"]

        transaction_id = transaction["id"]
        transaction_created_at = transaction["createdAt"]
        transaction_gross_amount = transaction["grossAmount"]["amount"]
        transaction_shopify_fee = transaction["shopifyFee"]["amount"]
        transaction_net_amount = transaction["netAmount"]["amount"]
        transaction_type = "APP_USAGE_SALE"
        
        app_name = transaction["app"]["name"]
        app_id = transaction["app"]["id"]

        shop_shopify_domain = transaction["shop"]["myshopifyDomain"]
        shop_provider_id = transaction["shop"]["id"]
        shop_name = transaction["shop"]["name"]
        
        begin
          app = ShopifyApp.find_or_create_by(user_id: id, provider_id: app_id) do |app|
            app.name = app_name
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end

        begin
          shop = Shop.find_or_create_by(user_id: id, provider_id: shop_provider_id) do |shop|
            shop.shopify_app_id = app.id
            shop.shopify_domain = shop_shopify_domain
            shop.provider_id = shop_provider_id
            shop.name = shop_name
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end

        begin
          Transaction.find_or_create_by(shop_id: shop.id, provider_id: transaction_id) do |transaction|
            transaction.shopify_app_id = app.id
            transaction.provider_created_at = transaction_created_at
            transaction.gross_amount = transaction_gross_amount
            transaction.net_amount = transaction_net_amount
            transaction.shopify_fee = transaction_shopify_fee
            transaction.transaction_type = transaction_type
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end

      has_next_page = result["data"]["transactions"]["pageInfo"]["hasNextPage"]
      cursor = result["data"]["transactions"]["edges"].last["cursor"] if has_next_page
      sleep 0.3
    end

    number_of_apps = shopify_apps.count
    number_of_apps.times do |i|
      app = shopify_apps[i]
      next unless app

      time_to_wait = 10.minutes * i
      RetreiveEventsAndPlansJob.set(wait: time_to_wait.minutes).perform_later(app_id: app.id, since: since)
    end
  end
end
