class StripeController < ApplicationController
  # skip authentication for stripe webhook
  skip_before_action :verify_authenticity_token, only: [:webhook]
  # skip authentication for stripe webhook
  skip_before_action :authenticate_user!, only: [:webhook]

  def webhook
    endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
        event = Stripe::Webhook.construct_event(
            payload, sig_header, endpoint_secret
        )
    rescue JSON::ParserError => e
        # Invalid payload
        status 400
        return
    rescue Stripe::SignatureVerificationError => e
        # Invalid signature
        status 400
        return
    end

    # Handle the event
    case event.type
    when 'payment_intent.succeeded'
      pp event.data.object
      
      # get email of customer
      email = event.data.object.charges.data[0].billing_details.email
      stripe_customer_id = event.data.object.customer

      p '-----------------------------------------------'
      pp email
      pp stripe_customer_id
      p '-----------------------------------------------'

      user = User.find_by(email: email).update(stripe_customer_id: stripe_customer_id)
      user.update(plan: 1)
    else
      puts "Unhandled event type: #{event.type}"
    end

    return 200
  end
end