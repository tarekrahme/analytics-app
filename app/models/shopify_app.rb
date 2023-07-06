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
class ShopifyApp < ApplicationRecord
  belongs_to :user

  has_many :shops, dependent: :destroy
  has_many :transactions, through: :shops
  has_many :plans, dependent: :destroy
  has_many :events, dependent: :destroy

  delegate :access_token, :organisation_provider_id, to: :user

  def retreive_events_and_plans
    require "httparty"
    require "json"

    # Set the GraphQL query
    query = <<-GRAPHQL
      query($app_id: ID!, $cursor: String){
        app(id: $app_id) {
          events(after: $cursor, first: 50, types:[SUBSCRIPTION_CHARGE_ACTIVATED, SUBSCRIPTION_CHARGE_CANCELED], occurredAtMin: "2021-01-01T00:00:00Z") {
            edges {
              cursor
              node {
                type
                shop {
                  id
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

    while has_next_page do
      body = { query: query, variables: { cursor: cursor, app_id: provider_id } }

      # Make the POST request
      response = HTTParty.post(endpoint, headers: headers, body: body.to_json)

      # Parse the JSON response
      result = JSON.parse(response.body)

      return unless result["data"]
      events = result["data"]["app"]["events"]["edges"]

      events.each do |event_edge|
        event = event_edge["node"]

        test = event["charge"]["test"]
        next if test

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

        shop = Shop.find_by(provider_id: event_shop_id)
        next unless shop

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
  end
end
