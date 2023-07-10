# == Schema Information
#
# Table name: shopify_apps
#
#  id          :bigint           not null, primary key
#  name        :string
#  provider_id :string
#  user_id     :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_shopify_apps_on_provider_id              (provider_id) UNIQUE
#  index_shopify_apps_on_user_id                  (user_id)
#  index_shopify_apps_on_user_id_and_provider_id  (user_id,provider_id) UNIQUE
#
class ShopifyApp < ApplicationRecord
  belongs_to :user

  has_many :shops, dependent: :destroy
  has_many :transactions, through: :shops
  has_many :plans, dependent: :destroy
  has_many :events, dependent: :destroy

  delegate :access_token, :organisation_provider_id, to: :user

  def retreive_events_and_plans(since: nil)
    require "httparty"
    require "json"

    # Set the GraphQL query
    query = <<-GRAPHQL
      query($app_id: ID!, $cursor: String, $since: DateTime){
        app(id: $app_id) {
          events(after: $cursor, first: 80, types:[SUBSCRIPTION_CHARGE_ACTIVATED, SUBSCRIPTION_CHARGE_CANCELED, SUBSCRIPTION_CHARGE_FROZEN, SUBSCRIPTION_CHARGE_UNFROZEN], occurredAtMin: $since) {
            edges {
              cursor
              node {
                type
                shop {
                  id
                  name
                  myshopifyDomain
                }
                occurredAt
                ... on SubscriptionChargeCanceled {
                  charge {
                    id
                    name
                    billingOn
                    test
                    amount {
                      amount
                      currencyCode
                    }
                  }
                }
                ... on SubscriptionChargeActivated {
                  charge {
                    id
                    name
                    billingOn
                    test
                    amount {
                      amount
                      currencyCode
                    }
                  }
                }
                ... on SubscriptionChargeFrozen {
                  charge {
                    id
                    name
                    billingOn
                    test
                    amount {
                      amount
                      currencyCode
                    }
                  }
                }
                ... on SubscriptionChargeUnfrozen {
                  charge {
                    id
                    name
                    billingOn
                    test
                    amount {
                      amount
                      currencyCode
                    }
                  }
                }
              }
            }
            pageInfo {
              hasNextPage
            }
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
    since = since.present? ? since : "2012-01-01T00:00:00Z"

    while has_next_page do
      body = { query: query, variables: { cursor: cursor, app_id: provider_id, since: since } }

      # Make the POST request
      response = HTTParty.post(endpoint, headers: headers, body: body.to_json)

      # Parse the JSON response
      result = JSON.parse(response.body)

      break unless result["data"]
      events = result["data"]["app"]["events"]["edges"]

      events.each do |event_edge|
        event = event_edge["node"]

        test = event["charge"]["test"]
        next if test

        shop_provider_id = event["shop"]["id"]
        shop_name = event["shop"]["name"]
        shop_shopify_domain = event["shop"]["myshopifyDomain"]
        event_type = event["type"]
        event_shop_id = event["shop"]["id"]
        event_occurred_at = event["occurredAt"]
        plan_name = event["charge"]["name"]
        event_billing_on = event["charge"]["billingOn"]
        gross_amount = event["charge"]["amount"]["amount"]

        begin
          plan = Plan.find_or_create_by(shopify_app_id: id, amount: gross_amount) do |plan|
            plan.name = plan_name
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end

        begin
          shop = Shop.find_or_create_by(user_id: user_id, provider_id: shop_provider_id) do |shop|
            shop.shopify_app_id = id
            shop.shopify_domain = shop_shopify_domain
            shop.provider_id = shop_provider_id
            shop.name = shop_name
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end

        next unless shop
        shop.update(plan_id: plan.id) if plan

        begin
          Event.find_or_create_by(shopify_app_id: id, shop_id: shop.id, event_type: event_type, occured_at: event_occurred_at) do |event|
            event.gross_amount = gross_amount
            event.billing_on = event_billing_on
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end

        has_next_page = result["data"]["app"]["events"]["pageInfo"]["hasNextPage"]
        cursor = result["data"]["app"]["events"]["edges"].last["cursor"] if has_next_page
        sleep 0.3
      end
    end

    PopulateActivatedOnColumnJob.perform_later(app_id: id, since: since)
  end
end
