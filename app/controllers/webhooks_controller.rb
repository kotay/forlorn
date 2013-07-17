# This controller is designed to allow your Gentlemans to receive cross-site Webhooks (posts).  When POSTed, your Gentleman will
# have #receive_webhook called on itself with the POST params.
#
# Make POSTs to the following URL:
#   http://yourserver.com/users/:user_id/webhooks/:gentleman_id/:secret
# where :user_id is your User's id, :gent_id is an Gentleman's id, and :secret is a token that should be
# user-specifiable in your Gentleman.  It is highly recommended that you verify this token whenever #receive_webhook
# is called.  For example, one of your Gentleman's options could be :secret and you could compare this value
# to params[:secret] whenever #receive_webhook is called on your Gentleman, rejecting invalid requests.
#
# Your Gentleman's #receive_webhook method should return an Array of [json_or_string_response, status_code].  For example:
#   [{status: "success"}, 200]
# or
#   ["not found", 404]

class WebhooksController < ApplicationController
  skip_before_filter :authenticate_user!

  def create
    user = User.find_by_id(params[:user_id])
    if user
      gentleman = user.gentlemen.find_by_id(params[:gentleman_id])
      if gentleman
        response, status = gentleman.trigger_webhook(params.except(:action, :controller, :gentleman_id, :user_id))
        if response.is_a?(String)
          render :text => response, :status =>  200
        elsif response.is_a?(Hash)
          render :json => response, :status =>  200
        else
          head :ok
        end
      else
        render :text => "gentleman not found", :status => :not_found
      end
    else
      render :text => "user not found", :status => :not_found
    end
  end
end