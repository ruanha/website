# This responds to a new payment that has been made
# and creates a record of it in our database. The actual
# creation of the payment within Stripe happens through
# "payment intents".

module Donations
  class Payment
    class Create
      class SubscriptionNotCreatedError < RuntimeError
        def initialize
          super "Subscription not yet created. Wait for webhook then try again."
        end
      end

      include Mandate

      def initialize(user, stripe_data, subscription: nil)
        @user = user
        @stripe_data = stripe_data
        @subscription = subscription
      end

      def call
        charge = stripe_data.charges.first
        Donations::Payment.create!(
          user: user,
          stripe_id: stripe_data.id,
          stripe_receipt_url: charge.receipt_url,
          subscription: subscription,
          amount_in_cents: stripe_data.amount
        ).tap do |payment|
          user.update(total_donated_in_cents: user.donation_payments.sum(:amount_in_cents))
          AwardBadgeJob.perform_later(user, :supporter)
          SendDonationPaymentEmailJob.perform_later(payment)
        end
      rescue ActiveRecord::RecordNotUnique
        Donations::Payment.find_by!(stripe_id: stripe_data.id)
      end

      memoize
      def subscription
        return @subscription if @subscription

        return unless stripe_data.invoice

        invoice = Stripe::Invoice.retrieve(stripe_data.invoice)
        return unless invoice.subscription

        begin
          user.donation_subscriptions.find_by!(stripe_id: invoice.subscription)
        rescue ActiveRecord::RecordNotFound
          raise SubscriptionNotCreatedError
        end
      end

      private
      attr_reader :user, :stripe_data
    end
  end
end
